module OCPHysteresisTests

using BattMo, Jutul, Test

# The test branches: the graphite OCP of chen_2020 raised by OFFSET on delithiation and
# lowered by OFFSET on lithiation, so that U_n = U + h * OFFSET.
const OFFSET = 0.01
const NEGATIVE = :NegativeElectrodeActiveMaterial
# C/20 of the 4.8 Ah cell of chen_2020; positive current discharges.
const C20 = 0.24

function hysteresis_parameters(;
        offset = OFFSET, gamma_lithiation = 1000.0, gamma_delithiation = 1000.0, branches = true,
        decay_rates = true,
    )
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    am = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
    u = am["OpenCircuitPotential"]
    if branches
        am["OpenCircuitPotentialLithiation"] = "($u) - $offset"
        am["OpenCircuitPotentialDelithiation"] = "($u) + $offset"
    end
    if decay_rates
        am["HysteresisDecayRateLithiation"] = gamma_lithiation
        am["HysteresisDecayRateDelithiation"] = gamma_delithiation
    end
    return cell_parameters
end

function hysteresis_simulation(
        cell_parameters; times, currents, dt, hysteresis = true, soc = 0.5, h0 = nothing, sei = false,
        initial_state = nothing,
    )
    model_settings = load_model_settings(; from_default_set = "p2d")
    delete!(model_settings, "RampUp")
    if hysteresis
        model_settings["OCPHysteresis"] = "OneState"
    end
    if sei
        model_settings["SEIModel"] = "Bolay"
    end
    settings = load_simulation_settings(; from_default_set = "p2d")
    # The default particle grid (10 cells) lets the models reuse code BattMo precompiles.
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        settings[electrode * "CoatingGridPoints"] = 3
        settings[electrode * "ParticleGridPoints"] = 10
    end
    settings["SeparatorGridPoints"] = 3
    protocol = Dict{String, Any}(
        "Protocol" => "InputCurrentSeries",
        "Times" => times,
        "Currents" => currents,
        "LowerVoltageLimit" => 2.5,
        "UpperVoltageLimit" => 4.3,
        "InitialStateOfCharge" => soc,
    )
    if !isnothing(h0)
        protocol["InitialHysteresisStateNegativeElectrode"] = h0
    end
    return Simulation(
        LithiumIonBattery(; model_settings), cell_parameters, CyclingProtocol(protocol);
        simulation_settings = settings, time_steps = fill(dt, round(Int, times[end] / dt)),
        output_all_secondary_variables = true, initial_state,
    )
end

# Tight tolerances, so that runs can be compared well below the effects tested.
function solve_tight(sim)
    tolerances = Dict(string(name) => Dict("default" => 1.0e-10) for name in keys(sim.model.multimodel.models))
    for scaling in BattMo.get_scalings(sim.model.multimodel, sim.parameters)
        tolerances[string(scaling.model_label)][string(scaling.equation_label)] = scaling.value * 1.0e-10
    end
    solver_settings = load_solver_settings(; from_default_set = "direct")
    solver_settings["NonLinearSolver"]["Tolerances"] = tolerances
    return solve(
        sim; solver_settings, info_level = -1, include_initial_state = true,
        expand_substates = true, error_on_incomplete = true,
    )
end

# A current held for `duration`, then the reverse current or a rest for `second`.
function two_parts(first, duration; second = nothing)
    isnothing(second) && return (times = [0.0, duration], currents = [first, first])
    current, length = second
    return (times = [0.0, duration, duration + 1.0e-3, duration + length], currents = [first, first, current, current])
end

voltages(output) = output.time_series["Voltage"]

# Shell-volume-weighted mean stoichiometry of the graphite in each electrode cell.
function mean_stoichiometry(sim, state)
    system = sim.model.multimodel[NEGATIVE].system
    vols = system.discretization[:vols]
    cmax = system.params[:maximum_concentration]
    c = state[NEGATIVE][:ParticleConcentration]
    return vec(sum(vols .* c; dims = 1)) ./ (sum(vols) * cmax)
end

surface_stoichiometry(sim, state) = state[NEGATIVE][:SurfaceConcentration] ./ sim.model.multimodel[NEGATIVE].system.params[:maximum_concentration]

hysteresis_states(sim, output) = [sim.initial_state; output.jutul_output.states]

"""Largest deviation of h from the implicit Euler step of the one-state law, over all steps and cells."""
function law_error(sim, output, gamma_lithiation, gamma_delithiation)
    states = hysteresis_states(sim, output)
    worst = 0.0
    for (s0, s1) in zip(states[1:(end - 1)], states[2:end])
        dtheta = mean_stoichiometry(sim, s1) .- mean_stoichiometry(sim, s0)
        theta_s = surface_stoichiometry(sim, s1)
        h0, h1 = s0[NEGATIVE][:HysteresisState], s1[NEGATIVE][:HysteresisState]
        for cell in eachindex(h1)
            expected = if dtheta[cell] < 0
                1 - (1 - h0[cell]) / (1 + gamma_delithiation(theta_s[cell]) * abs(dtheta[cell]) / 2)
            else
                -1 + (1 + h0[cell]) / (1 + gamma_lithiation(theta_s[cell]) * dtheta[cell] / 2)
            end
            worst = max(worst, abs(h1[cell] - expected))
        end
    end
    return worst
end

@testset "OCP hysteresis" begin

    @testset "Off unless switched on" begin
        protocol = two_parts(C20, 3600.0)
        with_branches = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false)
        without = hysteresis_simulation(hysteresis_parameters(; branches = false, decay_rates = false); protocol..., dt = 600.0, hysteresis = false)
        @test !haskey(with_branches.model.multimodel[NEGATIVE].primary_variables, :HysteresisState)
        @test voltages(solve_tight(with_branches)) == voltages(solve_tight(without))

        switched_on = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0)
        @test haskey(switched_on.model.multimodel[NEGATIVE].primary_variables, :HysteresisState)
        @test haskey(switched_on.model.multimodel[NEGATIVE].equations, :hysteresis)
        # The positive has no branches, so it keeps its one OCP.
        @test !haskey(switched_on.model.multimodel[:PositiveElectrodeActiveMaterial].primary_variables, :HysteresisState)
    end

    @testset "Equal branches give the model without hysteresis" begin
        protocol = two_parts(C20, 3600.0; second = (-C20, 3600.0))
        reference = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false))
        equal = solve_tight(hysteresis_simulation(hysteresis_parameters(; offset = 0.0); protocol..., dt = 600.0, h0 = 0.3))
        @test maximum(abs, voltages(equal) .- voltages(reference)) < 1.0e-8
    end

    @testset "Branch limits" begin
        # With a fast decay the graphite is on the delithiation branch during a discharge, U + OFFSET,
        # and on the lithiation branch during a charge, U - OFFSET.
        for (current, branch) in ((C20, 1), (-C20, -1))
            protocol = two_parts(current, 7200.0)
            reference = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false))
            output = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, h0 = 0.0))
            @test isapprox(voltages(output)[end] - voltages(reference)[end], -branch * OFFSET; atol = 1.0e-4)
            @test maximum(abs, output.jutul_output.states[end][NEGATIVE][:HysteresisState] .- branch) < 1.0e-6
        end
    end

    @testset "The state persists at rest" begin
        # At rest h changes only with the stoichiometry of its own cell, by the law; it does not relax
        # with time. A rest from a uniform state leaves it where it was.
        rate = _ -> 1000.0
        sim = hysteresis_simulation(hysteresis_parameters(); two_parts(0.0, 7200.0)..., dt = 600.0, h0 = 0.5)
        output = solve_tight(sim)
        @test maximum(abs, output.jutul_output.states[end][NEGATIVE][:HysteresisState] .- 0.5) < 1.0e-6
        @test law_error(sim, output, rate, rate) < 1.0e-9
        @test maximum(voltages(output)) - minimum(voltages(output)) < 1.0e-9
        # After a charge the cell rests near the lithiation branch of the graphite. Cells that give
        # lithium to their neighbours during the rest move a little towards the other branch.
        protocol = two_parts(-C20, 7200.0; second = (0.0, 7200.0))
        reference = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false))
        sim = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, h0 = 0.0)
        output = solve_tight(sim)
        @test law_error(sim, output, rate, rate) < 1.0e-9
        @test isapprox(voltages(output)[end] - voltages(reference)[end], OFFSET; atol = 0.05 * OFFSET)
    end

    @testset "Decay law" begin
        # A discharge from the lithiation branch, then a charge, with different rates in the two
        # directions: every step and cell follows the implicit Euler step of the one-state law.
        gamma_lithiation, gamma_delithiation = 60.0, 30.0
        parameters = hysteresis_parameters(; gamma_lithiation, gamma_delithiation)
        protocol = two_parts(C20, 3600.0; second = (-C20, 3600.0))
        sim = hysteresis_simulation(parameters; protocol..., dt = 300.0, h0 = -1.0)
        output = solve_tight(sim)
        @test law_error(sim, output, _ -> gamma_lithiation, _ -> gamma_delithiation) < 1.0e-9
        h = output.jutul_output.states[end][NEGATIVE][:HysteresisState]
        @test all(-1 .< h .< 0)

        # The implicit Euler steps converge to the exponential at first order: during the discharge,
        # 1 - h = 2 exp(-gamma * |dtheta| / 2).
        errors = map((600.0, 300.0)) do dt
            sim = hysteresis_simulation(parameters; two_parts(C20, 3600.0)..., dt, h0 = -1.0)
            output = solve_tight(sim)
            dtheta = mean_stoichiometry(sim, output.jutul_output.states[end]) .- mean_stoichiometry(sim, sim.initial_state)
            exact = 1 .- 2 .* exp.(-gamma_delithiation .* abs.(dtheta) ./ 2)
            maximum(abs, output.jutul_output.states[end][NEGATIVE][:HysteresisState] .- exact)
        end
        @test 1.7 < errors[1] / errors[2] < 2.3

        # A decay rate given as a table of the surface stoichiometry.
        table = Dict("x" => [0.0, 1.0], "y" => [10.0, 60.0])
        parameters = hysteresis_parameters(; gamma_lithiation)
        parameters["NegativeElectrode"]["ActiveMaterial"]["HysteresisDecayRateDelithiation"] = table
        sim = hysteresis_simulation(parameters; two_parts(C20, 3600.0)..., dt = 300.0, h0 = -1.0)
        output = solve_tight(sim)
        @test law_error(sim, output, _ -> gamma_lithiation, theta -> 10.0 + 50.0 * theta) < 1.0e-9
    end

    @testset "Bounds" begin
        sim = hysteresis_simulation(hysteresis_parameters(); two_parts(20 * C20, 1800.0)..., dt = 900.0, h0 = -1.0)
        output = solve_tight(sim)
        for state in output.jutul_output.states
            @test all(-1 .<= state[NEGATIVE][:HysteresisState] .<= 1)
        end
    end

    @testset "Driver: the stoichiometry change carries the current" begin
        # The law is driven by the change of the mean stoichiometry; over the electrode it equals the
        # charge passed, which ties it to PyBaMM's form with the interfacial current density.
        sim = hysteresis_simulation(hysteresis_parameters(); two_parts(C20, 3600.0)..., dt = 600.0, h0 = -1.0)
        output = solve_tight(sim)
        initial = BattMo.compute_lithium_inventory(sim, sim.initial_state; baseline_state = sim.initial_state)
        final = BattMo.compute_lithium_inventory(sim, output.jutul_output.states[end]; baseline_state = sim.initial_state)
        @test isapprox((initial.negative - final.negative) * BattMo.FARADAY_CONSTANT, C20 * 3600.0; rtol = 1.0e-6)
    end

    @testset "Initial state" begin
        protocol = two_parts(C20, 600.0)
        reference = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false)
        voltage(sim) = sim.initial_state[:Control][:ElectricPotential][1]
        for h0 in (-1.0, 0.5)
            sim = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, h0)
            @test all(sim.initial_state[NEGATIVE][:HysteresisState] .== h0)
            @test isapprox(voltage(sim), voltage(reference) - h0 * OFFSET; atol = 1.0e-12)
        end
        # Without an initial state, h starts at 0: on the mean of the two branches.
        sim = hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0)
        @test all(sim.initial_state[NEGATIVE][:HysteresisState] .== 0)
        @test isapprox(voltage(sim), voltage(reference); atol = 1.0e-12)
    end

    @testset "Restart from a stored state" begin
        # A run continued from its stored state carries the hysteresis state over, so that a long
        # simulation can be split into parts.
        parameters = hysteresis_parameters(; gamma_lithiation = 30.0, gamma_delithiation = 30.0)
        full = solve_tight(hysteresis_simulation(parameters; two_parts(C20, 3600.0)..., dt = 300.0, h0 = -1.0))
        first = solve_tight(hysteresis_simulation(parameters; two_parts(C20, 1800.0)..., dt = 300.0, h0 = -1.0))
        stored = first.jutul_output.states[end]
        second_sim = hysteresis_simulation(parameters; two_parts(C20, 1800.0)..., dt = 300.0, initial_state = stored)
        second = solve_tight(second_sim)
        @test second_sim.initial_state[NEGATIVE][:HysteresisState] == stored[NEGATIVE][:HysteresisState]
        h(output) = output.jutul_output.states[end][NEGATIVE][:HysteresisState]
        @test maximum(abs, h(second) .- h(full)) < 1.0e-8
        @test isapprox(voltages(second)[end], voltages(full)[end]; atol = 1.0e-8)
    end

    @testset "Output" begin
        # The hysteresis state is an output, and the voltage breakdown evaluates the OCV on the
        # branches: at the end of a discharge, on the delithiation branch, it is OFFSET lower.
        protocol = two_parts(C20, 7200.0)
        reference = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, hysteresis = false))
        output = solve_tight(hysteresis_simulation(hysteresis_parameters(); protocol..., dt = 600.0, h0 = 0.0))
        h = output.states["NegativeElectrode"]["ActiveMaterial"]["HysteresisState"]
        cells = findall(isfinite, h[end, :])
        @test isapprox(h[end, cells], output.jutul_output.states[end][NEGATIVE][:HysteresisState]; atol = 1.0e-12)
        ocv(output) = compute_voltage_breakdown(output)["OpenCircuitVoltageAverage"][end]
        @test isapprox(ocv(output) - ocv(reference), -OFFSET; atol = 1.0e-4)
    end

    @testset "With the SEI model" begin
        sim = hysteresis_simulation(hysteresis_parameters(); two_parts(C20, 3600.0)..., dt = 600.0, h0 = -1.0, sei = true)
        @test sim.model.multimodel[NEGATIVE] isa BattMo.SEImodel
        output = solve_tight(sim)
        state = output.jutul_output.states[end][NEGATIVE]
        @test haskey(state, :HysteresisState)
        @test haskey(state, :SEIThickness)
        @test all(-1 .< state[:HysteresisState] .< 1)
    end

    @testset "Input checks" begin
        protocol = two_parts(C20, 600.0)
        one_branch = hysteresis_parameters()
        delete!(one_branch["NegativeElectrode"]["ActiveMaterial"], "OpenCircuitPotentialLithiation")
        @test_throws ArgumentError hysteresis_simulation(one_branch; protocol..., dt = 600.0)
        no_rates = hysteresis_parameters(; decay_rates = false)
        @test_throws ArgumentError hysteresis_simulation(no_rates; protocol..., dt = 600.0)
        no_branches = hysteresis_parameters(; branches = false, decay_rates = false)
        @test_throws ArgumentError hysteresis_simulation(no_branches; protocol..., dt = 600.0)
    end

end

end

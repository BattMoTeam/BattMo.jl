module SEITests

using BattMo, Jutul, Test
using BattMo: ForwardDiff

function sei_simulation(;
        current = 0.0, duration = 600.0, dt = 20.0,
        coating_cells = 3, particle_cells = 6, concentration = 1.5,
        conductivity = 1.0e-5, sei = true, initial_state = nothing,
        currents = [current, current], interphase_overrides = Dict(), validate = true,
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020"),
    )
    cell_parameters = deepcopy(cell_parameters)
    interphase = cell_parameters["NegativeElectrode"]["Interphase"]
    interphase["InterstitialConcentration"] = concentration
    interphase["IonicConductivity"] = conductivity
    merge!(interphase, interphase_overrides)
    model_settings = load_model_settings(; from_default_set = "p2d")
    delete!(model_settings, "RampUp")
    if sei
        model_settings["SEIModel"] = "Bolay"
    end
    settings = load_simulation_settings(; from_default_set = "p2d")
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        settings[electrode * "CoatingGridPoints"] = coating_cells
        settings[electrode * "ParticleGridPoints"] = particle_cells
    end
    settings["SeparatorGridPoints"] = coating_cells
    protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => collect(range(0.0, duration; length = length(currents))),
            "Currents" => currents,
            "LowerVoltageLimit" => 2.0,
            "UpperVoltageLimit" => 4.3,
            "InitialStateOfCharge" => 0.5,
        )
    )
    return Simulation(
        LithiumIonBattery(; model_settings), cell_parameters, protocol;
        simulation_settings = settings, time_steps = fill(dt, round(Int, duration / dt)),
        output_all_secondary_variables = true, initial_state, validate,
    )
end

function solve_sei(sim)
    # Resolve the small inventory loss rather than just the much larger cycling current.
    tolerances = Dict(string(name) => Dict("default" => 1.0e-10) for name in keys(sim.model.multimodel.models))
    for scaling in BattMo.get_scalings(sim.model.multimodel, sim.parameters)
        tolerances[string(scaling.model_label)][string(scaling.equation_label)] = scaling.value * 1.0e-10
    end
    # Exercise SolverSettings directly, so forwarded Jutul keywords cannot mask bad defaults.
    solver_settings = load_solver_settings(; from_default_set = "direct")
    solver_settings["NonLinearSolver"]["Tolerances"] = tolerances
    return solve(
        sim; solver_settings, info_level = -1, include_initial_state = true,
        output_substates = true, error_on_incomplete = true,
    )
end

function check_sei_conservation(sim, output; baseline_state = sim.initial_state)
    initial = compute_lithium_inventory(sim, baseline_state; baseline_state)
    negative_name = :NegativeElectrodeActiveMaterial
    params = sim.model.multimodel[negative_name].system.params
    electrode_cells = sim.couplings["NegativeElectrodeActiveMaterial"]["Electrolyte"]["cells"]
    electrolyte_cells = sim.couplings["Electrolyte"]["NegativeElectrodeActiveMaterial"]["cells"]
    volumes = sim.parameters[negative_name][:Volume]
    temperature = sim.parameters[negative_name][:Temperature]
    start_inventory = compute_lithium_inventory(sim, sim.initial_state; baseline_state)
    integrated = start_inventory.sei_added
    previous_time = sim.initial_state[:Control][:Controller].time
    previous_thickness = get(sim.initial_state[negative_name], :SEIThickness, Float64[])
    max_balance_error = 0.0
    max_integration_error = 0.0
    for state in output.jutul_output.states
        inventory = compute_lithium_inventory(sim, state; baseline_state)
        tolerance = 1.0e-10 * initial.mobile + 1.0e-5 * inventory.sei_added
        electrode = state[negative_name]
        electrolyte = state[:Electrolyte]
        time = state[:Control][:Controller].time
        dt = time - previous_time
        @test dt > 0
        rate = if sim.model.multimodel[negative_name] isa BattMo.SEImodel
            sum(zip(electrode_cells, electrolyte_cells)) do (a, e)
                flux = BattMo.sei_molar_flux(
                    params, electrode[:SEIThickness][a], temperature[a],
                    electrode[:ElectricPotential][a], electrolyte[:ElectricPotential][e],
                    electrode[:SEIVoltageDrop][a],
                )
                volumes[a] * params[:volumetric_surface_area] * flux
            end
        else
            0.0
        end
        integrated += dt * rate
        balance_error = abs(inventory.total - initial.mobile)
        integration_error = abs(inventory.sei_added - integrated)
        @test balance_error <= tolerance
        @test integration_error <= tolerance
        thickness = get(electrode, :SEIThickness, Float64[])
        @test all(thickness .>= previous_thickness .- 1.0e-18)
        previous_time = time
        previous_thickness = thickness
        max_balance_error = max(max_balance_error, balance_error)
        max_integration_error = max(max_integration_error, integration_error)
    end
    final = compute_lithium_inventory(sim, output.jutul_output.states[end]; baseline_state)
    @info "SEI accounting" loss_mol = final.sei_added max_balance_error max_integration_error
    @test previous_time ≈ sum(sim.time_steps) atol = 1.0e-10 rtol = 0.0
    return final
end

@testset "SEI lithium consumption" begin
    sim = sei_simulation()
    baseline = sim.initial_state
    initial = compute_lithium_inventory(sim, baseline; baseline_state = baseline)
    output = solve_sei(sim)
    final = check_sei_conservation(sim, output)
    @test 1.0e-4 <= final.sei_added / initial.mobile <= 1.0e-2
    @test final.mobile < initial.mobile
    @test maximum(abs, output.time_series["Current"]) <= 1.0e-12
    @test final.sei_loss_ah ≈ BattMo.FARADAY_CONSTANT * final.sei_added / 3600 rtol = 1.0e-14

    @testset "Cycling conservation" begin
        for current in (-2.5, 2.5)
            cycling_sim = sei_simulation(; current, concentration = 0.5)
            cycling_output = solve_sei(cycling_sim)
            cycling_final = check_sei_conservation(cycling_sim, cycling_output)
            @test 1.0e-4 <= cycling_final.sei_added / initial.mobile <= 1.0e-2
            @test cycling_final.mobile < initial.mobile
        end
    end

    @testset "Local sources and automatic differentiation" begin
        negative_name = :NegativeElectrodeActiveMaterial
        model_a = sim.model.multimodel[negative_name]
        model_e = sim.model.multimodel[:Electrolyte]
        params = model_a.system.params
        state = output.jutul_output.states[end]
        electrode = merge((; sim.parameters[negative_name]...), (; state[negative_name]...))
        electrolyte = merge((; sim.parameters[:Electrolyte]...), (; state[:Electrolyte]...))
        a = 2
        e = sim.couplings["Electrolyte"]["NegativeElectrodeActiveMaterial"]["cells"][a]
        ct_e = BattMo.ButlerVolmerActmatToElyteCT([e], [a])
        ct_a = BattMo.ButlerVolmerElyteToActmatCT([a], [e])
        area = electrode.Volume[a] * params[:volumetric_surface_area]
        particle_factor = params[:volumetric_surface_area] *
            (4 * pi * model_a.system.discretization[:rp]^3 / 3) /
            (electrode.VolumeFraction[a] * params[:volume_fractions][1])
        reference_flux = BattMo.sei_molar_flux(
            params, 1.0e-8, 298.15, electrode.OpenCircuitPotential[a], 0.0, 0.0,
        )
        F = BattMo.FARADAY_CONSTANT
        # Normalize both inputs and residuals so finite-difference errors have useful scales.
        function local_sources(x)
            state_a = merge(
                electrode, (
                    SEIThickness = fill(1.0e-8 * x[1], length(electrode.Volume)),
                    Temperature = fill(298.15 * x[2], length(electrode.Volume)),
                    ElectricPotential = fill(0.1 * x[3], length(electrode.Volume)),
                    SEIVoltageDrop = fill(0.05 * x[5], length(electrode.Volume)),
                )
            )
            state_e = merge(
                electrolyte, (
                    ElectricPotential = fill(0.1 * x[4], length(electrolyte.Volume)),
                )
            )
            residuals = zeros(eltype(x), 6)
            for (i, (target, source, model_t, model_s, ct, equation)) in enumerate(
                    (
                        (state_e, state_a, model_e, model_a, ct_e, :mass_conservation),
                        (state_e, state_a, model_e, model_a, ct_e, :charge_conservation),
                        (state_a, state_e, model_a, model_e, ct_a, :charge_conservation),
                        (state_a, state_e, model_a, model_e, ct_a, :solid_diffusion_bc),
                        (state_a, state_e, model_a, model_e, ct_a, :sei_mass_cons),
                        (state_a, state_e, model_a, model_e, ct_a, :sei_voltage_drop),
                    )
                )
                buffer = view(residuals, i:i)
                Jutul.update_cross_term_in_entity!(
                    buffer, 1, target, target, source, source, model_t, model_s, ct,
                    model_t.equations[equation], 20.0,
                )
            end
            scales = reference_flux .* [
                area, area * F, area * F, particle_factor, 1.0,
                F * 1.0e-8 / params[:IonicConductivity],
            ]
            return residuals ./ scales
        end
        x = [1.0, 1.0, electrode.OpenCircuitPotential[a] / 0.1, 0.0, 0.0]
        sources = local_sources(x)
        @test sources ≈ [1.0, 1.0, -1.0, 0.0, -1.0, 0.0] atol = 1.0e-8 rtol = 1.0e-12
        for drop in (0.0, 0.1)
            x[5] = drop / 0.05
            x[3] = (electrode.OpenCircuitPotential[a] + drop) / 0.1
            derivatives = ForwardDiff.jacobian(local_sources, x)
            for h in (1.0e-5, 1.0e-6)
                finite_difference = hcat(
                    map(eachindex(x)) do i
                        plus = copy(x)
                        minus = copy(x)
                        plus[i] += h
                        minus[i] -= h
                        (local_sources(plus) - local_sources(minus)) / (2 * h)
                    end...
                )
                @test derivatives ≈ finite_difference rtol = 1.0e-5 atol = 1.0e-8
            end
        end
        # At the blocked-growth point, all sources vanish when intercalation is also zero,
        # except for the deliberately nonzero film-voltage residual.
        @test maximum(abs, local_sources(x)[1:5]) <= 1.0e-8
        threshold = 2 * BattMo.GAS_CONSTANT * 298.15 / F
        flux_at_drop(u) = BattMo.sei_molar_flux(params, 1.0e-8, 298.15, 0.1, 0.0, u)
        @test flux_at_drop(threshold * (1 + 1.0e-8)) == 0.0
        @test 0 <= flux_at_drop(threshold * (1 - 1.0e-8)) < reference_flux * 1.0e-5
        @test Jutul.minimum_value(BattMo.NormalizedSEIThickness()) > 0
        @test isfinite(@inferred BattMo.sei_molar_flux(params, 1.0e-8, 298.15, 0.1, 0.0, 0.0))
        prefactor_response = ForwardDiff.derivative(1.0) do multiplier
            varied_params = (
                ElectronicDiffusionCoefficient = params[:ElectronicDiffusionCoefficient] * multiplier,
                InterstitialConcentration = params[:InterstitialConcentration],
            )
            BattMo.sei_molar_flux(varied_params, 1.0e-8, 298.15, 0.1, 0.0, 0.0)
        end
        @test prefactor_response ≈ flux_at_drop(0.0) rtol = 1.0e-12 atol = 0.0
    end

    @testset "Inventory weights and BOL reference" begin
        name = :NegativeElectrodeActiveMaterial
        center_state = deepcopy(baseline)
        surface_state = deepcopy(baseline)
        center_state[name][:ParticleConcentration][1, 1] += 100.0
        surface_state[name][:ParticleConcentration][end, 1] += 100.0
        center = compute_lithium_inventory(sim, center_state; baseline_state = baseline)
        surface = compute_lithium_inventory(sim, surface_state; baseline_state = baseline)
        shells = size(baseline[name][:ParticleConcentration], 1)
        shell_volume_ratio = shells^3 - (shells - 1)^3
        @test (surface.negative - initial.negative) / (center.negative - initial.negative) ≈
            shell_volume_ratio rtol = 1.0e-9 atol = 0.0
        @test initial.sei_added == 0.0
        @test initial.sei_loss_ah == 0.0
        @test_throws UndefKeywordError compute_lithium_inventory(sim, baseline)
    end

    @testset "Disabled growth and initial film resistance" begin
        bare_sim = sei_simulation(; sei = false, current = 2.5)
        bare_output = solve_sei(bare_sim)
        bare_final = check_sei_conservation(bare_sim, bare_output)
        @test bare_final.sei_added == 0.0
        for conductivity in (1.0e-5, 1.0e3)
            fixed_sim = sei_simulation(; concentration = 0.0, current = 2.5, conductivity)
            fixed_output = solve_sei(fixed_sim)
            fixed_initial = compute_lithium_inventory(
                fixed_sim, fixed_sim.initial_state; baseline_state = fixed_sim.initial_state,
            )
            @test fixed_initial.mobile ≈ initial.mobile atol = 1.0e-14 rtol = 0.0
            # There is no kinetic flux to integrate when growth is disabled.
            fixed_final = check_sei_conservation(fixed_sim, fixed_output)
            @test abs(fixed_final.mobile - fixed_initial.mobile) <= 1.0e-10 * fixed_initial.mobile
            for state in fixed_output.jutul_output.states
                @test maximum(abs.(state[:NegativeElectrodeActiveMaterial][:SEIThickness] .- 1.0e-8)) <= 1.0e-18
            end
            scales = BattMo.get_scalings(fixed_sim.model.multimodel, fixed_sim.parameters)
            sei_scale = only(filter(s -> s.equation_label == :sei_mass_cons, scales)).value
            @test isfinite(sei_scale) && sei_scale > 0
            configured = fixed_output.jutul_output.solver_configuration[:tolerances]
            @test configured[:NegativeElectrodeActiveMaterial][:sei_mass_cons] ≈ sei_scale * 1.0e-10 rtol = 1.0e-14
            voltage_difference = maximum(
                abs.(
                    fixed_output.time_series["Voltage"] - bare_output.time_series["Voltage"],
                )
            )
            @info "Initial film voltage effect" conductivity voltage_difference
            if conductivity == 1.0e3
                @test voltage_difference <= 1.0e-6
            else
                @test voltage_difference > 1.0e-6
            end
        end
    end

    @testset "SEI restart preserves the BOL inventory" begin
        current = -2.5
        full_sim = sei_simulation(; current)
        full_output = solve_sei(full_sim)
        first_sim = sei_simulation(; current, duration = 300.0)
        first_output = solve_sei(first_sim)
        restart_state = first_output.jutul_output.states[end]
        second_sim = sei_simulation(; current, duration = 300.0, initial_state = restart_state)
        second_output = solve_sei(second_sim)
        baseline_state = full_sim.initial_state
        check_sei_conservation(second_sim, second_output; baseline_state)
        split_states = vcat(first_output.jutul_output.states, second_output.jutul_output.states)
        @test length(split_states) == length(full_output.jutul_output.states)
        for (reference, restarted) in zip(full_output.jutul_output.states, split_states)
            for name in (:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial)
                concentration_scale = full_sim.model.multimodel[name].system.params[:maximum_concentration]
                @test isapprox(
                    reference[name][:ParticleConcentration], restarted[name][:ParticleConcentration];
                    rtol = 1.0e-6, atol = 1.0e-10 * concentration_scale,
                )
            end
            @test isapprox(
                reference[:Electrolyte][:ElectrolyteConcentration],
                restarted[:Electrolyte][:ElectrolyteConcentration]; rtol = 1.0e-6, atol = 1.0e-7,
            )
            @test isapprox(
                reference[:NegativeElectrodeActiveMaterial][:SEIThickness],
                restarted[:NegativeElectrodeActiveMaterial][:SEIThickness]; rtol = 1.0e-6, atol = 1.0e-18,
            )
            ref_inventory = compute_lithium_inventory(full_sim, reference; baseline_state)
            split_inventory = compute_lithium_inventory(full_sim, restarted; baseline_state)
            @test ref_inventory.sei_added ≈ split_inventory.sei_added rtol = 1.0e-6 atol = 1.0e-10 * initial.mobile
            @test reference[:Control][:ElectricPotential] ≈ restarted[:Control][:ElectricPotential] atol = 1.0e-6 rtol = 0.0
        end
    end

    @testset "Suppressed growth during discharge" begin
        blocked_sim = sei_simulation(; current = 2.5, conductivity = 1.0e-7, duration = 120.0)
        blocked_output = solve_sei(blocked_sim)
        blocked_inventory = check_sei_conservation(blocked_sim, blocked_output)
        threshold = 2 * BattMo.GAS_CONSTANT * 298.15 / BattMo.FARADAY_CONSTANT
        for state in blocked_output.jutul_output.states
            @test minimum(state[:NegativeElectrodeActiveMaterial][:SEIVoltageDrop]) > threshold
        end
        @test abs(blocked_inventory.sei_added) <= 1.0e-10 * initial.mobile
    end

    @testset "Zero diffusion and generated schema" begin
        zero_sim = sei_simulation(;
            interphase_overrides = Dict("ElectronicDiffusionCoefficient" => 0.0), duration = 120.0,
        )
        zero_output = solve_sei(zero_sim)
        zero_inventory = check_sei_conservation(zero_sim, zero_output)
        @test abs(zero_inventory.sei_added) <= 1.0e-10 * initial.mobile
        schema = get_schema_cell_parameters(zero_sim.model.settings)
        properties = schema["properties"]["NegativeElectrode"]["properties"]["Interphase"]["properties"]
        @test properties["ElectronicDiffusionCoefficient"]["minimum"] == 0.0
        @test properties["StoichiometricCoefficient"]["exclusiveMinimum"] == 0.0
        @test properties["InitialPotentialDrop"]["exclusiveMinimum"] == 0.0
    end

    @testset "Timestep and spatial refinement" begin
        # A C/20 waveform represents the low-rate RPT regime; C/2 is covered above.
        currents = [0.0, -0.25, -0.25, 0.0, 0.25, 0.25, 0.0]
        time_outputs = []
        time_losses = Float64[]
        for dt in (20.0, 10.0, 5.0)
            refinement_sim = sei_simulation(; currents, dt, concentration = 0.5)
            refinement_output = solve_sei(refinement_sim)
            inventory = check_sei_conservation(refinement_sim, refinement_output)
            push!(time_outputs, refinement_output)
            push!(time_losses, inventory.sei_added)
        end
        time_voltage_error = maximum(
            abs.(
                time_outputs[2].time_series["Voltage"] - time_outputs[3].time_series["Voltage"][1:2:end],
            )
        )
        time_loss_error = abs(time_losses[2] - time_losses[3]) / time_losses[3]
        @info "SEI timestep refinement" time_losses time_loss_error time_voltage_error
        @test time_loss_error < 0.01
        @test time_voltage_error < 1.0e-4
        @test abs(time_losses[3] - time_losses[2]) < abs(time_losses[2] - time_losses[1])

        space_outputs = []
        space_losses = Float64[]
        for factor in (2, 4, 8)
            refinement_sim = sei_simulation(;
                currents, dt = 5.0, concentration = 0.5,
                coating_cells = 3 * factor, particle_cells = 6 * factor,
            )
            refinement_output = solve_sei(refinement_sim)
            inventory = check_sei_conservation(refinement_sim, refinement_output)
            push!(space_outputs, refinement_output)
            push!(space_losses, inventory.sei_added)
        end
        space_voltage_error = maximum(
            abs.(
                space_outputs[2].time_series["Voltage"] - space_outputs[3].time_series["Voltage"],
            )
        )
        space_loss_error = abs(space_losses[2] - space_losses[3]) / space_losses[3]
        @info "SEI spatial refinement" space_losses space_loss_error space_voltage_error
        @test space_loss_error < 0.01
        @test space_voltage_error < 1.0e-4
    end

    @testset "Invalid SEI inputs" begin
        for field in ("InitialThickness", "InitialPotentialDrop", "StoichiometricCoefficient", "MolarVolume", "IonicConductivity")
            @test_throws ArgumentError sei_simulation(; interphase_overrides = Dict(field => 0.0), validate = false)
        end
        for field in ("ElectronicDiffusionCoefficient", "InterstitialConcentration")
            @test_throws ArgumentError sei_simulation(; interphase_overrides = Dict(field => -1.0), validate = false)
        end
        @test_throws ArgumentError sei_simulation(; interphase_overrides = Dict("MolarVolume" => NaN), validate = false)
    end
end

end # module

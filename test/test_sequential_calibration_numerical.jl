using BattMo
using Test

# Run this file separately to check numerical sensitivities and adjoint caching.
# All evaluations use a fixed three-step case; no optimizer is run.

function coarse_sequential_calibration_simulation()
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    get!(cell_parameters["Electrolyte"], "BruggemanCoefficient", cell_parameters["Separator"]["BruggemanCoefficient"])

    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    cycling_protocol["InitialStateOfCharge"] = 0.8
    cycling_protocol["LowerVoltageLimit"] = 2.0
    cycling_protocol["DRate"] = 0.5

    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["NegativeElectrodeCoatingGridPoints"] = 3
    simulation_settings["PositiveElectrodeCoatingGridPoints"] = 3
    simulation_settings["NegativeElectrodeParticleGridPoints"] = 3
    simulation_settings["PositiveElectrodeParticleGridPoints"] = 3
    simulation_settings["SeparatorGridPoints"] = 2

    model = LithiumIonBattery()
    return Simulation(
        model,
        cell_parameters,
        cycling_protocol;
        simulation_settings,
        time_steps = [1.0, 1.0, 1.0],
    )
end

@testset "Sequential numerical sensitivities and cache" begin
    sim = coarse_sequential_calibration_simulation()
    solver_settings = load_solver_settings(; from_default_set = "direct")
    output = solve(sim; solver_settings, info_level = -1)
    time = output.time_series["Time"]
    target_voltage = output.time_series["Voltage"] .+ 1.0e-3
    original_parameters = deepcopy(sim.cell_parameters.all)
    original_time = copy(time)
    original_voltage = copy(target_voltage)
    shortnames = ["ne_j0", "elyte_bg"]
    sensitivities = evaluate_sequential_sensitivities(sim, time, target_voltage, shortnames; solver_settings)
    problem = BattMo.setup_sequential_problem(sim, time, target_voltage, shortnames)

    @testset "Gradients in optimization and normalized coordinates" begin
        @test isapprox(sensitivities.x0, problem.x0; atol = 0.0, rtol = 1.0e-12)
        @test sensitivities.lower == [-13.0, 1.0e-10]
        @test sensitivities.upper == [-6.0, 10.0]
        @test isapprox(sensitivities.objective_value, 1.0e-6; atol = 1.0e-12, rtol = 1.0e-8)
        width = sensitivities.upper .- sensitivities.lower
        normalized_step = 1.0e-5
        for i in eachindex(shortnames)
            # One pair of forward solves supplies the finite differences in both coordinates.
            step = zeros(length(shortnames))
            step[i] = width[i] * normalized_step
            plus, plus_gradient = BattMo.solve_and_differentiate_for_calibration(
                problem.x0 + step, problem.setup_case, problem.calibration, problem.objective, solver_settings;
                gradient = false,
            )
            minus, minus_gradient = BattMo.solve_and_differentiate_for_calibration(
                problem.x0 - step, problem.setup_case, problem.calibration, problem.objective, solver_settings;
                gradient = false,
            )
            @test ismissing(plus_gradient) && ismissing(minus_gradient)
            difference = (plus - minus) / (2 * step[i])
            normalized_difference = (plus - minus) / (2 * normalized_step)
            @test abs(difference) > 1.0e-9
            @test isapprox(sensitivities.gradient[i], difference; atol = 1.0e-10, rtol = 5.0e-3)
            @test isapprox(sensitivities.normalized_gradient[i], normalized_difference; atol = 1.0e-10, rtol = 5.0e-3)
        end
    end

    @testset "Cached adjoints at changed parameters" begin
        cache = Dict()
        cached_x = copy(problem.x0)
        backend_arg = (use_sparsity = false, di_sparse = true, single_step_sparsity = false, do_prep = true)
        initial_value, initial_gradient = BattMo.solve_and_differentiate_for_calibration(
            cached_x, problem.setup_case, problem.calibration, problem.objective, solver_settings;
            adj_cache = cache, backend_arg,
        )
        @test isapprox(initial_value, sensitivities.objective_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(initial_gradient, sensitivities.gradient; atol = 1.0e-12, rtol = 1.0e-8)
        storage = cache[:storage]
        repeated_value, repeated_gradient = BattMo.solve_and_differentiate_for_calibration(
            copy(cached_x), problem.setup_case, problem.calibration, problem.objective, solver_settings;
            adj_cache = cache, backend_arg,
        )
        @test cache[:storage] === storage
        @test isapprox(repeated_value, initial_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(repeated_gradient, initial_gradient; atol = 1.0e-12, rtol = 1.0e-8)

        # Optimizers may mutate the same vector between evaluations.
        cached_x .+= [0.05, 0.1]
        cached_value, cached_gradient = BattMo.solve_and_differentiate_for_calibration(
            cached_x, problem.setup_case, problem.calibration, problem.objective, solver_settings;
            adj_cache = cache, backend_arg,
        )
        @test cache[:storage] !== storage
        fresh = BattMo.setup_sequential_problem(sim, time, target_voltage, shortnames)
        fresh_value, fresh_gradient = BattMo.solve_and_differentiate_for_calibration(
            cached_x, fresh.setup_case, fresh.calibration, fresh.objective, solver_settings;
            backend_arg,
        )
        @test !isapprox(cached_value, initial_value; atol = 1.0e-12, rtol = 1.0e-4)
        @test isapprox(cached_value, fresh_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(cached_gradient, fresh_gradient; atol = 1.0e-12, rtol = 1.0e-8)
    end
    @test sim.cell_parameters.all == original_parameters
    @test time == original_time
    @test target_voltage == original_voltage
end

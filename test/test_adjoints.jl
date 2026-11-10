using BattMo, Test, Jutul
import BattMo: VoltageCalibration, free_calibration_parameter!, freeze_calibration_parameter!, print_calibration_overview

function test_adjoints()
    cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    solver_settings = load_solver_settings(; from_default_set = "direct")

    cycling_protocol["InitialStateOfCharge"] = 0.8
    cycling_protocol["LowerVoltageLimit"] = 2.0

    model_setup = LithiumIonBattery()

    cycling_protocol["DRate"] = 0.5
    time_steps = fill(50.0, 10)
    sim = Simulation(model_setup, cell_parameters, cycling_protocol; time_steps)

    output0 = solve(sim, info_level = -1)
    t0 = output0.time_series["Time"]
    V0 = output0.time_series["Voltage"]

    vc0 = VoltageCalibration(t0, V0, sim)
    obj0 = BattMo.setup_calibration_objective(vc0)
    multimodel = sim.model.multimodel
    jutul_states = output0.jutul_output.states
    dt = report_timesteps(output0.jutul_output.reports)[1:length(jutul_states)]
    forces = sim.forces
    prm = sim.parameters
    state0 = sim.initial_state
    # Check that the objective is zero when the voltage data matches the model output
    @test Jutul.evaluate_objective(obj0, multimodel, jutul_states, dt, forces) ≈ 0.0
    # Perturb the voltage data to make the objective non-zero
    vc = VoltageCalibration(t0, V0 .+ 1.0, sim)

    free_calibration_parameter!(
        vc,
        ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
        lower_bound = 0.0, upper_bound = 1.0
    )
    free_calibration_parameter!(
        vc,
        ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
        lower_bound = 0.0, upper_bound = 1.0
    )
    free_calibration_parameter!(
        vc,
        ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
        lower_bound = 0.0, upper_bound = 1.0
    )
    free_calibration_parameter!(
        vc,
        ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
        lower_bound = 0.0, upper_bound = 1.0
    )
    free_calibration_parameter!(
        vc,
        ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"];
        lower_bound = 10000.0, upper_bound = 1.0e5
    )
    free_calibration_parameter!(
        vc,
        ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"];
        lower_bound = 10000.0, upper_bound = 1.0e5
    )
    free_calibration_parameter!(
        vc,
        ["Electrolyte", "Concentration"];
        lower_bound = 500.0, upper_bound = 2000.0
    )
    free_calibration_parameter!(
        vc,
        ["NegativeElectrode", "ActiveMaterial", "ReactionRateConstant"];
        lower_bound = 1.0e-16, upper_bound = 1.0e-10
    )
    free_calibration_parameter!(
        vc,
        ["PositiveElectrode", "ActiveMaterial", "ReactionRateConstant"];
        lower_bound = 1.0e-16, upper_bound = 1.0e-10
    )
    obj = BattMo.setup_calibration_objective(vc)
    val = Jutul.evaluate_objective(obj, multimodel, jutul_states, dt, forces)
    @test val ≈ 1.0


    x0, x_setup = BattMo.vectorize_cell_parameters_for_calibration(vc, vc.sim)
    x0_copy = deepcopy(x0)
    setup_battmo_case(X, step_info = missing) = BattMo.setup_battmo_case_for_calibration(X, vc.sim, x_setup, step_info)
    numg = similar(x0)
    f, = BattMo.solve_and_differentiate_for_calibration(x0, setup_battmo_case, vc, obj, solver_settings, gradient = false)
    for i in eachindex(numg)
        x = copy(x0)
        ϵ = max(1.0e-8 * abs(x[i]), 1.0e-16)
        x[i] += ϵ
        f1, = BattMo.solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, obj, solver_settings, gradient = false)
        numg[i] = (f1 - f) / ϵ
    end

    f, g = BattMo.solve_and_differentiate_for_calibration(x0, setup_battmo_case, vc, obj, solver_settings)
    mynorm = x -> sum(x -> x^2, x)^(1 / 2)
    @test mynorm(numg - g) / mynorm(numg) ≈ 0.0 atol = 1.0e-4
    for i in eachindex(numg)
        @testset "$(x_setup.names[i])" begin
            @test numg[i] ≈ g[i] rtol = 5.0e-3
        end
    end
    return
end

@testset "Parameter adjoints" begin
    test_adjoints()
end

function split_step_calibration_simulation()
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

    # The second report step is more than ten times the first, so the solver splits it.
    return Simulation(
        LithiumIonBattery(),
        cell_parameters,
        cycling_protocol;
        simulation_settings,
        time_steps = [1.0, 30.0, 30.0],
    )
end

@testset "Sequential calibration adjoints" begin
    sim = split_step_calibration_simulation()
    solver_settings = load_solver_settings(; from_default_set = "direct")
    output = solve(sim; solver_settings, info_level = -1)
    ministeps = [count(m -> m[:success], report[:ministeps]) for report in output.jutul_output.reports]
    @test any(>(1), ministeps)

    time = output.time_series["Time"]
    voltage = output.time_series["Voltage"] .+ 1.0e-3
    original_parameters = deepcopy(sim.cell_parameters.all)
    original_time = copy(time)
    original_voltage = copy(voltage)
    # A log-scaled parameter stored in the model and a linear one that is also a Jutul parameter.
    shortnames = ["ne_D", "elyte_bg"]
    sensitivities = evaluate_sequential_sensitivities(sim, time, voltage, shortnames; solver_settings)
    problem = BattMo.setup_sequential_problem(sim, time, voltage, shortnames)
    # Same differentiation settings as evaluate_sequential_sensitivities.
    backend_arg = (use_sparsity = false, di_sparse = true, single_step_sparsity = false, do_prep = true)
    objective_and_gradient(calibration_problem, x, settings; kwargs...) = BattMo.solve_and_differentiate_for_calibration(
        x, calibration_problem.setup_case, calibration_problem.calibration, calibration_problem.objective, settings;
        kwargs...,
    )

    @testset "Gradients match finite differences" begin
        @test isapprox(sensitivities.x0, problem.x0; atol = 0.0, rtol = 1.0e-12)
        @test sensitivities.lower == problem.lower
        @test sensitivities.upper == problem.upper
        width = problem.upper .- problem.lower
        normalized_step = 1.0e-5
        for i in eachindex(shortnames)
            # One pair of forward solves supplies the finite differences in both coordinates.
            step = zeros(length(shortnames))
            step[i] = width[i] * normalized_step
            plus, plus_gradient = objective_and_gradient(problem, problem.x0 + step, solver_settings; gradient = false)
            minus, minus_gradient = objective_and_gradient(problem, problem.x0 - step, solver_settings; gradient = false)
            @test ismissing(plus_gradient) && ismissing(minus_gradient)
            difference = (plus - minus) / (2 * step[i])
            @test abs(difference) > 1.0e-9
            @test isapprox(sensitivities.gradient[i], difference; atol = 0.0, rtol = 1.0e-6)
            @test isapprox(sensitivities.normalized_gradient[i], (plus - minus) / (2 * normalized_step); atol = 0.0, rtol = 1.0e-6)
        end
    end

    @testset "Ministep states regardless of output settings" begin
        expanded_settings = deepcopy(solver_settings)
        expanded_settings["Output"]["ExpandSubstates"] = true
        _, expanded_gradient = objective_and_gradient(problem, problem.x0, expanded_settings; backend_arg)
        @test isapprox(expanded_gradient, sensitivities.gradient; atol = 1.0e-12, rtol = 1.0e-8)
    end

    @testset "Cached adjoints at changed parameters" begin
        cache = Dict()
        cached_x = copy(problem.x0)
        initial_value, initial_gradient = objective_and_gradient(problem, cached_x, solver_settings; adj_cache = cache, backend_arg)
        @test isapprox(initial_value, sensitivities.objective_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(initial_gradient, sensitivities.gradient; atol = 1.0e-12, rtol = 1.0e-8)
        storage = cache[:storage]
        repeated_value, repeated_gradient = objective_and_gradient(problem, copy(cached_x), solver_settings; adj_cache = cache, backend_arg)
        @test cache[:storage] === storage
        @test isapprox(repeated_value, initial_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(repeated_gradient, initial_gradient; atol = 1.0e-12, rtol = 1.0e-8)

        # Optimizers may mutate the same vector between evaluations.
        cached_x .+= [0.05, 0.1]
        cached_value, cached_gradient = objective_and_gradient(problem, cached_x, solver_settings; adj_cache = cache, backend_arg)
        @test cache[:storage] !== storage
        fresh = BattMo.setup_sequential_problem(sim, time, voltage, shortnames)
        fresh_value, fresh_gradient = objective_and_gradient(fresh, cached_x, solver_settings; backend_arg)
        @test !isapprox(cached_value, initial_value; atol = 1.0e-12, rtol = 1.0e-4)
        @test isapprox(cached_value, fresh_value; atol = 1.0e-12, rtol = 1.0e-8)
        @test isapprox(cached_gradient, fresh_gradient; atol = 1.0e-12, rtol = 1.0e-8)
    end

    @testset "No completed report step" begin
        failing_settings = deepcopy(solver_settings)
        failing_settings["NonLinearSolver"]["MaxNonLinearIterations"] = 0
        failing_settings["NonLinearSolver"]["MaxTimestepCuts"] = 0
        @test_throws "did not complete any report step" objective_and_gradient(problem, problem.x0, failing_settings; gradient = false)
    end

    @testset "Remaining data time weights only the final ministep" begin
        objective = BattMo.setup_calibration_objective(VoltageCalibration([0.0, 100.0], [4.0, 4.0], sim))
        # Three ministeps end at 20, 40 and 60 s, and the last two share the final report step.
        states = [
            Jutul.JUTUL_OUTPUT_TYPE(:Control => Jutul.JUTUL_OUTPUT_TYPE(:Controller => (time = t,), :ElectricPotential => [3.9]))
                for t in (20.0, 40.0, 60.0)
        ]
        value = Jutul.evaluate_objective(objective, sim.model.multimodel, states, fill(20.0, 3), missing; step_index = [1, 2, 2])
        # The final ministep also covers the 40 s left until the data ends.
        @test isapprox(value, (20.0 + 20.0 + 40.0) * 0.1^2 / 100.0; atol = 1.0e-14, rtol = 0.0)
    end

    @test sim.cell_parameters.all == original_parameters
    @test time == original_time
    @test voltage == original_voltage
end

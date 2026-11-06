using BattMo
using Test

@testset "ExpandSubstates solver setting" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    sim = Simulation(
        LithiumIonBattery(), cell_parameters, cycling_protocol;
        simulation_settings, time_steps = [4.0],
    )
    input = (; model_settings = sim.model.settings, cell_parameters, cycling_protocol, simulation_settings)

    for enabled in (false, true)
        solver_settings = load_solver_settings(; from_default_set = "direct")
        solver_settings["Output"]["ExpandSubstates"] = enabled
        @test BattMo.validate_parameter_set(solver_settings)
        config = BattMo.solver_configuration(
            sim.simulator, sim.model, input, sim.parameters; solver_settings,
        )
        # Jutul stores the substates that the expansion needs.
        @test config[:output_substates] === enabled

        # Keyword overrides must update the same canonical JSON setting.
        config = BattMo.solver_configuration(
            sim.simulator, sim.model, input, sim.parameters;
            solver_settings, expand_substates = !enabled,
        )
        @test config[:output_substates] === !enabled
    end

    # The expanded output holds every accepted substate and locates the report timesteps.
    output = solve(sim; info_level = -1, expand_substates = true, max_timestep = 1)
    states = output.jutul_output.states
    @test length(states) > 1
    @test output.jutul_output.report_indices == [length(states)]
    @test all(state -> !haskey(state, :substates), states)
    @test length(output.time_series["Time"]) == length(states)

    for name in ("default", "direct", "iterative")
        @test load_solver_settings(; from_default_set = name)["Output"]["ExpandSubstates"] === false
    end
    invalid_settings = load_solver_settings(; from_default_set = "direct")
    invalid_settings["Output"]["ExpandSubstates"] = "true"
    @test !BattMo.validate_parameter_set(invalid_settings)
end

@testset "default settings use documented keys" begin
    # The schemas accept unknown keys, so a key that the code reads under another name passes validation.
    schema = BattMo.get_schema_solver_settings()
    for name in ("default", "direct", "iterative")
        settings = load_solver_settings(; from_default_set = name)
        for (section, values) in settings.all
            undocumented = [key for key in keys(values) if !haskey(schema["properties"][section]["properties"], key)]
            @test isempty(undocumented)
        end
    end
    for name in ("p2d", "p4d_pouch", "p4d_cylindrical")
        schema = BattMo.get_schema_simulation_settings(load_model_settings(; from_default_set = name))
        settings = load_simulation_settings(; from_default_set = name)
        undocumented = [key for key in keys(settings.all) if key != "Metadata" && !haskey(schema["properties"], key)]
        @test isempty(undocumented)
    end
end

@testset "solver settings reach the Jutul configuration" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    sim = Simulation(
        LithiumIonBattery(), cell_parameters, cycling_protocol;
        simulation_settings, time_steps = [4.0],
    )
    input = (; model_settings = sim.model.settings, cell_parameters, cycling_protocol, simulation_settings)

    solver_settings = load_solver_settings(; from_default_set = "direct")
    solver_settings["NonLinearSolver"]["MinTimestep"] = 1.0e-3
    solver_settings["NonLinearSolver"]["MaxTimestep"] = 0.5
    solver_settings["NonLinearSolver"]["MaxResidual"] = 1.0e10
    @test BattMo.validate_parameter_set(solver_settings)
    config = BattMo.solver_configuration(sim.simulator, sim.model, input, sim.parameters; solver_settings)
    @test config[:min_timestep] == 1.0e-3
    @test config[:max_timestep] == 0.5
    @test config[:max_residual] == 1.0e10

    # Objects given as keywords replace the named relaxation and time-step selectors.
    relaxation = BattMo.SimpleRelaxation()
    timestep_selectors = [BattMo.TimestepSelector()]
    config = BattMo.solver_configuration(
        sim.simulator, sim.model, input, sim.parameters;
        solver_settings, min_timestep = 2.0e-3, relaxation, timestep_selectors,
    )
    @test config[:min_timestep] == 2.0e-3
    @test config[:relaxation] === relaxation
    @test config[:timestep_selectors] == timestep_selectors
end

@testset "default linear solver and time-step selectors" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    sim = Simulation(
        LithiumIonBattery(), cell_parameters, cycling_protocol;
        simulation_settings, time_steps = [4.0],
    )
    input = (; model_settings = sim.model.settings, cell_parameters, cycling_protocol, simulation_settings)
    solver_settings = load_solver_settings(; from_default_set = "direct")
    config = BattMo.solver_configuration(sim.simulator, sim.model, input, sim.parameters; solver_settings)

    # P2D models use KLU; P4D models keep UMFPACK through Jutul's LUSolver.
    @test config[:linear_solver] isa BattMo.Jutul.KLUSolver
    for framework in ("P4D Pouch", "P4D Cylindrical")
        linear_solver = BattMo.battery_linsolve(Dict{String, Any}("Method" => "Direct"); model_framework = framework)
        @test linear_solver isa BattMo.Jutul.LUSolver
    end

    selectors = config[:timestep_selectors]
    @test any(selector -> selector isa BattMo.Jutul.IterationTimestepSelector && selector.target == 5, selectors)
    @test any(selectors) do selector
        return selector isa BattMo.Jutul.VariableChangeTimestepSelector && selector.key == :ElectricPotential &&
            selector.model_key == :Control && selector.target == 0.1 && selector.is_rel
    end

    # KLU factorizes the P2D Jacobian.
    output = solve(sim; info_level = -1)
    @test length(output.jutul_output.states) == 1
    @test all(isfinite, output.time_series["Voltage"])
end

@testset "inputs iterate over their entries" begin
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    entries = Dict{String, Any}()
    for (key, value) in simulation_settings
        entries[key] = value
    end
    @test entries == simulation_settings.all
end

@testset "simulation validation flags and accept_invalid" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")

    # Keep the solve short.
    time_steps = [1.0]

    # Make Chen 2020 invalid according to the schema:
    # ElectrodeGeometricSurfaceArea maximum is 2.0
    area = 100.0

    @testset "validation enabled allows construction but highlights input" begin
        println("Tests with validation enabled and user-provided input:")

        validate = true

        invalid_cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        invalid_cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = area

        sim = Simulation(
            LithiumIonBattery(validate = validate),
            invalid_cell_parameters,
            cycling_protocol;
            simulation_settings,
            time_steps,
            validate = validate,
        )

        @test sim.validate === true
        @test sim.is_valid === false

        # Validation enabled + invalid Simulation + accept_invalid=false should error.
        @test_throws ErrorException solve(sim; info_level = -1)

        # Validation enabled + invalid Simulation + accept_invalid=true should pass.
        output = solve(sim; accept_invalid = true, info_level = -1)
        @test haskey(output.time_series, "Voltage")
    end

    @testset "validation enabled accepts valid input" begin
        println("Tests with validation enabled and valid input:")

        validate = true

        valid_cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

        sim = Simulation(
            LithiumIonBattery(validate = validate),
            valid_cell_parameters,
            cycling_protocol;
            simulation_settings,
            time_steps,
            validate = validate,
        )

        @test sim.validate === true
        @test sim.is_valid === true

        output = solve(sim; info_level = -1)
        @test haskey(output.time_series, "Voltage")
    end

    @testset "validation disabled allows construction with user-provided input" begin
        println("Tests with validation disabled:")

        validate = false

        cell_parameters_no_validation = load_cell_parameters(; from_default_set = "chen_2020")
        cell_parameters_no_validation["Cell"]["ElectrodeGeometricSurfaceArea"] = area

        sim_no_validation = Simulation(
            LithiumIonBattery(validate = validate),
            cell_parameters_no_validation,
            cycling_protocol;
            simulation_settings,
            time_steps,
            validate = validate,
        )

        @test sim_no_validation.validate === false
        @test sim_no_validation.is_valid === true

        # accept_invalid only makes sense when validation was enabled.
        @test_throws ErrorException solve(sim_no_validation; accept_invalid = true, info_level = -1)

        # Solving without accept_invalid should be allowed because validation was disabled.
        output = solve(sim_no_validation; info_level = -1)
        @test haskey(output.time_series, "Voltage")
    end
end

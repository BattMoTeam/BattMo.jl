using BattMo
using Test

@testset "OutputSubstates solver setting" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    sim = Simulation(
        LithiumIonBattery(), cell_parameters, cycling_protocol;
        simulation_settings, time_steps = [1.0],
    )
    input = (; model_settings = sim.model.settings, cell_parameters, cycling_protocol, simulation_settings)

    for enabled in (false, true)
        solver_settings = load_solver_settings(; from_default_set = "direct")
        solver_settings["Output"]["OutputSubstates"] = enabled
        @test BattMo.validate_parameter_set(solver_settings)
        config = BattMo.solver_configuration(
            sim.simulator, sim.model, input, sim.parameters; solver_settings,
        )
        @test config[:output_substates] === enabled

        # Keyword overrides must update the same canonical JSON setting.
        config = BattMo.solver_configuration(
            sim.simulator, sim.model, input, sim.parameters;
            solver_settings, output_substates = !enabled,
        )
        @test config[:output_substates] === !enabled
    end

    for name in ("default", "direct", "iterative")
        @test load_solver_settings(; from_default_set = name)["Output"]["OutputSubstates"] === false
    end
    invalid_settings = load_solver_settings(; from_default_set = "direct")
    invalid_settings["Output"]["OutputSubstates"] = "true"
    @test !BattMo.validate_parameter_set(invalid_settings)
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

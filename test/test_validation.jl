using BattMo
using Test

@testset "simulation validation flags and accept_invalid" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")

    # Keep the solve short.
    time_steps = [1.0]

    # Make Chen 2020 invalid according to the schema:
    # ElectrodeGeometricSurfaceArea maximum is 2.0
    area = 20.0

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

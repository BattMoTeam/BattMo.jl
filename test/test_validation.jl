using BattMo
using Test

@testset "simulation validation flags and accept_invalid" begin
    println("Tests with validation enabled:")
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")

    # Keep the solve short when testing accept_invalid.
    time_steps = [1.0]

    # Make Chen 2020 invalid according to the schema:
    # ElectrodeGeometricSurfaceArea maximum is 2.0
    area = 20.0
    cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = area

    model_setup = LithiumIonBattery()

    sim = Simulation(
        model_setup,
        cell_parameters,
        cycling_protocol;
        simulation_settings,
        time_steps,
        validate = true,
    )

    @test sim.validate === true
    @test sim.is_valid === false

    # Validation enabled + invalid Simulation + accept_invalid=false should error.
    @test_throws ErrorException solve(sim)

    # Validation enabled + invalid Simulation + accept_invalid=true should pass
    output = solve(sim; accept_invalid = true, info_level = -1)
    @test haskey(output.time_series, "Voltage")

    # Same invalid physical input, but validation disabled.
    println("Tests with validation disabled:")
    cell_parameters_no_validation = load_cell_parameters(; from_default_set = "chen_2020")
    cell_parameters_no_validation["Cell"]["ElectrodeGeometricSurfaceArea"] = area

    sim_no_validation = Simulation(
        LithiumIonBattery(),
        cell_parameters_no_validation,
        cycling_protocol;
        simulation_settings,
        time_steps,
        validate = false,
    )

    @test sim_no_validation.validate === false
    @test sim_no_validation.is_valid === true

    # accept_invalid only makes sense when validation was enabled.
    @test_throws ErrorException solve(sim_no_validation; accept_invalid = true)
end

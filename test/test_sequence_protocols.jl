using BattMo
using Test

@testset "Rest protocol" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 50

    model = LithiumIonBattery(; model_settings)
    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "Rest",
            "InitialStateOfCharge" => 0.5,
            "Duration" => 100.0,
        )
    )

    output = solve(Simulation(model, cell_parameters, cycling_protocol; simulation_settings); info_level = -1)

    @test output.time_series["Time"][end] > 0.0
    @test all(abs.(output.time_series["Current"]) .< 1.0e-8)
end

@testset "Sequence protocol with CC and Rest steps" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 10

    model = LithiumIonBattery(; model_settings)
    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "Sequence",
            "InitialStateOfCharge" => 0.99,
            "Steps" => [
                Dict(
                    "Protocol" => "CC",
                    "InitialControl" => "discharging",
                    "DRate" => 0.1,
                    "TotalNumberOfCycles" => 0,
                    "LowerVoltageLimit" => 4.0,
                    "UpperVoltageLimit" => 4.1,
                ),
                Dict(
                    "Protocol" => "Rest",
                    "Duration" => 20.0,
                ),
            ],
        )
    )

    output = solve(Simulation(model, cell_parameters, cycling_protocol; simulation_settings); info_level = -1)
    current = output.time_series["Current"]

    @test any(current .> 0.1)
    @test first(current) < maximum(current)
    @test any(abs.(current) .< 1.0e-8)
end

@testset "Sequence protocol accepts combined CC Rest and CCCV steps" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 50

    model = LithiumIonBattery(; model_settings)
    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "Sequence",
            "InitialStateOfCharge" => 0.5,
            "Steps" => [
                Dict(
                    "Protocol" => "CC",
                    "InitialControl" => "discharging",
                    "DRate" => 0.1,
                    "TotalNumberOfCycles" => 0,
                    "LowerVoltageLimit" => 3.9,
                    "UpperVoltageLimit" => 4.1,
                ),
                Dict(
                    "Protocol" => "Rest",
                    "Duration" => 20.0,
                ),
                Dict(
                    "Protocol" => "CCCV",
                    "InitialControl" => "charging",
                    "CRate" => 1.0,
                    "DRate" => 1.0,
                    "TotalNumberOfCycles" => 1,
                    "LowerVoltageLimit" => 3.0,
                    "UpperVoltageLimit" => 4.0,
                    "CurrentChangeLimit" => 1.0e-4,
                    "VoltageChangeLimit" => 1.0e-4,
                ),
            ],
        )
    )

    sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

    @test !isempty(sim.time_steps)
    @test length(cycling_protocol["Steps"]) == 3
end

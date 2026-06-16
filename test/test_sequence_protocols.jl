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

@testset "Sequence protocol applies ramp-up at each current-controlled step" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 50.0
    simulation_settings["RampUpSteps"] = 3

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
    sequence_policy = sim.model.multimodel[:Control].system.policy
    cc_policy = BattMo.sequence_step_policy(sequence_policy.steps[1])
    rest_policy = BattMo.sequence_step_policy(sequence_policy.steps[2])
    cccv_policy = BattMo.sequence_step_policy(sequence_policy.steps[3])

    @test !ismissing(cc_policy.current_function)
    @test !ismissing(cccv_policy.current_function)
    @test cc_policy.current_function(0.0) == 0.0
    @test cccv_policy.current_function(0.0) == 0.0
    @test cc_policy.current_function(simulation_settings["RampUpTime"]) ≈ cc_policy.ImaxDischarge
    @test cccv_policy.current_function(simulation_settings["RampUpTime"]) ≈ cccv_policy.ImaxCharge

    ramp_timesteps = BattMo.compute_rampup_timesteps(
        1.1 * BattMo.Constants().hour / cycling_protocol["Steps"][1]["DRate"],
        simulation_settings["TimeStepDuration"],
        simulation_settings["RampUpSteps"],
    )
    rest_index = length(ramp_timesteps) + 1
    next_step_index = rest_index + 1

    @test rest_policy.duration == sim.time_steps[rest_index]
    @test sim.time_steps[next_step_index:(next_step_index + simulation_settings["RampUpSteps"] - 1)] == ramp_timesteps[1:simulation_settings["RampUpSteps"]]
end

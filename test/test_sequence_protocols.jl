using BattMo
using Jutul: report_timesteps
using Test

function control_voltage(output)
    return [only(state[:Control][:ElectricPotential]) for state in output.jutul_output.states]
end

function control_current(output)
    return [only(state[:Control][:Current]) for state in output.jutul_output.states]
end

function sequence_step_index(output)
    return [state[:Control][:Controller].step_index for state in output.jutul_output.states]
end

function control_controller(output)
    return [state[:Control][:Controller] for state in output.jutul_output.states]
end

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

@testset "Sequence Rest steps use global controller time and local step start time" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    delete!(model_settings, "RampUp")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 10.0

    model = LithiumIonBattery(; model_settings)
    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "Sequence",
            "InitialStateOfCharge" => 0.5,
            "Steps" => [
                Dict("Protocol" => "Rest", "Duration" => 20.0),
                Dict("Protocol" => "Rest", "Duration" => 30.0),
                Dict("Protocol" => "Rest", "Duration" => 40.0),
            ],
        )
    )

    output = solve(
        Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
        info_level = -1,
        output_substates = true,
    )

    controllers = control_controller(output)
    step_index = sequence_step_index(output)
    report_time = cumsum(report_timesteps(output.jutul_output.reports; ministeps = true))

    @test length(controllers) == length(report_time)
    # When the final sequence step completes, the controller advances once more:
    # step_index == length(Steps) + 1 means "sequence complete".
    @test sort(unique(step_index)) == [1, 2, 3, 4]

    for k in 1:3
        indices = findall(==(k), step_index)
        @test !isempty(indices)
        if !isempty(indices)
            step_start = sum(cycling_protocol["Steps"][i]["Duration"] for i in 1:(k - 1); init = 0.0)
            @test all(controller -> isapprox(controller.step_start_time, step_start; atol = 1.0e-12, rtol = 0.0), controllers[indices])
            @test isapprox(controllers[indices[end]].time, report_time[indices[end]]; atol = 1.0e-12, rtol = 0.0)
            @test controllers[indices[end]].time - controllers[indices[end]].step_start_time <= cycling_protocol["Steps"][k]["Duration"] + 1.0e-12
        end
    end

    terminal = findall(==(4), step_index)
    @test !isempty(terminal)
    if !isempty(terminal)
        sequence_duration = sum(step["Duration"] for step in cycling_protocol["Steps"])
        @test all(controller -> isapprox(controller.time, sequence_duration; atol = 1.0e-12, rtol = 0.0), controllers[terminal])
    end
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

@testset "Sequence protocol advances through CC discharge Rest and CC charge" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    delete!(model_settings, "RampUp")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 20.0

    model = LithiumIonBattery(; model_settings)
    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "Sequence",
            "InitialStateOfCharge" => 1.0,
            "Steps" => [
                Dict(
                    "Protocol" => "CC",
                    "InitialControl" => "discharging",
                    "DRate" => 1.0,
                    "TotalNumberOfCycles" => 0,
                    "LowerVoltageLimit" => 3.0,
                    "UpperVoltageLimit" => 4.2,
                ),
                Dict(
                    "Protocol" => "Rest",
                    "Duration" => 120.0,
                ),
                Dict(
                    "Protocol" => "CC",
                    "InitialControl" => "charging",
                    "CRate" => 1.0,
                    "TotalNumberOfCycles" => 0,
                    "LowerVoltageLimit" => 3.0,
                    "UpperVoltageLimit" => 3.8,
                ),
            ],
        )
    )

    output = solve(
        Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
        info_level = -1,
        output_substates = true,
    )

    voltage = control_voltage(output)
    current = control_current(output)
    step_index = sequence_step_index(output)

    discharge = findall(==(1), step_index)
    rest = findall(==(2), step_index)
    charge = findall(==(3), step_index)

    @test !isempty(discharge)
    @test !isempty(rest)
    @test !isempty(charge)

    if !isempty(discharge)
        @test voltage[last(discharge)] < voltage[first(discharge)]
        @test all(current[discharge] .> 0.0)
    end
    if length(rest) > 2
        rest_tail = rest[cld(length(rest), 2):end]
        @test all(abs.(current[rest_tail]) .< 1.0e-8)
        @test maximum(voltage[rest_tail]) - minimum(voltage[rest_tail]) < 0.05
    end
    if !isempty(charge)
        @test voltage[last(charge)] > voltage[first(charge)]
        println("current during charge: ", current[charge])
        @test all(current[charge[2:end]] .< 0.0)
    end
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
    rest_ramp_timesteps = BattMo.compute_rampup_timesteps(
        cycling_protocol["Steps"][2]["Duration"],
        simulation_settings["TimeStepDuration"],
        simulation_settings["RampUpSteps"],
    )
    rest_index = length(ramp_timesteps) + 1
    next_step_index = rest_index + length(rest_ramp_timesteps)

    @test sim.time_steps[rest_index:(rest_index + simulation_settings["RampUpSteps"] - 1)] == rest_ramp_timesteps[1:simulation_settings["RampUpSteps"]]
    @test sim.time_steps[next_step_index:(next_step_index + simulation_settings["RampUpSteps"] - 1)] == ramp_timesteps[1:simulation_settings["RampUpSteps"]]
end

@testset "Sequence transition ramp is controlled by RampUp model setting" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    RampUp_setting = model_settings["RampUp"]
    delete!(model_settings, "RampUp")
    model_settings["Rampup"] = RampUp_setting
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = 10.0
    simulation_settings["RampUpTime"] = 10.0
    simulation_settings["RampUpSteps"] = 3

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

    model = LithiumIonBattery(; model_settings)
    output = solve(Simulation(model, cell_parameters, cycling_protocol; simulation_settings); info_level = -1)
    raw_states = output.jutul_output.states
    step_index = [state[:Control][:Controller].step_index for state in raw_states]
    transition_index = findfirst(i -> step_index[i - 1] == 1 && step_index[i] == 2, 2:length(step_index))
    current = output.time_series["Current"]

    @test transition_index !== nothing
    ramp_window = current[transition_index:min(end, transition_index + simulation_settings["RampUpSteps"] + 1)]
    @test any(0.0 .< ramp_window .< current[transition_index - 1])
    @test any(abs.(current[transition_index:end]) .< 1.0e-8)

    model_settings_without_ramp = load_model_settings(; from_default_set = "p2d")
    delete!(model_settings_without_ramp, "RampUp")
    model_without_ramp = LithiumIonBattery(; model_settings = model_settings_without_ramp)
    sim_without_ramp = Simulation(model_without_ramp, cell_parameters, cycling_protocol; simulation_settings)

    @test !sim_without_ramp.model.multimodel[:Control].system.policy.use_ramp_up
end

using BattMo
using Test

@testset "Generic control" begin

	@testset "Experiment strings to control steps" begin

		steps = experiment_to_control_steps([
			"Discharge at 0.5 C until 3.0 V or until 2 hours",
			"Rest until 1e-4 V/s",
			"Charge at 500 mA until 4.1 V",
			"Hold at 4.1 V until 50 mA",
			"Repeat 2 times",
			"Discharge at 2 W for 10 minutes",
		])

		@test length(steps) == 2

		cycle = steps[1]
		@test cycle["ControlType"] == "Cycle"
		@test cycle["NumberOfCycles"] == 3
		@test length(cycle["ControlSteps"]) == 4

		discharge, rest, charge, hold = cycle["ControlSteps"]

		@test discharge["ControlType"] == "Current"
		@test discharge["CRate"] == 0.5
		@test discharge["Direction"] == "discharging"
		@test discharge["Termination"] == [
			Dict("Quantity" => "Voltage", "Value" => 3.0, "Comparison" => "below"),
			Dict("Quantity" => "Time", "Value" => 7200.0),
		]

		@test rest["ControlType"] == "Rest"
		@test rest["Termination"]["Quantity"] == "VoltageChange"
		@test rest["Termination"]["Comparison"] == "absolute value below"

		@test charge["Value"] ≈ 0.5
		@test charge["Termination"]["Comparison"] == "above"

		@test hold["ControlType"] == "Voltage"
		@test hold["Value"] == 4.1
		@test hold["Termination"] == Dict("Quantity" => "Current", "Value" => 0.05, "Comparison" => "absolute value below")

		power = steps[2]
		@test power["ControlType"] == "Power"
		@test power["Value"] == 2.0
		@test power["Termination"] == Dict("Quantity" => "Time", "Value" => 600.0)

		# A voltage limit during a rest follows the relaxation, which is opposite to the previous step
		after_discharge = experiment_to_control_steps(["Discharge at 1 A until 3.0 V", "Rest until 3.3 V"])
		@test after_discharge[2]["Termination"]["Comparison"] == "above"
		after_charge = experiment_to_control_steps(["Charge at 1 A until 4.0 V", "Rest until 3.9 V"])
		@test after_charge[2]["Termination"]["Comparison"] == "below"

		@test_throws ErrorException experiment_to_control_steps(["Hold at 0.5 SOC for 1 hour"])
		@test_throws ErrorException experiment_to_control_steps(["Charge at 1 A until"])
		@test_throws ErrorException experiment_to_control_steps(["Repeat 2 times"])

	end

	@testset "Control step schema" begin

		schema = BattMo.Schema(get_schema_control_steps())
		is_valid(steps) = isempty(BattMo.validate(schema, steps).issues)

		@test is_valid(load_cycling_protocol(; from_default_set = "generic")["ControlSteps"])
		@test is_valid(experiment_to_control_steps(load_cycling_protocol(; from_default_set = "experiment")["Experiment"]))

		termination = Dict("Quantity" => "Voltage", "Value" => 3.0, "Comparison" => "below")

		# Current steps need a direction and exactly one of Value and CRate
		@test is_valid([Dict("ControlType" => "Current", "CRate" => 1.0, "Direction" => "discharging", "Termination" => termination)])
		@test !is_valid([Dict("ControlType" => "Current", "Value" => 1.0, "Termination" => termination)])
		@test !is_valid([Dict("ControlType" => "Current", "Value" => 1.0, "CRate" => 1.0, "Direction" => "discharging", "Termination" => termination)])

		# Terminations other than time need a comparison
		@test !is_valid([Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Voltage", "Value" => 3.0))])
		@test is_valid([Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 10.0))])

		# Unknown fields and control types are rejected
		@test !is_valid([Dict("ControlType" => "Rest", "TimeStepSize" => 10, "Termination" => Dict("Quantity" => "Time", "Value" => 10.0))])
		@test !is_valid([Dict("ControlType" => "Hold", "Termination" => termination)])

		# Cycles are validated recursively
		@test is_valid([Dict("ControlType" => "Cycle", "NumberOfCycles" => 2, "ControlSteps" => [
			Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 10.0)),
		])])
		@test !is_valid([Dict("ControlType" => "Cycle", "NumberOfCycles" => 2, "ControlSteps" => [
			Dict("ControlType" => "Rest", "Duration" => 10.0),
		])])

		# The new step types and the termination tolerance
		@test is_valid([Dict("ControlType" => "CurrentFunction", "FunctionName" => "f", "FilePath" => "f.jl")])
		@test !is_valid([Dict("ControlType" => "CurrentFunction")])
		@test is_valid([Dict("ControlType" => "CurrentSeries", "Times" => [0.0, 1.0], "Currents" => [1.0, 1.0], "LowerVoltageLimit" => 3.0)])
		@test !is_valid([Dict("ControlType" => "CurrentSeries", "Times" => [0.0, 1.0])])
		@test is_valid([Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Voltage", "Value" => 3.0, "Comparison" => "above", "Tolerance" => 1e-4))])
		@test !is_valid([Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Voltage", "Value" => 3.0, "Comparison" => "above", "Tolerance" => -1.0))])

	end

	@testset "Protocol conversion" begin

		schema = BattMo.Schema(get_schema_control_steps())
		is_valid(steps) = isempty(BattMo.validate(schema, steps).issues)

		# Single constant current discharge until the lower voltage limit
		steps = cycling_protocol_to_control_steps(load_cycling_protocol(; from_default_set = "cc_discharge"))
		@test is_valid(steps)
		@test length(steps) == 1
		@test steps[1]["ControlType"] == "Current"
		@test steps[1]["Direction"] == "discharging"
		@test steps[1]["CRate"] == 0.5
		@test steps[1]["Termination"]["Value"] == 2.4
		@test steps[1]["Termination"]["Comparison"] == "below"

		# Constant current cycles, starting with the initial control
		steps = cycling_protocol_to_control_steps(load_cycling_protocol(; from_default_set = "cc_cycling"))
		@test is_valid(steps)
		@test steps[1]["ControlType"] == "Cycle"
		@test steps[1]["NumberOfCycles"] == 3
		@test [s["Direction"] for s in steps[1]["ControlSteps"]] == ["charging", "discharging"]

		# CC-CV cycles
		steps = cycling_protocol_to_control_steps(load_cycling_protocol(; from_default_set = "cccv"))
		@test is_valid(steps)
		@test steps[1]["NumberOfCycles"] == 3
		@test [s["ControlType"] for s in steps[1]["ControlSteps"]] == ["Current", "Voltage", "Current", "Rest"]
		@test steps[1]["ControlSteps"][2]["Termination"]["Quantity"] == "CurrentChange"
		@test steps[1]["ControlSteps"][4]["Termination"]["Quantity"] == "VoltageChange"

		# Function and current series protocols have a single step without termination
		steps = cycling_protocol_to_control_steps(load_cycling_protocol(; from_default_set = "user_defined_current_function"))
		@test is_valid(steps)
		@test steps == [Dict("ControlType" => "CurrentFunction", "FunctionName" => "current_function")]

		series = CyclingProtocol(Dict("Protocol" => "InputCurrentSeries", "Times" => [0.0, 10.0], "Currents" => [1.0, 2.0],
			"LowerVoltageLimit" => 2.5, "UpperVoltageLimit" => 4.2, "InitialStateOfCharge" => 0.5))
		steps = cycling_protocol_to_control_steps(series)
		@test is_valid(steps)
		@test steps[1]["ControlType"] == "CurrentSeries"
		@test !haskey(steps[1], "Termination")

		# Only the last step can be given without termination
		rest = Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 10.0))
		@test BattMo.ControlProtocol([rest, Dict("ControlType" => "Rest")], 0.5; capacity = 1.0) isa BattMo.ControlProtocol
		@test_throws ErrorException BattMo.ControlProtocol([Dict("ControlType" => "Rest"), rest], 0.5; capacity = 1.0)

		# The Matlab control input is converted to control steps as well
		matlab_cccv = Dict("controlPolicy" => "CCCV", "ImaxDischarge" => 5.0, "ImaxCharge" => 5.0, "lowerCutoffVoltage" => 3.0,
			"upperCutoffVoltage" => 4.1, "dEdtLimit" => 1e-4, "dIdtLimit" => 1e-4, "initialControl" => "charging", "numberOfCycles" => 2.0)
		protocol = BattMo.setup_matlab_control_protocol(matlab_cccv)
		@test length(protocol.steps) == 8
		@test protocol.steps[1] isa BattMo.CurrentStep && protocol.steps[2] isa BattMo.VoltageStep
		@test protocol.final_cycle_count == 2

		matlab_cc = Dict("controlPolicy" => "CCDischarge", "Imax" => 5.0, "lowerCutoffVoltage" => 3.0, "rampupTime" => 10.0)
		protocol = BattMo.setup_matlab_control_protocol(matlab_cc)
		@test protocol.steps[1] isa BattMo.CurrentStep && protocol.steps[2] isa BattMo.VoltageStep
		@test protocol.steps[2].termination isa BattMo.NoTermination

	end

	@testset "Cycling protocol validation" begin

		model_settings = load_model_settings(; from_default_set = "p2d")
		is_valid(cycling_protocol) = redirect_stdout(() -> BattMo.validate_parameter_set(cycling_protocol, model_settings), devnull)

		generic = load_cycling_protocol(; from_default_set = "generic")
		@test is_valid(generic)

		protocol = deepcopy(generic.all)
		delete!(protocol, "ControlSteps")
		@test !is_valid(CyclingProtocol(protocol))

		protocol = deepcopy(generic.all)
		protocol["ControlSteps"][1]["Directon"] = "charging"
		@test !is_valid(CyclingProtocol(protocol))

		# Experiment strings are validated through their conversion to control steps
		experiment = load_cycling_protocol(; from_default_set = "experiment")
		@test is_valid(experiment)

		for strings in [["Charge at 1 A untl 4.0 V"], ["Charge at one A until 4.0 V"], ["Charge at"], ["Charge at -1 A until 4.0 V"]]
			protocol = deepcopy(experiment.all)
			protocol["Experiment"] = strings
			@test !is_valid(CyclingProtocol(protocol))
		end

	end

	@testset "Cycle unfolding" begin

		rest = Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 10.0))

		unfolded = BattMo.unfold_control_steps([
			rest,
			Dict("ControlType" => "Cycle", "NumberOfCycles" => 2, "ControlSteps" => [rest, rest]),
			Dict("ControlType" => "Cycle", "NumberOfCycles" => 2, "ControlSteps" => [rest]),
			rest,
		])

		@test length(unfolded) == 8
		@test [u.cycle_count for u in unfolded] == [0, 1, 1, 2, 2, 3, 4, 5]
		@test [u.step_index for u in unfolded] == [0, 0, 1, 0, 1, 0, 0, 0]

	end

	@testset "Simulation" begin

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		simulation_settings = load_simulation_settings(; from_default_set = "p2d")
		simulation_settings["TimeStepDuration"] = 50
		model_setup = LithiumIonBattery()

		function run(cycling_protocol)
			sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
			return solve(sim; info_level = -1)
		end

		# The json control steps and the equivalent experiment strings give the same simulation
		output_generic = run(load_cycling_protocol(; from_default_set = "generic"))
		output_experiment = run(load_cycling_protocol(; from_default_set = "experiment"))

		t = output_generic.time_series["Time"]
		E = output_generic.time_series["Voltage"]
		I = output_generic.time_series["Current"]

		@test t == output_experiment.time_series["Time"]
		@test E ≈ output_experiment.time_series["Voltage"]

		# The simulation stops after the final rest instead of running until TotalTime
		@test t[end] < 100000
		@test maximum(E) < 4.0 * (1 + 2e-3)
		@test abs(I[end]) < 1e-8

		# A power controlled step can be the first step
		cycling_protocol = CyclingProtocol(Dict(
			"Protocol" => "Generic",
			"InitialStateOfCharge" => 0.99,
			"InitialTemperature" => 298.15,
			"TotalTime" => 20000,
			"ControlSteps" => [Dict(
				"ControlType" => "Power",
				"Value" => 10.0,
				"Direction" => "discharging",
				"Termination" => Dict("Quantity" => "Voltage", "Value" => 3.5, "Comparison" => "below"),
			)],
		))
		output = run(cycling_protocol)
		P = output.time_series["Current"] .* output.time_series["Voltage"]
		@test all(isapprox.(P[5:(end - 1)], 10.0; rtol = 1e-3))
		@test output.time_series["Time"][end] < 20000

		# A cycle repeats its steps
		cycling_protocol = CyclingProtocol(Dict(
			"Protocol" => "Generic",
			"InitialStateOfCharge" => 0.5,
			"InitialTemperature" => 298.15,
			"TotalTime" => 20000,
			"ControlSteps" => [Dict(
				"ControlType" => "Cycle",
				"NumberOfCycles" => 3,
				"ControlSteps" => [
					Dict("ControlType" => "Current", "CRate" => 1.0, "Direction" => "discharging",
						"Termination" => Dict("Quantity" => "Time", "Value" => 300)),
					Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 300)),
				],
			)],
		))
		output = run(cycling_protocol)
		I = output.time_series["Current"]
		number_of_discharges = count(k -> I[k] > 1.0 && I[k - 1] < 1.0, 2:length(I))
		@test number_of_discharges == 3
		@test output.time_series["Time"][end] < 20000

	end

	@testset "Time stepping on control step breakpoints" begin

		# Breakpoints of the control steps, relative to the start of the step
		series = BattMo.setup_current_series_step([0.0, 7.0, 14.0], [1.0, 2.0, 3.0], -Inf, Inf, BattMo.NoTermination())
		@test BattMo.next_breakpoint(series, 0.0) == 7.0
		@test BattMo.next_breakpoint(series, 7.0) == 14.0
		@test BattMo.next_breakpoint(series, 14.0) == Inf
		rest = BattMo.RestStep(BattMo.AnyTermination([BattMo.TimeTermination(30.0, 1e-3), BattMo.VoltageTermination(3.0, "below", 1e-3)]))
		@test BattMo.next_breakpoint(rest, 10.0) == 30.0
		@test BattMo.next_breakpoint(rest, 30.0) == Inf

		# A rest of 125 s followed by a current series inside a Generic protocol, with 50 s report steps: the time
		# steps land on the end of the rest and on every point of the series
		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		simulation_settings = load_simulation_settings(; from_default_set = "p2d")
		simulation_settings["TimeStepDuration"] = 50
		solver_settings = load_solver_settings(; from_default_set = "direct")
		solver_settings["Output"]["OutputSubstates"] = true

		series_times = collect(0.0:7.0:70.0)
		cycling_protocol = CyclingProtocol(Dict(
			"Protocol" => "Generic",
			"InitialStateOfCharge" => 0.9,
			"InitialTemperature" => 298.15,
			"TotalTime" => 400,
			"ControlSteps" => [
				Dict("ControlType" => "Rest", "Termination" => Dict("Quantity" => "Time", "Value" => 125)),
				Dict("ControlType" => "CurrentSeries", "Times" => series_times, "Currents" => [isodd(i) ? 2.0 : 6.0 for i in eachindex(series_times)],
					"Termination" => Dict("Quantity" => "Time", "Value" => 70)),
				Dict("ControlType" => "Rest"),
			],
		))
		sim = Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim; solver_settings, info_level = -1)

		times = Float64[]
		for state in output.jutul_output.states
			append!(times, [substate[:Control][:Controller].time for substate in get(state, :substates, [])])
			push!(times, state[:Control][:Controller].time)
		end
		@test all(b -> any(t -> abs(t - b) < 1e-6, times), [125.0; 125.0 .+ series_times[2:end]])

		series_state = first(s for s in output.jutul_output.states if s[:Control][:Controller].step_count == 1)
		@test series_state[:Control][:Controller].step_start_time ≈ 125.0 atol = 1e-9

	end

end

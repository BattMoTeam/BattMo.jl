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
			Dict("ControlType" => "Rest"),
		])])

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

end

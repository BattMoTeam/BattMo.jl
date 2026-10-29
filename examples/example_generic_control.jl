# # Generic control steps
#
# The "Generic" cycling protocol describes a cycling experiment as a list of control steps in json. Each step is a
# "Current", "Voltage", "Power" or "Rest" step with a termination, or a "Cycle" that repeats a list of steps.
# The structure is described by the schema returned by `get_schema_control_steps()`.

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["TimeStepDuration"] = 50

model_setup = LithiumIonBattery()

# Three CC-CV cycles followed by a rest. The currents are given as C-rates, and the CV hold terminates when the
# current has dropped below C/20 or after one hour.

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Generic",
		"InitialStateOfCharge" => 0.99,
		"InitialTemperature" => 298.15,
		"TotalTime" => 200000,
		"ControlSteps" => [
			Dict(
				"ControlType" => "Cycle",
				"NumberOfCycles" => 3,
				"ControlSteps" => [
					Dict(
						"ControlType" => "Current",
						"CRate" => 1.0,
						"Direction" => "discharging",
						"Termination" => Dict("Quantity" => "Voltage", "Value" => 3.0, "Comparison" => "below"),
					),
					Dict(
						"ControlType" => "Rest",
						"Termination" => Dict("Quantity" => "Time", "Value" => 1800),
					),
					Dict(
						"ControlType" => "Current",
						"CRate" => 0.5,
						"Direction" => "charging",
						"Termination" => Dict("Quantity" => "Voltage", "Value" => 4.1, "Comparison" => "above"),
					),
					Dict(
						"ControlType" => "Voltage",
						"Value" => 4.1,
						"Termination" => [
							Dict("Quantity" => "CRate", "Value" => 0.05, "Comparison" => "absolute value below"),
							Dict("Quantity" => "Time", "Value" => 3600),
						],
					),
				],
			),
			Dict(
				"ControlType" => "Rest",
				"Termination" => Dict("Quantity" => "Time", "Value" => 3600),
			),
		],
	),
)

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim; info_level = 0)

plot_dashboard(output)

# The same protocol can be written with experiment strings. These are converted to the control step structure
# before the simulation is set up, which can be inspected with `experiment_to_control_steps`.

experiment = [
	"Discharge at 1 C until 3.0 V",
	"Rest for 30 minutes",
	"Charge at 0.5 C until 4.1 V",
	"Hold at 4.1 V until 0.05 C or until 1 hour",
	"Repeat 2 times",
	"Rest for 1 hour",
]

control_steps = experiment_to_control_steps(experiment)

# The control steps of a "Generic" protocol can also be stored in and loaded from a json file, see for example the
# default protocol loaded with `load_cycling_protocol(; from_default_set = "generic")`.

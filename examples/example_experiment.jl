using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.01,
		"Capacity" => 5,
		"Experiment" =>
			[
				# "Rest for 1 hour",
				[
					"Charge at 1/2 C until 4.0 V",
					"Rest for 1 hour",
					"Discharge at 1/4 C until 3.0 V",
					"Rest for 1 hour",
					"Increase cycle count",
					"Repeat 2 times",
				],
				"Rest for 1 hour",
				"Repeat 2 times",

				# "Rest until 1e-4 V/s",
			],
	),
)

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["RampUpTime"] = 100

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

output = solve(sim; info_level = 0)

plot_dashboard(output)

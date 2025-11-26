using BattMo, GLMakie

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.5,
		"Experiment" =>
			[
				"Charge at 1 A until 4.0 V",
				"Hold at 4.0 V until 1e-4 A change",
				"Discharge at 1 A until 3.0 V",
				"Rest until 1e-4 V change",
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

using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.99,
		# "Capacity" => 5,
		"Experiment" =>
			[
				"Rest for 1 hour",
				"Charge at 5 W for 4 hour or until 3.5 V",
				"Charge at 0.5 C until 4.0 V or until 1 hour",
				"Hold at 4.0 V until 1e-4 A/s",
				"Discharge at 1 A until 3.4 V",
				"Discharge at 2 W until 3.0 V",
				"Rest until 1e-4 V/s",
				"Charge at 1/20 C for 30 minutes",
			],
	),
)

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["RampUpTime"] = 100
simulation_settings["TimeStepDuration"] = 20

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

output = solve(sim; info_level = 0)


f = plot_dashboard(output)

DataInspector(f)
f

# f2 = plot_output(output, ["Voltage vs Time", "CycleCount vs Time", "StepIndex vs Time", "StepCount vs Time"], layout = (4, 1))
# DataInspector(f2)
# f2
# cycling_protocol2 = load_cycling_protocol(from_default_set = "cccv")

# sim2 = Simulation(model_setup, cell_parameters, cycling_protocol2; simulation_settings)

# output2 = solve(sim2; info_level = 0)


# f = Figure(size = (1000, 400))

# ax = Axis(f[1, 1],
# 	title = "Length",
# 	xlabel = "Cycle steps / s",
# 	ylabel = "Cycle number / V",
# 	xlabelsize = 25,
# 	ylabelsize = 25,
# 	xticklabelsize = 25,
# 	yticklabelsize = 25,
# )

# # Example data
# xs = output.time_series["StepNumber"]
# ys = output.time_series["CycleNumber"]

# # Create custom tooltips for each point
# tooltips = ["Step: $(x), Cycle: $(y)" for (x, y) in zip(xs, ys)]

# line1 = scatterlines!(ax, xs, ys;
# 	linewidth = 10,
# 	markersize = 10,
# 	marker = :cross,
# 	markercolor = :black,
# 	# tooltip = tooltips,
# )

# DataInspector(f)
# f


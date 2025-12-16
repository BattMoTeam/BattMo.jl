using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.99,
		# "Capacity" => 5,
		"Experiment" =>
			[
				"Discharge at 1 C until 2.5 V",
				"Charge at 1 C until 0.8 SOC",
				"Rest for 20 minutes",

				# SOC 90%
				# "Discharge at 0.05 C until 0.90 SOC",
				# "Rest for 20 minutes",
				# "Hold at 0.90 SOC until 0.001 C or until 1 hour",
				# "Rest for 20 minutes",
				# "Charge at 0.1 C for 0.6 seconds",
				# "Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 80% 
				# "Discharge at 0.05 C until 0.80 SOC",
				# "Rest for 20 minutes",
				# "Hold at 0.80 SOC until 0.001 C",
				# "Rest for 20 minutes",
				# "Charge at 0.1 C for 0.6 seconds",
				# "Discharge at 0.1 C for 0.6 seconds",

				# Repeat for 70%
				"Discharge at 0.05 C until 0.70 SOC",
				"Rest for 20 minutes",
				"Hold at 0.70 SOC until 0.001 C",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 60%
				"Discharge at 0.05 C until 0.60 SOC",
				"Rest for 20 minutes",
				"Hold at 0.60 SOC until 0.001 C",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 50%
				"Discharge at 0.05 C until 0.50 SOC",
				"Rest for 20 minutes",
				"Hold at 0.50 SOC until 0.001 C",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 40%
				"Discharge at 0.05 C until 0.40 SOC",
				"Rest for 20 minutes",
				"Hold at 0.40 SOC until 0.001 C",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 30%
				"Discharge at 0.05 C until 0.30 SOC",
				"Rest for 20 minutes",
				"Hold at 0.30 SOC until 0.001 C",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 20%
				# "Discharge at 0.05 C until 0.20 SOC",
				# "Rest for 20 minutes",
				# "Hold at 0.20 SOC until 0.001 C or",
				# "Rest for 20 minutes",
				# "Charge at 0.1 C for 0.6 seconds",
				# "Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 10%
				# "Discharge at 0.5 C until 0.10 SOC or until 30 minutes",
				# "Rest for 10 minutes",
				# "Discharge at 10 W for 10 seconds or until 3.4 V",
				# "Rest for 60 seconds",
				# "Charge at 10 W for 10 seconds or until 4.1 V",
				# "Rest for 5 minutes",

				# # (Add additional SOC steps as needed)

				# "Charge at 0.2 C until 0.90 SOC or until 2 hours",
				# "Rest until 1e-4 V/s",
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


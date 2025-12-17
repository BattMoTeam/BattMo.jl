using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.8,
		"Experiment" =>
			[
				# State of charge 70%
				"Discharge at 0.05 C until 0.70 SOC",
				"Rest for 20 minutes",
				"Hold at 0.70 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# Repeat for 60%
				"Discharge at 0.05 C until 0.60 SOC",
				"Rest for 20 minutes",
				"Hold at 0.60 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 50%
				"Discharge at 0.05 C until 0.50 SOC",
				"Rest for 20 minutes",
				"Hold at 0.50 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 40%
				"Discharge at 0.05 C until 0.40 SOC",
				"Rest for 20 minutes",
				"Hold at 0.40 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# # Repeat for 30%
				"Discharge at 0.05 C until 0.30 SOC",
				"Rest for 20 minutes",
				"Hold at 0.30 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

				# Repeat for 20%
				"Discharge at 0.05 C until 0.20 SOC",
				"Rest for 20 minutes",
				"Hold at 0.20 SOC until 0.001 C or for 4 hours",
				"Rest for 20 minutes",
				"Charge at 0.1 C for 0.6 seconds",
				"Discharge at 0.1 C for 0.6 seconds",

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


# f = plot_dashboard(output)

# DataInspector(f)
# f


f = Figure(size = (1000, 400))

ax = Axis(f[2, 1],
	title = "Voltage",
	xlabel = "Time / h",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	output.time_series["Time"] / 3600,
	output.time_series["Voltage"];
	linewidth = 4,
	# markersize = 10,
	# marker = :cross,
	# markercolor = :black,
)


ax = Axis(f[1, 1],
	title = "Current",
	xlabel = "Time / h",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	output.time_series["Time"] / 3600,
	output.time_series["Current"];
	linewidth = 4,
	# markersize = 10,
	# marker = :cross,
	# markercolor = :black,
)

f

using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.01,
		"Capacity" => 5,
		"Experiment" =>
			[
				"Charge at 1 C until 4.0 V",
				"Hold at 4.0 V until 1e-4 A/s",
				"Discharge at 1 C until 3.0 V",
				"Rest until 1e-4 V/s",
				"Rest for 1 hour",
				"Increase cycle count",
				"Repeat 2 times",
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

# cycling_protocol2 = load_cycling_protocol(from_default_set = "cccv")

# sim2 = Simulation(model_setup, cell_parameters, cycling_protocol2; simulation_settings)

# output2 = solve(sim2; info_level = 0)


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Length",
	xlabel = "Cycle steps / s",
	ylabel = "Cycle number / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

# Example data
xs = output.time_series["StepNumber"]
ys = output.time_series["CycleNumber"]

# Create custom tooltips for each point
tooltips = ["Step: $(x), Cycle: $(y)" for (x, y) in zip(xs, ys)]

line1 = scatterlines!(ax, xs, ys;
	linewidth = 10,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	# tooltip = tooltips,
)

DataInspector(f)
f


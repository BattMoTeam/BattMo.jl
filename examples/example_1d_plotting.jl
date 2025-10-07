using BattMo, GLMakie

model_settings = load_model_settings(; from_default_set = "P2D")
model_settings["SEIModel"] = "Bolay"
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

model = LithiumIonBattery(; model_settings)

cycling_protocol["TotalNumberOfCycles"] = 10

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim;)

print_output_overview(output)


time_series = output.time_series
states = output.states
metrics = output.metrics

# Plot a simple pre-defined dashboard
plot_dashboard(output)

# Plot a dashboard with line plots
plot_dashboard(output; plot_type = "line")

# Plot a dashboard with contour plots
plot_dashboard(output; plot_type = "contour")

# Some simple examples plotting time series quantities using the `plot_output` function
plot_output(output,
	[
		"Current vs Time",
		"Voltage vs Time",
	];
	layout = (2, 1),
)

# Some simple examples plotting state quantities using the `plot_output` function

plot_output(output,
	[
		["NegativeElectrodeActiveMaterialSurfaceConcentration vs Time at Position index 10", "NegativeElectrodeActiveMaterialSurfaceConcentration vs Time at Position index 1"],
		"NegativeElectrodeActiveMaterialParticleConcentration vs Time at Position index 10 and NegativeElectrodeActiveMaterialRadius index 5",
		"NegativeElectrodeActiveMaterialSurfaceConcentration vs Position and Time",
		"PositiveElectrodeActiveMaterialParticleConcentration vs Time and Position at PositiveElectrodeActiveMaterialRadius index end",
		"NegativeElectrodeActiveMaterialPotential vs Time at Position index 10",
	];
	layout = (4, 2),
)

# Some simple examples plotting metrics using the `plot_output` function
plot_output(output,
	[
		"DischargeCapacity vs CycleIndex",
		"CycleNumber vs Time",
		"RoundTripEfficiency vs CycleIndex",
		"RoundTripEfficiency vs DischargeCapacity",
	];
	layout = (4, 2),
)




# Access state data and plot for a specific time step

output_data = output.states;

t = 100 # time step to plot

d1 = output_data["NegativeElectrodeActiveMaterialSurfaceConcentration"][t, :]
d2 = output_data["PositiveElectrodeActiveMaterialSurfaceConcentration"][t, :]
d3 = output_data["ElectrolyteConcentration"][t, :]

f = Figure()
ax = Axis(f[1, 1], title = "Concentration at t = $(output_data["Time"][t]) s", xlabel = "Position [m]", ylabel = "Concentration")
l1 = lines!(ax, output_data["Position"], d1, color = :red, linewidth = 2, label = "NeAmSurfaceConcentration")
l2 = lines!(ax, output_data["Position"], d2, color = :blue, linewidth = 2, label = "PeAmSurfaceConcentration")
l3 = lines!(ax, output_data["Position"], d3, color = :green, linewidth = 2, label = "ElectrolyteConcentration")
axislegend(ax)
display(GLMakie.Screen(), f)

g = Figure()
ax2 = Axis(g[1, 1], title = "Active Material Concentration at t = $(output_data["Time"][t]) s", xlabel = "Position", ylabel = "Depth")
hm1 = contourf!(ax2, output_data["Position"], output_data["NegativeElectrodeActiveMaterialRadius"], output_data["NegativeElectrodeActiveMaterialParticleConcentration"][t, :, :])
hm2 = contourf!(ax2, output_data["Position"], output_data["PositiveElectrodeActiveMaterialRadius"], output_data["PositiveElectrodeActiveMaterialParticleConcentration"][t, :, :])
Colorbar(g[1, 2], hm1)
display(GLMakie.Screen(), g)



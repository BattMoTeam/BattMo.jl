using Jutul, BattMo, GLMakie, Statistics

# ## Setup input parameters
cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")

model_settings["ThermalModel"] = "Decoupled"

model = LithiumIonBattery(; model_settings)

output = Simulation(model, cell_parameters, cycling_protocol);


grids     = output.simulation.grids
maps      = output.simulation.global_maps
timesteps = output.simulation.time_steps[1:length(states)]

time_series = output.time_series
jutul_states = output.states

t = time_series["Time"]
E = time_series["Voltage"]
I = time_series["Current"]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t ./ 3600,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

display(GLMakie.Screen(), f)

thermal_model = sim.decoupled_thermal.model
thermal_states = [state[:ThermalModel] for state in jutul_states]

plot_interactive(thermal_model, thermal_states)

# Plot maximum temperature in the cell over time

T = [maximum(state, dims = 1) for state in output.states["ThermalModel"]["Temperature"]]

f2 = Figure(size = (1000, 400))

ax = Axis(f2[1, 1],
	title = "Maximum temperature in the cell",
	xlabel = "Time / s",
	ylabel = "Temperature / K",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t ./ 3600, # convert time to hours
	T;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	# label = "Julia",
)

display(GLMakie.Screen(), f2)


##
thook = BattMo.setup_thermal_post_ministep_hook(input, Temperature = 298.0)
# TODO: Why does the thermal model pop up here as well?
s = Simulation(input);
for k in [:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial, :Electrolyte]
	push!(s.simulator.model.models[k].output_variables, :Temperature)
end
##
result_sequential = solve(s, post_ministep_hook = thook);
##
tstates = result_sequential.jutul_output.states
elyte_temp = map(s -> maximum(s[:Electrolyte][:Temperature]), tstates)
pam_temp = map(s -> maximum(s[:PositiveElectrodeActiveMaterial][:Temperature]), tstates)
nam_temp = map(s -> maximum(s[:NegativeElectrodeActiveMaterial][:Temperature]), tstates)

fig, ax, plt = lines(T, label = "Maximum temperature (decoupled)")
lines!(ax, elyte_temp, label = "Electrolyte temperature (coupled)")
lines!(ax, pam_temp, label = "Positive electrode temperature (coupled)")
lines!(ax, nam_temp, label = "Negative electrode temperature (coupled)")
axislegend()
fig

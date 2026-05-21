using Jutul, BattMo, GLMakie, Statistics

############# BattMo.jl format

## Setup input parameters
cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

model_settings["ThermalModel"] = "Decoupled"

cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["AmbientTemperature"] = 298.15
cycling_protocol["LowerVoltageLimit"] = 2.5
cycling_protocol["UpperVoltageLimit"] = 3.6
cycling_protocol["DRate"] = 1

simulation_settings["TimeStepDuration"] = 50

cell_parameters["Cell"]["SurfaceHeatTransferCoefficient"] = 3

##
# Decoupled thermal simulation
####

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

output = solve(sim; accept_invalid = true);


##
time_series = output.time_series;
states = output.states;

t = time_series["Time"];
E = time_series["Voltage"];
I = time_series["Current"];

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / h",
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

plot_interactive_3d(output)

##
# jutul_states = output.jutul_output.states;
# thermal_model = sim.decoupled_thermal.model;
# thermal_states = [state[:ThermalModel] for state in jutul_states];



# Plot maximum temperature in the cell over time

T = vec(maximum(output.states["ThermalModel"]["Temperature"], dims = 2))

f2 = Figure(size = (1000, 400))

ax = Axis(f2[1, 1],
	title = "Maximum temperature in the cell",
	xlabel = "Time / h",
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
# Sequential thermal simulation
####

model_settings = load_model_settings(; from_default_set = "p4d_pouch")
model_settings["ThermalModel"] = "Sequential"

model = LithiumIonBattery(; model_settings);

s = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# for k in [:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial, :Electrolyte]
# 	push!(s.simulator.model.models[k].output_variables, :Temperature)
# end
##
result_sequential = solve(s; accept_invalid = true);


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

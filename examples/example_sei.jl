# # Example with SEI layer 

# ## Preparation of the input
using Jutul, BattMo, GLMakie

# We use the SEI model presented in [bolay2022](@cite). We use the json data given in [bolay.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/bolay.json#L157) which contains the parameters for the SEI layer. 

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020.json")
file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P2D.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCCV.json")
file_path_simulation = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simulation_settings/", "simulation_settings_P2D.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
model_settings = read_model_settings(file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)

nothing # hide

# We retrieve the parameters for the SEI layer, using the fact that their names have a "SEI" prefix.
interphaseparams = inputparams["NegativeElectrode"]["Interphase"]
Dict(interphaseparams)

# ## We start the simulation and retrieve the result

model = LithiumIon(; model_settings);

output = run_battery(model, cell_parameters, cycling_protocol; simulation_settings);

states = output[:states]

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide

# ## Plot of voltage and current

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
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

display(GLMakie.Screen(), f) # hide
f # hide

# ## Plot of SEI length

# We recover the SEI length from the `state` output
seilength = [state[:NeAm][:SEIlength][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Length",
	xlabel = "Time / s",
	ylabel = "Length / m",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	seilength;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

ax = Axis(f[2, 1],
	title = "Length",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

display(GLMakie.Screen(), f) # hide
f # hide



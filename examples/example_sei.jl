# # Example with SEI layer 

# ## Preparation of the input
using Jutul, BattMo, GLMakie

# We use the SEI model presented in [bolay2022](@cite). We use the json data given in [bolay.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/bolay.json#L157) which contains the parameters for the SEI layer. 

name = "bolay"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = load_parameters(fn, SimulationInput)
nothing # hide

# We retrieve the parameters for the SEI layer, using the fact that their names have a "SEI" prefix.
interfaceparams = inputparams["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]
Dict([pair for pair in interfaceparams if occursin("SEI", pair.first)])

# ## We start the simulation and retrieve the result
output = run_battery(inputparams)

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



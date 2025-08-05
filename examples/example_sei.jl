# # Example with SEI layer 

# ## Preparation of the input
using Jutul, BattMo, GLMakie

# We use the SEI model presented in [bolay2022](@cite). We use the json data given in [bolay.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/bolay.json#L157) which contains the parameters for the SEI layer. 

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

nothing # hide

# We have a look at the SEI related parameters.
interphase_parameters = cell_parameters["NegativeElectrode"]["Interphase"]

# ## We start the simulation and retrieve the result

model = LithiumIonBattery();

model_settings = model.settings
model_settings["SEIModel"] = "Bolay"

cycling_protocol["TotalNumberOfCycles"] = 10

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

output = solve(sim)

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide

# ## Plot of voltage and current

plot_dashboard(output; plot_type = "simple")

# ## Plot of SEI thickness

# We recover the SEI thickness from the `state` output
seilength_x1 = [state[:NeAm][:SEIlength][1] for state in states]
seilength_xend = [state[:NeAm][:SEIlength][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Length",
	xlabel = "Time / s",
	ylabel = "Thickness / m",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	seilength_x1;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

scatterlines!(ax,
	t,
	seilength_xend;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

ax = Axis(f[2, 1],
	title = "SEI thicknesss",
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


# ## Plot of voltage drop 

u_x1 = [state[:NeAm][:SEIvoltageDrop][1] for state in states]
u_xend = [state[:NeAm][:SEIvoltageDrop][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "SEI voltage drop",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	u_x1;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :blue,
	label = "xmin")

scatterlines!(ax,
	t,
	u_xend;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "xmax")


# ## Plot of the lithium content

u_x1 = [state[:NeAm][:SEIvoltageDrop][1] for state in states]
u_xend = [state[:NeAm][:SEIvoltageDrop][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "SEI voltage drop",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	u_x1;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :blue,
	label = "xmin")

scatterlines!(ax,
	t,
	u_xend;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "xmax")
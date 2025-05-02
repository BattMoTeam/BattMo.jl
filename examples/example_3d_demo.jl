# # 3D battery example
using Jutul, BattMo, GLMakie

# ## Setup input parameters
file_path_cell = parameter_file_path("cell_parameters", "Xu2015.json")
file_path_model = parameter_file_path("model_settings", "P4D_pouch.json")
file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
file_path_simulation = parameter_file_path("simulation_settings", "P4D_pouch.json")

cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
model_settings = load_model_settings(; from_file_path = file_path_model)
simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)
nothing # hide

# ## Setup and run simulation

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim)
nothing # hide

# ## Plot discharge curve 

states = output[:states]
model  = output[:extra][:model]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
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
	markercolor = :black)

display(f) # hide
f # hide

# ## Plot potential on grid at last time step #
state = states[10]

function plot_potential(am, cc, label)
	f3D = Figure(size = (600, 650))
	ax3d = Axis3(f3D[1, 1];
		title = "Potential in $label electrode (coating and active material)")

	maxPhi = maximum([maximum(state[cc][:Phi]), maximum(state[am][:Phi])])
	minPhi = minimum([minimum(state[cc][:Phi]), minimum(state[am][:Phi])])

	colorrange = [0, maxPhi - minPhi]

	components = [am, cc]
	for component in components
		g = model[component].domain.representation
		phi = state[component][:Phi]
		Jutul.plot_cell_data!(ax3d, g, phi .- minPhi; colormap = :viridis, colorrange = colorrange)
	end

	cbar = GLMakie.Colorbar(f3D[1, 2];
		colormap = :viridis,
		colorrange = colorrange .+ minPhi,
		label = "potential")
	display(GLMakie.Screen(), f3D)
	return f3D
end
nothing # hide

# ## Plot the potential in the positive electrode
plot_potential(:PeAm, :PeCc, "positive")

# ## Plot the potential in the negative electrode
plot_potential(:NeAm, :NeCc, "negative")

# ## Plot surface concentration on grid at last time step
function plot_surface_concentration(component, label)
	f3D = Figure(size = (600, 650))
	ax3d = Axis3(f3D[1, 1];
		title = "Surface concentration in $label electrode")

	cs = state[component][:Cs]
	maxcs = maximum(cs)
	mincs = minimum(cs)

	colorrange = [0, maxcs - mincs]
	g = model[component].domain.representation
	Jutul.plot_cell_data!(ax3d, g, cs .- mincs;
		colormap = :viridis,
		colorrange = colorrange)

	cbar = GLMakie.Colorbar(f3D[1, 2];
		colormap = :viridis,
		colorrange = colorrange .+ mincs,
		label = "concentration")
	display(GLMakie.Screen(), f3D)
	return f3D
end
nothing # hide

# ## Plot the surface concentration in the positive electrode
plot_surface_concentration(:PeAm, "positive")

# ## Plot the surface concentration in the negative electrode
plot_surface_concentration(:NeAm, "negative")

# ## Plot electrolyte concentration and potential on grid at last time step
function plot_elyte(var, label)
	f3D = Figure(size = (600, 650))
	ax3d = Axis3(f3D[1, 1]; title = "$label in electrolyte")

	val = state[:Elyte][var]
	maxval = maximum(val)
	minval = minimum(val)

	colorrange = [0, maxval - minval]

	g = model[:Elyte].domain.representation
	Jutul.plot_cell_data!(ax3d, g, val .- minval;
		colormap = :viridis,
		colorrange = colorrange)

	cbar = GLMakie.Colorbar(f3D[1, 2];
		colormap = :viridis,
		colorrange = colorrange .+ minval,
		label = "$label")
	display(GLMakie.Screen(), f3D)
	f3D
end
nothing # hide

# ## Plot of the concentration in the electrolyte
plot_elyte(:C, "concentration")

# ## Plot of the potential in the electrolyte
plot_elyte(:Phi, "potential")

# # Handling simulation outputs

# In this tutorial we will explore the outputs of a simulation for interesting tasks:
# - Plot voltage and current curves
# - Plot overpotentials
# - Plot cell states in space and time
# - Save outputs
# - Load outputs.

# Lets start with loading some pre-defined cell parameters, cycling protocols, and running a simulation. 

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
nothing # hide

model = LithiumIonBattery()

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim)
nothing # hide


# Now we'll have a look into what the output entail. The ouput is of type NamedTuple and contains multiple dicts. Lets print the
# keys of each dict. 

keys(output)

# So we can see the the output contains state data, cell specifications, reports on the simulation, the input parameters of the simulation, and some extra data.
# The most important dicts, that we'll dive a bit deeper into, are the states and cell specifications. First let's see how the states output is structured.

# ### States
states = output[:states]
typeof(states)

# As we can see, the states output is a Vector that contains dicts.

keys(states)

# In this case it consists of 77 dicts. Each dict represents 
# a time step in the simulation and each time step stores quantities divided into battery component related group. This structure agrees with the overal model structure of BattMo.

initial_state = states[1]
keys(initial_state)

# So each time step contains quantities related to the electrolyte, the negative electrode active material, the cycling control, and the positive electrode active material.
# Lets print the stored quantities for each group.

# Electrolyte keys:
keys(initial_state[:Elyte])
# Negative electrode active material keys:
keys(initial_state[:NeAm])
# Positive electrode active material keys:
keys(initial_state[:PeAm])
# Control keys:
keys(initial_state[:Control])

# ### Cell specifications
# Now lets see what quantities are stored within the cellSpecifications dict in the simulation output.

cell_specifications = output[:cellSpecifications];
keys(cell_specifications)

# Let's say we want to plot the cell current and cell voltage over time. First we'll retrieve these three quantities from the output.

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Voltage][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide

# Now we can use GLMakie to create a plot. Lets first plot the cell voltage.

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
)

f # hide

# And the cell current.

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / V",
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
)


f # hide

# ## Retrieving other quantities

# Concentration 
negative_electrode_surface_concentration = Array([[state[:NeAm][:SurfaceConcentration] for state in states]]);
positive_electrode_surface_concentration = Array([[state[:PeAm][:SurfaceConcentration] for state in states]]);
negative_electrode_particle_concentration = Array([[state[:NeAm][:ParticleConcentration] for state in states]]);
positive_electrode_particle_concentration = Array([[state[:PeAm][:ParticleConcentration] for state in states]]);
electrolyte_concentration = [state[:Elyte][:Concentration] for state in states];


# Potential
negative_electrode_potential = [state[:NeAm][:Voltage] for state in states];
electrolyte_potential = [state[:Elyte][:Voltage] for state in states];
positive_electrode_potential = [state[:PeAm][:Voltage] for state in states];

# Grid wrapper:
# We need Jutul to get the grid wrapper.
using Jutul

extra = output[:extra]
model = extra[:model].multimodel
negative_electrode_grid_wrap = physical_representation(model[:NeAm]);
electrolyte_grid_wrap = physical_representation(model[:Elyte]);
positive_electrode_grid_wrap = physical_representation(model[:PeAm]);

# Mesh cell centroids coordinates
centroids_NeAm = negative_electrode_grid_wrap[:cell_centroids, Cells()];
centroids_Elyte = electrolyte_grid_wrap[:cell_centroids, Cells()];
print(centroids_Elyte)
centroids_PeAm = positive_electrode_grid_wrap[:cell_centroids, Cells()];

# Boundary faces coordinates
boundaries_NeAm = negative_electrode_grid_wrap[:boundary_centroids, BoundaryFaces()];
boundaries_Elyte = electrolyte_grid_wrap[:boundary_centroids, BoundaryFaces()];
boundaries_PeAm = positive_electrode_grid_wrap[:boundary_centroids, BoundaryFaces()];

# UPDATE WITH NEW OUTPUT API

# ### The simulation output

# ### Access overpotentials

# ### Plot cell states

# ### Save and load outputs






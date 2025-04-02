# # How to run a model
#
# Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.

using BattMo, GLMakie

# BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default 
# parameter sets, for example the Li-ion parameter set that has been created from the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide


# We instantiate a Lithium-ion battery model with default model settings
model = LithiumIonBatteryModel()

# Then we setup a Simulation object to validate our parameter sets to the intsnatiated battery model.
sim = Simulation(model, cell_parameters, cycling_protocol);

# check if the Simulation object is valid
sim.is_valid

# Now we can solve the simulation
output = solve(sim)



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

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
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


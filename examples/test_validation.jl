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

# Now we can solve the simulation
output = solve(sim);


# states = output[:states]

# t = [state[:Control][:ControllerCV].time for state in states]
# E = [state[:Control][:Phi][1] for state in states]
# I = [state[:Control][:Current][1] for state in states]
# nothing # hide

# # Now we can use GLMakie to create a plot. Lets first plot the cell voltage.

# f = Figure(size = (1000, 400))

# ax = Axis(f[1, 1],
# 	title = "Voltage",
# 	xlabel = "Time / s",
# 	ylabel = "Voltage / V",
# 	xlabelsize = 25,
# 	ylabelsize = 25,
# 	xticklabelsize = 25,
# 	yticklabelsize = 25,
# )


# scatterlines!(ax,
# 	t,
# 	E;
# 	linewidth = 4,
# 	markersize = 10,
# 	marker = :cross,
# 	markercolor = :black,
# )

# f # hide

# # And the cell current.

# ax = Axis(f[1, 2],
# 	title = "Current",
# 	xlabel = "Time / s",
# 	ylabel = "Current / V",
# 	xlabelsize = 25,
# 	ylabelsize = 25,
# 	xticklabelsize = 25,
# 	yticklabelsize = 25,
# )


# scatterlines!(ax,
# 	t,
# 	I;
# 	linewidth = 4,
# 	markersize = 10,
# 	marker = :cross,
# 	markercolor = :black,
# )


# f # hide
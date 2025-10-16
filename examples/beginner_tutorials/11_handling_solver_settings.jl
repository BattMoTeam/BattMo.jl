# # How to change solver related settings in BattMo
#
# Until now we have seen four different input types that can be used to define a simulation in BattMo:
# - *CellParameters* : defines the physical and chemical properties of the battery cell
# - *CyclingProtocol* : defines the current/voltage profile that the cell is subjected to during the simulation
# - *ModelSettings* :   defines various settings for the battery model, such as which submodels to use
# - *SimulationSettings* : defines the time step and grid resolution for your simulations
#
# In addition to these, there is a fifth input type called SolverSettings.
# These settings allow you to control various aspects of the numerical solver used in BattMo.
# This can be useful for improving convergence, stability, and performance of the simulations.
# But as a beginner, just learning how to use BattMo, for most solver settings you'll stick with the default settings.
# Therefore, we will not go into detail about all the available options here, but just show how to load and modify the solver settings
# for a couple of specific settings that can be very useful and handy for every user.
#
# Let's get into it.

using BattMo, GLMakie

# Just like we can load the default cell parameters, cycling protocol, model settings, and simulation settings,
# we can also load the default solver settings.
solver_settings = load_solver_settings(; from_default_set = "default")
nothing # hide

# Lets setup a simple simulation to demonstrate the solver settings.

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)
nothing # hide

# As the solver settings tell the solver how to solve the simulation object, we need to pass the solver settings to the solve function.
output = solve(sim; solver_settings)
nothing # hide
# The simulation should run just like before, but now we have the option to modify the solver settings.
# One useful setting is that we can set an output path that will save the simulation output to an HDF5 file.
# This can be useful if you are running long simulations and want to save the output for later analysis.
# By default, the output is not saved to a file, but we can change that by setting the OutputPath field in the solver settings.

solver_settings["OutputPath"] = "example_path/"
try # hide
	output = solve(sim; solver_settings)
	nothing # hide
catch e # hide
	@warn "Expected to fail because the path does not exist" exception = e # hide
end # hide
nothing # hide

# Another convenient setting is the option to change the amount of information printed to the console during the simulation. For this we use the setting "InfoLevel".
# This can be useful for monitoring the progress of the simulation, and debugging purposes. Or on the contrary, if you want to run a simulation without any output to the console, you can set the value to -1.
# Let's have a look at the description of the setting to see the available options.
print_info("InfoLevel")

# As you can see, the default value is 0, which gives minimal output (just a progress bar by default, and a final report).

# To have a look at the other available settings, you can print them all like this:
print_info(""; category = "SolverSettings")

# As most of the time we'll only change one or two settings, and we use some of the settings often temporary, BattMo also has the option to
# pass the solver settings directly to the solve function, without having to create a SolverSettings object first.
# This can be useful for quick tests, or if you want to change a setting for a single simulation only. In that case you have to pass them
# as keyword arguments to the solve function. Because of convention, we use snake_case for the keyword arguments, instead of the usual CamelCase used in the SolverSettings object.
# The snake_case name is just the CamelCase name with the first letter lowercased and the low dash in between, if you're unsure, you can find the
# correct name by printing the setting info as shown above.

output = solve(sim; info_level = 2)
nothing # hide

# These keywork arguments will override the settings in the SolverSettings object, if both are provided.
# # How to change time and grid resolution in BattMo
#
# Until now we have seen three different input types that can be used to define a simulation in BattMo:
# - *CellParameters* : defines the physical and chemical properties of the battery cell
# - *CyclingProtocol* : defines the current/voltage profile that the cell is subjected to during the simulation
# - *ModelSettings* :   defines various settings for the battery model, such as which submodels to use
#
# In addition to these, there is a fourth input type called SimulationSettings.
# These settings allow you to control the time step and grid resolution for your simulations.
# This can be useful for balancing accuracy and computational cost.
#
# Let's see how to change these settings.

using BattMo, GLMakie

# Load cell parameters as before
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
nothing # hide

# To demonstrate changing time resolution we will use a drive cycle to setup a current function.

# Create wltp function to calculate Current (WLTP data from https://github.com/JRCSTU/wltp)

using CSV
using DataFrames
using Jutul

data_path = string(dirname(pathof(BattMo)), "/../examples/example_data/")
path = joinpath(data_path, "wltp.csv")

df = CSV.read(path, DataFrame)

t = df[:, 1]
P = df[:, 2]

power_func = get_1d_interpolator(t, P, cap_endpoints = false)


function current_function(time, voltage)

	factor = 4000 # Tot account for the fact that we're simulating a single cell instead of a battery pack

	return power_func(time) / voltage / factor
end

@eval Main current_function = $current_function

# Load a cycling protocol that uses the current function
cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")
nothing # hide

# Plot the drive data to see what we are simulating
fig = Figure(size = (1000, 400))
ax = Axis(fig[1, 1], title = "Drive cycle", xlabel = "Time / s", ylabel = "Power / W")
lines!(ax, t, P)
fig

# Load default simulation settings for the P2D model
simulation_settings = load_simulation_settings(; from_default_set = "P2D")
nothing # hide

# run the simulation
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim;)
nothing # hide

# Plot the results
plot_dashboard(output)

# We can see from the plot that the time resolution is way too low to capture the dynamics of the drive cycle.
# We can change the time resolution by modifying the simulation settings. Let's see which simulation setting is available that has to do with time.

print_setting_info("time"; category = "SimulationSettings")

# We can see that the time step can be controlled by TimeStepDuration.

simulation_settings["TimeStepDuration"] = 1.0 # Set the initial time step duration to 1 second

# Now let's rerun the simulation with the new time step duration and plot the results.
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim;)
plot_dashboard(output)

# We can see that the time resolution is much better now and we can capture the dynamics of the drive cycle.

# We can also plot the concentrations and potentials in the cell to see how they change over time and position. 
# Let's plot them as line plots over position so we can have a look at the grid resolution.

plot_dashboard(output; plot_type = "line")

# Now scrol the bar at the bottom of the window the change the time step to see how the concentrations and potentials change over time.
# For most time steps, we can see that the electrolyte concentration and positive electrode surface concentration over position are not smooth.
# This is because the grid resolution of the negative and positive electrode are too low to capture the concentration gradient.
# We can change the grid resolution by modifying the simulation settings. Let's see which simulation setting is available that changes the negative and positive electrode coating thickness grid resolution.

print_setting_info("PositiveElectrode"; category = "SimulationSettings")

# And the negative electrode grid resolution.

print_setting_info("NegativeElectrode"; category = "SimulationSettings")

# We can see that the grid resolutions can be controlled by GridResolutionPositiveElectrodeCoating and GridResolutionNegativeElectrodeCoating.

# Lets have a look at the current grid resolutions and increase them.
println("Current grid resolution in positive electrode coating and separator: ",
	simulation_settings["GridResolutionPositiveElectrodeCoating"],
	" and ",
	simulation_settings["GridResolutionNegativeElectrodeCoating"])

simulation_settings["GridResolutionPositiveElectrodeCoating"] = 20 # Increase the grid resolution in the positive electrode coating to 20
simulation_settings["GridResolutionNegativeElectrodeCoating"] = 20 # Increase the grid resolution in the separator to 10

#Let's rerun the simulation with the new grid resolution and plot the results.
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim;)
plot_dashboard(output; plot_type = "line")

# We can see that the electrolyte concentration and positive electrode surface concentration over position are now smooth.

# # Exploring the impact of the reaction rate constant

# To change cell parameters, cycling protocols and settings, we can modify the JSON files directly, or we can read 
# them into objects in the script and modify them as Dictionaries. 

# Lets first read the parameters from the JSON files.

# ###  Load Input Files and Initialize Model

# We begin by loading the parameter files:

using BattMo

file_path_cell = string(dirname(pathof(BattMo)), "/../src/input/defaults/cell_parameters/", "Chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../src/input/defaults/cycling_protocols/", "CCDischarge.json")

cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
nothing # hide

# ### Explore and Modify Parameters

# We can inspect different parameter groups in the loaded parameter sets using search_parameter. For example, we'd like to now how electrode related objects and parameters are named:

search_parameter(cell_parameters, "Electrode")

# Another example where we'd like to now which concentration parameters are part of the parameter set:
search_parameter(cell_parameters, "Concentration")


# Lets access what is inside the Separator key.

cell_parameters["Separator"]

# We have a flat list of parameters and values for the separator. In other cases, a key might nest other dictionaries, 
# which can be accessed using the normal dictionary notation. Lets see for instance the  active material parameters of 
# the negative electrode.

cell_parameters["NegativeElectrode"]["ActiveMaterial"]

# ### Editing scalar parameters

# Parameter that take single numerical values (e.g. real, integers, booleans) can be directly modified. Examples:

cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1e-13
nothing # hide

cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] = 8.2e-5
nothing # hide


# ### Editing non-scalar parameters

# Some parameters are described as functions or arrays, since the parameter value depends on other variables. For instance
# the Open Circuit Potentials of the Active Materials depend on the lithium stoichiometry and temperature. 

# > MISSING 

# ### Compare simulations 

# After the updates, we instantiate the model and the simulations, verify the simulations to be valid, 
# and run it as in the first tutorial.

model = LithiumIonBatteryModel()

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim);

states = output[:states]
t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
using GLMakie # hide
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, E)
ax = Axis(fig[1, 2], ylabel = "Current / I", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, I)
fig

# ### Compare with Original Parameters

# Let’s reload the original parameters and simulate again to compare:

cell_parameters_2 = load_cell_parameters(; from_file_path = file_path_cell)
sim2 = Simulation(model, cell_parameters_2, cycling_protocol);
output2 = solve(sim2)
nothing # hide

# Now, plot the original and modified results:

t2 = [state[:Control][:ControllerCV].time for state in output2[:states]]
E2 = [state[:Control][:Phi][1] for state in output2[:states]]
I2 = [state[:Control][:Current][1] for state in output2[:states]]

fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, E)
lines!(ax, t2, E2)
ax = Axis(fig[1, 2], ylabel = "Current / A", xlabel = "Time / s")
lines!(ax, t, I, label = "intial value")
lines!(ax, t2, I2, label = "updated value")
fig[1, 3] = Legend(fig, ax, "Reaction rate", framevisible = false)
fig # hide

# ### Sweep Over Reaction Rate Constants
# We can now explore how the reaction rate constant affects the battery performance. We loop over a range of values, update the parameter, and collect results:
outputs = []
for r in range(5e-11, 1e-13, length = 5)
	cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = r
	sim3 = Simulation(model, cell_parameters, cycling_protocol)
	result = solve(sim3; config_kwargs = (; end_report = false))
	push!(outputs, (r = r, output = result))  # store r together with output
end
nothing # hide

# Now, plot the discharge curves for each reaction rate:

using Printf
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

for data in outputs
	local t = [state[:Control][:ControllerCV].time for state in data.output[:states]]
	local E = [state[:Control][:Phi][1] for state in data.output[:states]]
	lines!(ax, t, E, label = @sprintf("%.1e", data.r))
end

fig[1, 2] = Legend(fig, ax, "Reaction rate", framevisible = false)
fig # hide

# This clearly demonstrates that the reaction rate constant only becomes a limiting factor as it drops to very low values, such as 1e-13.
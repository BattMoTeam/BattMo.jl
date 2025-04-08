# # Change input parameters

# To change cell parameters, cycling protocols and settings, we can modify the JSON files directly, or we can read 
# them into objects in the script and modify them as Dictionaries. 

# Lets first read the parameters from the JSON files.

using BattMo

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide

# You can inspect the contents of the parameter object as you would do with normal dictionaries.

keys(cell_parameters)

# ### Accessing parameters

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

# > UPDATE WITH NEW OUTPUT API

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

# To compare the results, let us reload the original parameter set and run a simulation with it. Note that we use 
# the same model and simulation protocol.

cell_parameters_original = read_cell_parameters(file_path_cell)
sim2 = Simulation(model, cell_parameters_original, cycling_protocol);
output2 = solve(sim)
nothing # hide

# We plot both curves

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

# ### Parameter Sweep
#%%
# We can of course change parameter values programatically. Lets iterate over a range of reaction rates and
# collect the results in the `outputs` list. In the simulation configuration keywords `config_kwargs` we pass to
# `run_battery`, we add the options of not printing out the full simulation report at the end of the simulation.

outputs = []
for r in range(5e-11, 1e-13, length = 5)
	cell_parameters_original["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = r
	sim3 = Simulation(model, cell_parameters, cycling_protocol)
	current_simulation_output = solve(sim3; config_kwargs = (; end_report = false))
	push!(outputs, current_simulation_output)
end
nothing # hide

# We can then plot the results and observe that reaction rate constant is not really a limiting factor before we reache
# the value of 1e-13.

using Printf
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
for output in outputs
	local t = [state[:Control][:ControllerCV].time for state in output[:states]]
	local E = [state[:Control][:Phi][1] for state in output[:states]]
	local r = output[:extra][:inputparams]["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["reactionRateConstant"]
	lines!(ax, t, E, label = "$(@sprintf("%g", r))")
end
fig[1, 2] = Legend(fig, ax, "Reaction rate", framevisible = false)
fig # hide
#%%
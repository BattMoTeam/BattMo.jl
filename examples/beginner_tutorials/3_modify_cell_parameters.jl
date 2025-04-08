# # Exploring the impact of the reaction rate constant

# In BattMo, input parameters for a simulation are typically defined in JSON files. While you can edit these files directly, there's a more flexible approach: 
# modify the parameters programmatically by working with the corresponding Julia dictionary created from the JSON.

# As shown in the first tutorial, the function read_cell_parameters reads and converts the JSON content into a Julia Dict. This allows us to directly access and modify simulation inputs in code.

# ###  Load Input Files and Initialize Model

# We begin by loading the parameter files:

using BattMo

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide

# Now, instantiate the model you'd like to work with:

model = LithiumIonBatteryModel();

# ### Explore and Modify Parameters

# We can inspect different parameter groups in the loaded parameter sets using search_parameter. For example, we'd like to now how electrode related objects and parameters are named:

search_parameter(cell_parameters, "Electrode")

# Another example where we'd like to now which concentration parameters are part of the parameter set:
search_parameter(cell_parameters, "Concentration")


# We can access the parameters by perfoming Dict operations. Let’s take a closer look at the electrolyte parameters:
cell_parameters["Electrolyte"]

# And now, access the active material parameters for the negative electrode:

active_material_params = cell_parameters["NegativeElectrode"]["ActiveMaterial"]

# We can directly change one of these parameters. Let us for example change the reaction rate constant,

active_material_params["ReactionRateConstant"] = 1e-13
nothing # hide

# ###  Run the Simulation
# We now create a Simulation object and solve it:

sim = Simulation(model, cell_parameters, cycling_protocol)

# Then we solve for the simulation
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

cell_parameters_2 = read_cell_parameters(file_path_cell)
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
	active_material_params["ReactionRateConstant"] = r
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
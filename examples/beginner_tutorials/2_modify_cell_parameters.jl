# # Change input parameters

# One way to change the values of our input parameters is the alter the value in the JSON file, which speaks for itself. 
# But, as we saw in the first tutorial, BattMo uses the function `readBattMoJsonInputFile` to convert the JSON data to a Julia dict before running the simulation.
# Therefore, it is also possible to change the input parameters by altering the dict.

# We create the input parameter dict like shown in the first tutorial.

using BattMo

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide

# We instantiate the model that we would like to work with.

model = LithiumIonBatteryModel()


# We have an `inputparams` object that corresponds to the json file 
# [p2d_40_jl_chen2020.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40_jl_chen2020.json) 
# which we can investigate directly.

# We can for example inspect the parameters for the electrolyte

cell_parameters["Electrolyte"]

# or of the active material of the negative electrode. At the active material, we find all the parameters related to the
# active material reactions.

active_material_params = cell_parameters["NegativeElectrode"]["ActiveMaterial"]

# We can directly change one of these parameters. Let us for example change the reaction rate constant,

active_material_params["ReactionRateConstant"] = 1e-13
nothing # hide

# We setup the simulation object and check if it's valid

sim = Simulation(model, cell_parameters, cycling_protocol)
# sim.is_valid

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

# To compare the results, let us reload the previous input file and run it

cell_parameters_2 = read_cell_parameters(file_path_cell)
sim2 = Simulation(model, cell_parameters_2, cycling_protocol);
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

# Then, it becomes clear that the values can be changed programatically. We iterate over a range of reaction rate and
# collect the results in the `outputs` list. In the simulation configuration keywords `config_kwargs` we pass to
# `run_battery`, we add the options of not printing out the full simulation report at the end of the simulation.

outputs = []
for r in range(5e-11, 1e-13, length = 5)
	active_material_params["reactionRateConstant"] = r
	sim3 = Simulation(model, cell_parameters, cycling_protocol)
	push!(outputs, solve(sim3; config_kwargs = (; end_report = false)))
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

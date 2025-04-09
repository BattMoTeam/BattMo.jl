# # Running parameter sweep

# In this tutorial we will compare the effect that parameter values have on cell performance.

# Lets start with loading some pre-defined cell parameters and cycling protocols. 

using BattMo, GLMakie

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide

model = LithiumIonBatteryModel()

# ### Sweeping through reaction rates
# First lets see the effect that the reaction rate of the negative electrode has on cell performance. To do this, we simply loop through
# a list of parameter values, carry a simulation for each value, store the outputs, and compare the voltage curves for every output.
# We use the logarithm of the reaction rates to change their values by orders of magnitude.
log_rate_start = -3.0
log_rate_stop = -13.0

outputs = []
for r in range(log_rate_start, log_rate_stop, length = 10)
	cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 10^r
	sim = Simulation(model, cell_parameters, cycling_protocol)
	result = solve(sim; config_kwargs = (; end_report = false))
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

# Sweeping reaction rates result in interesting behavior of the cells voltage and capacity. High reaction rates have negligible influence 
# on the cell voltage curve. However, values below 1e-10 result in a noticeable difference on the curves and the cell's capacity. 
# This observations might be attributed to the interplay between Li+ diffusion and reaction processes. For high reaction rates, 
# the limiting Li+ transport step might be diffusing Li+ from/to the electrodes. However, below a threshold value, the reaction kinetics 
# becomes the bottleneck step in Li+ transport, thus contributing significantly to the cell's overpotential. 





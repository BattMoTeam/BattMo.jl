# # Running parameter sweep

# In this tutorial we will compare the effect that parameter values have on cell performance.

# Lets start with loading some pre-defined cell parameters and cycling protocols. 

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
nothing # hide

model = LithiumIonBattery()

# ### Sweeping through reaction rates
# First lets see the effect that the reaction rate of the negative electrode has on cell performance. To do this, we simply loop through
# a list of parameter values, carry a simulation for each value, store the outputs, and compare the voltage curves for every output.
# We use the logarithm of the reaction rates to change their values by orders of magnitude.
log_rate_start = -3.0
log_rate_stop = -13.0

outputs_rate = []
for r in range(log_rate_start, log_rate_stop, length = 10)
	cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 10^r
	sim = Simulation(model, cell_parameters, cycling_protocol)
	result = solve(sim; end_report = false)
	push!(outputs_rate, (r = r, output = result))  # store r together with output
end
nothing # hide

# Now, plot the discharge curves for each reaction rate:

using Printf
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

for data in outputs_rate
	local t = [state[:Control][:Controller].time for state in data.output[:states]]
	local E = [state[:Control][:ElectricPotential][1] for state in data.output[:states]]
	lines!(ax, t, E, label = @sprintf("%.1e", 10^data.r))
end

fig[1, 2] = Legend(fig, ax, "Reaction rate", framevisible = false)
fig # hide

# Sweeping reaction rates result in interesting behavior of the cells voltage and capacity. High reaction rates have negligible influence 
# on the cell voltage curve. However, values below 1e-10 result in a noticeable difference on the curves and the cell's capacity. 
# This observations might be attributed to the interplay between Li+ diffusion and reaction processes. For high reaction rates, 
# the limiting Li+ transport step might be diffusing Li+ from/to the electrodes. However, below a threshold value, the reaction kinetics 
# becomes the bottleneck step in Li+ transport, thus contributing significantly to the cell's overpotential. 


# ### Sweeping through diffusion coefficients
# Lets now see the effect that the diffusion coefficient of the positive electrode has on cell performance. We first set the reaction rate 
# to the original value in the parameter set, and then follow the same procedure as above.

cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1.0e-13

log_D_start = -10.0
log_D_stop = -15.0

outputs_diff = []

for d in range(log_D_start, log_D_stop, length = 10)
	cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 10^d
	sim = Simulation(model, cell_parameters, cycling_protocol)
	result = solve(sim; end_report = false)
	push!(outputs_diff, (d = d, output = result))  # store r together with output
end
nothing # hide

fig1 = Figure()
ax1 = Axis(fig1[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

for data in outputs_diff
	if length(data.output[:states]) > 0 #if simulation is successful
		local t = [state[:Control][:Controller].time for state in data.output[:states]]
		local E = [state[:Control][:ElectricPotential][1] for state in data.output[:states]]
		lines!(ax1, t, E, label = @sprintf("%.1e", 10^data.d))
	end
end

fig1[1, 2] = Legend(fig1, ax1, "Diffusion Coefficient", framevisible = false)
fig1 # hide

# Diffusion coefficients, just as reaction rates, have also a non-linear effect on the cells voltage and capacity. Diffusion coefficients
# down to 5e-14  have negligible influence on the cell voltage curve. However, as the coefficients fall below 5e-14 they start to influence
# the curves and the cell's capacity in a noticeable way. The effect becomes more pronounced at lower values. As with reaction rates,  
# these observations might originate from the interplay between Li+ diffusion and reaction processes, where the cell's overpotential responds
# to the transport limiting step.
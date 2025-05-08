# # Study Power Capability

# In this tutorial, we will study the effects that electrode thicknesses have over the power delivered by a cell. Power capability is usually determined from the
# loss in capacity when cycling the cell at higher rates. We will compare the effects of thickness on the power delivery of a cell.

# ### Load required packages, model and data

using BattMo, GLMakie, Printf

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cc_discharge_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model_setup = LithiumIonBattery()
#%%
# ### Outline our experiment
# We will change the thickness of the positive electrode, and evaluate the cell capacity at different CRates. Lets define the DRates to use, the range of thicknesses
# to explore, and a handy function to calculate the discharge capacity, using a basic trapezoidal rule to integrate time and current.
#%%
d_rates = [0.05, 0.1, 0.2, 0.5, 1.0, 2.0]
thicknesses = range(8.0e-5, 10.0e-5, length = 9)

function compute_discharge_capacity(output::NamedTuple)
	t = [state[:Control][:Controller].time for state in output[:states]]
	I = [state[:Control][:Current][1] for state in output[:states]]
	diff_t = diff(t)
	insert!(diff_t, 1, t[1])
	return sum(diff_t .* I) / 3600
end

# Now we loop through both DRates and thicknesses to run a simulation for each combination. For each simulation, we will calculate the discharge capacity, and store it for
# plotting.
power_rates = []

for thickness in thicknesses

	capacities = []
	cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"] = thickness

	for d_rate in d_rates

		cc_discharge_protocol["DRate"] = d_rate
		sim = Simulation(model_setup, cell_parameters, cc_discharge_protocol)
		print("###### Simulation of thickness $thickness | d_rate $d_rate #########")
		output = solve(sim; config_kwargs = (; end_report = false))

		if length(output[:states]) > 0 #if simulation is successful
			discharge_capacity = compute_discharge_capacity(output)
			push!(capacities, discharge_capacity)
		else
			push!(capacities, 0.0)
		end
	end
	push!(power_rates, (thickness = thickness, d_rates = d_rates, capacities = capacities))
end
nothing # hide
#%%
# ### Analyze Capacities
# Now we plot capacities vs Drate at different thicknesses of the positive electrode:

fig = Figure(size = (1000, 400))
ax = Axis(fig[1, 1], title = "Power capability vs Thickness of Negative Electrode", xlabel = "DRate", ylabel = "Capacity/Ah")

for experiment in power_rates

	label_str = @sprintf("%.1e", experiment.thickness)
	lines!(ax, experiment.d_rates, experiment.capacities, label = label_str)
end

fig[1, 2] = Legend(fig, ax, "Thicknesses", framevisible = false)
fig

# WHY CELL CAPACITY INCREASES WHITH NEGATIVE ELECTRODE THICKNESS, AFTER IT HAS PASSED NP>1? STRANGE!!!!!!!!!

# # Handling cycling protocols

# In this tutorial, we demonstrate functionality to handle cycling protcols. We will illustrate the effect that the DRate has on battery 
# performance during discharge, using a constant-current (CC) discharge protocol.

# ### Load required packages and data
# We start by loading the necessary parameters sets and instantiating a model. For the cyling protocol, we'll start from the default constant current discharge protocol.

using BattMo, GLMakie, Printf

# Load cell and model setup

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cc_discharge_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

# Load default model
model = LithiumIonBattery()

# ### Handle, access and edit cycling protocols
# We manipulate a cycling protocol in the same was as we do cell parameters in the previous tutorial. To list all outermost keys:
keys(cc_discharge_protocol)

# Show all keys and values
cc_discharge_protocol.all

# Search for a specific parameter
search_parameter(cc_discharge_protocol, "rate")

# Access a specific parameter
cc_discharge_protocol["DRate"]

# Change protocol parameters as dicitonaries
cc_discharge_protocol["DRate"] = 2.0

# ### Compare cell performance across DRates
# Lets now do something more fun. Since we can edit scalar valued parameters as we edit dictionaries, we can loop through different DRates and run
# a simulation for each. We can then compare the cell voltage profiles for each DRate.

# Let’s define the range of C-rates to explore:
d_rates = [0.2, 0.5, 1.0, 2.0]

# Now loop through these values, update the protocol, and store the results:
outputs = []

for d_rate in d_rates
	protocol = deepcopy(cc_discharge_protocol)
	protocol["DRate"] = d_rate

	sim = Simulation(model, cell_parameters, protocol)
	output = solve(sim; info_level = -1)
	push!(outputs, (d_rate = d_rate, output = output))
end
nothing # hide

# ### Analyze Voltage and Capacity
# We'll extract the voltage vs. time and delivered capacity for each C-rate:

fig = Figure(size = (1000, 400))
ax1 = Axis(fig[1, 1], title = "Voltage vs Time", xlabel = "Time / s", ylabel = "Voltage / V")

for result in outputs

	t = result.output.time_series["Time"]
	E = result.output.time_series["Voltage"]
	I = result.output.time_series["Current"]

	label_str = @sprintf("%.1fC", result.d_rate)
	lines!(ax1, t, E, label = label_str)

end

fig[1, 3] = Legend(fig, ax1, "C-rates", framevisible = false)
fig

# We see this cell has poor power capabilities since its capacity decreases quite rapidly with DRate.

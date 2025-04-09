# # Handling cycling protocols

# In this tutorial, we demonstrate functionality to handle cycling protcols, by illustrating the effect that the CRate has on battery 
# performance during discharge, using a constant-current (CC) discharge protocol.

# ### Load required packages and data
# We start by loading the necessary parameters sets and instantiating a model. For the cyling protocol, we'll start from the default constant current discharge protocol.

using BattMo, GLMakie, Printf

# Load cell and model setup
cell_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
cycling_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(cell_path)
cc_discharge_protocol = read_cycling_protocol(cycling_path)

# Load default model
model = LithiumIonBatteryModel()

# ### Handle, access and edit cycling protocols
# We manipulate the cycling protocol object in the same was as we do cell parameters in the previous tutorial. List all outermost keys:
keys(cc_discharge_protocol)

# Show all keys and values
cc_discharge_protocol.all

# Search for a specific parameter
search_parameter(cc_discharge_protocol, "rate")

# Access a specific parameter
cc_discharge_protocol["DRate"]

# We also change protocol parameters as dicitonaries
cc_discharge_protocol["DRate"] = 2.0

# ### Compare cell performance across DRates
# Lets now do something more fun. Since we can edit scalar valued parameters with dictionary notation, we can loop through different DRates and run
# a simulation for each. We can then compare the cell voltage profiles for each DRate.

# Let’s define the range of C-rates to explore:
d_rates = [0.2, 0.5, 1.0, 2.0]

# Now loop through these values, update the protocol, and store the results:
outputs = []

for d_rate in d_rates
	protocol = deepcopy(cc_discharge_protocol)
	protocol["DRate"] = d_rate

	sim = Simulation(model, cell_parameters, protocol)
	output = solve(sim; config_kwargs = (; end_report = false))
	push!(outputs, (d_rate = d_rate, output = output))
end
nothing # hide

# ### Analyze Voltage and Capacity
# We'll extract the voltage vs. time and delivered capacity for each C-rate:

fig = Figure(size = (1000, 400))
ax1 = Axis(fig[1, 1], title = "Voltage vs Time", xlabel = "Time / s", ylabel = "Voltage / V")

for result in outputs

	states = result.output[:states]
	t = [state[:Control][:ControllerCV].time for state in states]
	E = [state[:Control][:Phi][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	label_str = @sprintf("%.1fC", result.d_rate)
	lines!(ax1, t, E, label = label_str)

end

fig[1, 3] = Legend(fig, ax1, "C-rates", framevisible = false)
fig

# We see this cell has poor power capabilities since its capacity decreases quite rapidly with DRate.

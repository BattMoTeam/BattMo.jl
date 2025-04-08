# # Exploring the Impact of C-Rate in a CC Discharge Protocol

# In this tutorial, we’ll demonstrate how to programmatically modify a cycling protocol—specifically, the C-rate in a constant-current (CC) 
# discharge protocol—and examine its effect on battery performance and capacity.

# ### Load Required Packages and Data
# We start by loading the necessary parameters sets and instantiating a model. For the cyling protocol, we'll start from the default constant current discharge protocol.

using BattMo, GLMakie, Printf

# Load cell and model setup
cell_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
cycling_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(cell_path)
cc_discharge_protocol = read_cycling_protocol(cycling_path)

# Load default model
model = LithiumIonBatteryModel()

# ### Modify the Cycling Protocol – Varying the C-Rate

# We can have a look at the content of the CylingProtocol object:
cc_discharge_protocol.all

# Let’s define the range of C-rates to explore:
c_rates = [0.2, 0.5, 1.0, 2.0]

# Now loop through these values, update the protocol, and store the results:
outputs = []

for c_rate in c_rates
	protocol = deepcopy(cc_discharge_protocol)
	protocol["DRate"] = c_rate

	sim = Simulation(model, cell_parameters, protocol)
	output = solve(sim; config_kwargs = (; end_report = false))
	push!(outputs, (c_rate = c_rate, output = output))
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

	lines!(ax1, t, E, label = "@sprintf(\"%.1fC\", result.c_rate)")

end

fig[1, 3] = Legend(fig, ax1, "C-rates", framevisible = false)
fig

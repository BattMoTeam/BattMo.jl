# # Exploring the Impact of C-Rate in a CC Discharge Protocol

# In this tutorial, we demonstrate the effect that the CRate has on battery performance during discharge, using a constant-current (CC) discharge protocol.

# ### Load Required Packages and Data
# We start by loading the necessary parameters sets and instantiating a model. For the cyling protocol, we'll start from the default constant current discharge protocol.

using BattMo, GLMakie, Printf

# Load cell and model setup
cell_path = parameter_file_path("cell_parameters", "Chen2020_calibrated.json")
cycling_path = parameter_file_path("cycling_protocols", "CCDischarge.json")

cell_parameters = load_cell_parameters(; from_file_path = cell_path)
cc_discharge_protocol = load_cycling_protocol(; from_file_path = cycling_path)

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

	label_str = @sprintf("%.1fC", result.c_rate)
	lines!(ax1, t, E, label = label_str)

end

fig[1, 3] = Legend(fig, ax1, "C-rates", framevisible = false)
fig

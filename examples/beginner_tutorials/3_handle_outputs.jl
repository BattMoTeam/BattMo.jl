# # Handling simulation outputs

# In this tutorial we will explore the outputs of a simulation for interesting tasks:
# - Plot voltage and current curves
# - Plot overpotentials
# - Plot cell states in space and time
# - Save outputs
# - Load outputs.

# Lets start with loading some pre-defined cell parameters, cycling protocols, and running a simulation. 

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
nothing # hide

model = LithiumIonBattery()

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim);
nothing # hide


# Now we'll have a look into what the output entail. The ouput is of type SimulationOutput and contains multiple output quantity dicts, the full input dict and some other structures. Lets print the
# keys. 

keys(output)

# In terms of simulation results, we can see that the output structure includes time series data, states data and metrics data. Furthermore, it includes the full input dict, some output structure from Jutul, the model instance, and the simulation instance.
# Let's for now have a look into the simulation results and see how we can access certain output quantities. 

# In BattMo, we make a distinction between three types of results:
# - time series: includes all quantities that only depend on time. For example, time itself, cell voltage, current, capacity, etc.
# - states: includes all the state quantities like for example, concentration, potential, charge, etc. These quantities can depend on time, position, and radius.
# - metrics: includes all the from output quantities calculated cell metrics like discharge capacity, charge energy, round trip efficiency, etc. These metrics depend on the cycle number.

# The have an overview of all the quantities that are available you can run:
print_output_overview(output)

# To get more information on particular output variables, for example all that have concentration in their name:
print_output_variable_info("concentration")

# As the time series, states, and metrics structures are dicts we can retrieve quantities by accessing their key. Let's for example create a simple voltage vs capacity plot.

voltage = output.time_series["Voltage"]
capacity = output.time_series["Capacity"]

fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Capacity / Ah", title = "Discharge curve")
lines!(ax, capacity, voltage)
display(fig)

# Or lets plot the lithium concentration versus the active material particle radius of the positive electrode close to the separator at the and of the discharge:
radius = output.states["PositiveElectrodeActiveMaterialRadius"]
positive_electrode_concentration = output.states["PositiveElectrodeActiveMaterialParticleConcentration"]

simulation_settings = output.input["SimulationSettings"] # Retrieve the default simulation settings to get the grid point number that we need.

grid_point = simulation_settings["NegativeElectrodeCoatingGridPoints"] + simulation_settings["SeparatorGridPoints"] + 1 # First grid point of the positive electrode

concentration_at_grid_point = positive_electrode_concentration[end, grid_point, :]

fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Lithium concentration / mol·L⁻¹", xlabel = "Particle radius / m", title = "Positive electrode concentration")
lines!(ax, radius, concentration_at_grid_point)
display(fig)




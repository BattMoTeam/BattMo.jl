using BattMo, GLMakie

# Load cell parameters and cycling protocol
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

# We want to setup the model and simulation for P4D simulations
model_settings = load_model_settings(; from_default_set = "P4D_cylindrical")
simulation_settings = load_simulation_settings(; from_default_set = "P4D_cylindrical")

# We adjust the parameters so that the simulation in this example is not too long (around a couple of minutes)

cell_parameters["Cell"]["OuterRadius"]                                   = 0.004
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.5]
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabFractions"] = [0.5]
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"]     = 0.002
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"]     = 0.002
simulation_settings["GridResolutionAngular"]                             = 30

# Setup the model
model = LithiumIonBattery(; model_settings)

# Setup the simulation
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# Solve the simulation
output = solve(sim, info_level = -1)

# Cool interactive plotting of the results in the 3D geometry
plot_interactive_3d(output)


fig = Figure()

# Create a colorbar with the colormap `:curl`
Colorbar(fig[1, 1],
	colormap = :curl,
	limits = (minimum(zdata_clean), maximum(zdata_clean)),
	label = "Electrolyte concentration  /  mol·m⁻³",
)

fig

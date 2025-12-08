using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

# The cell parameters represent a full stack, but right now we only have a 3D geometry of a single layer pouch available, 
# so we calculate the ElectrodeGeometricSurfaceArea for one layer using the ElectrodeLength and ElectrodeWidth:

cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = cell_parameters["Cell"]["ElectrodeLength"] * cell_parameters["Cell"]["ElectrodeWidth"]

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol);
output = solve(sim)

plot_dashboard(output)

plot_interactive_3d(output; colormap = :curl)



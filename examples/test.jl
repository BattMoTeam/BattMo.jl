

using BattMo, WGLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model = LithiumIonBattery()


sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim; info_level = -1)

plot_dashboard(output; plot_type = "contour")


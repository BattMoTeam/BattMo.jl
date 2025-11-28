

using BattMo, GLMakie


cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

model = LithiumIonBattery()


sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim;)

plot_dashboard(output; plot_type = "contour")


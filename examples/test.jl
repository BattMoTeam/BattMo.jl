using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model = SodiumIonBattery()

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim);

plot_dashboard(output)
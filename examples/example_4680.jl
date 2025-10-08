using BattMo, GLMakie

cell_parameters = load_cell_parameters(from_file_path = "4680_cell.json")
cycling_protocol = load_cycling_protocol(from_default_set = "CCDischarge")

model = LithiumIonModel()

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim)
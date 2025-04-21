using BattMo

model_settings = load_model_settings(; from_default_set = "P2D")
cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model = LithiumIonBatteryModel(; model_settings);



sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim; accept_invalid = true)
using Jutul, BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P4D_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")

battery_model = LithiumIonBatteryModel(; model_settings)

sim = Simulation(battery_model, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim)


states = output[:states]
solved_model = output[:extra][:model]

# @info typeof(solved_model.models)
dx = [0.02 0 0]
shift = Dict()
shift[:NAM] = dx
shift[:PAM] = dx
shift[:CC] = dx
shift[:PP] = dx

plot_multimodel_interactive(solved_model, states, shift = shift, colormap = :curl)

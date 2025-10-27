using BattMo, GLMakie

################################
# Load parameters and settings
cell_parameters_ank = load_cell_parameters(from_file_path = joinpath(@__DIR__, "input_files", "cell_parameters", "cell_parameters_4680_initial.json"))
cell_parameters_chen = load_cell_parameters(from_file_path = joinpath(@__DIR__, "input_files", "cell_parameters", "cell_parameters_chen_2020.json"))
cycling_protocol = load_cycling_protocol(from_default_set = "cc_discharge")
model_settings = load_model_settings(from_default_set = "p2d")
solver_settings = load_solver_settings(from_default_set = "direct")

# fill up missing parameters in ankit's file with chen's file
# cell_parameters = merge_input(cell_parameters_ank, cell_parameters_chen; type = "fill")


################################
# Add Temperature dependence
# model_settings["TemperatureDependence"] = "Arrhenius"

################################
# Alter cycling protocol
cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["UpperVoltageLimit"] = 4.2
cycling_protocol["DRate"] = 0.5


################################
# Run simulation

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters_ank, cycling_protocol)

output = solve(sim; solver_settings, accept_invalid = true);

################################
# Plot results
plot_dashboard(output; plot_type = "contour")

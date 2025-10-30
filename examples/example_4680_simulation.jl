using BattMo, GLMakie

################################
# Load parameters and settings
cell_parameters = load_cell_parameters(from_file_path = joinpath(@__DIR__, "example_input", "cell_parameters", "tesla_4680_before_calibration.json"))
cycling_protocol = load_cycling_protocol(from_default_set = "cc_discharge")
model_settings = load_model_settings(from_default_set = "p2d")
solver_settings = load_solver_settings(from_default_set = "direct")

################################
# Add Temperature dependence
# model_settings["TemperatureDependence"] = "Arrhenius"

################################
# Alter cycling protocol
# cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["UpperVoltageLimit"] = 3.7
cycling_protocol["LowerVoltageLimit"] = 3.0
cycling_protocol["DRate"] = 1


################################
# Run simulation

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim; solver_settings, accept_invalid = true);

################################
# Plot results
plot_dashboard(output; plot_type = "contour")

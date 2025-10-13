using BattMo, GLMakie

################################
# Load parameters and settings
cell_parameters = load_cell_parameters(from_file_path = joinpath(@__DIR__, "4680_cell.json"))
cycling_protocol = load_cycling_protocol(from_default_set = "CCCharge")
model_settings = load_model_settings(from_default_set = "P2D")
solver_settings = load_solver_settings(from_default_set = "direct")

################################
# Add Temperature dependence
model_settings["TemperatureDependence"] = "Arrhenius"

################################
# Alter cycling protocol
cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["UpperVoltageLimit"] = 4.2
cycling_protocol["CRate"] = 2


model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim; solver_settings)
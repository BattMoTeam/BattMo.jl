using Jutul, BattMo, GLMakie, Statistics

model_settings = load_model_settings(; from_default_set = "p4d_pouch")
cell_parameters = load_model_settings(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")


# Add Thermal Model
model_settings["ThermalModel"] = "Sequential"


# Add thermal parameters
cell_parameters["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
cell_parameters["ThermalModel"]["source"]                          = 1e4
cell_parameters["ThermalModel"]["conductivity"]                    = 12


model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol)

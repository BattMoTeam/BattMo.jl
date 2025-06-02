using BattMo

model_settings = load_model_settings(; from_default_set = "P4D_pouch")
model_settings["SEIModel"] = "Bolay"

model_setup = LithiumIonBattery(; model_settings)

empty_cell_parameter_set = load_cell_parameters(; from_model_template = model_setup)

file_path = "Ai2020.json"
write_to_json_file(file_path, empty_cell_parameter_set)

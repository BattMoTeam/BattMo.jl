using BattMo

model_settings = load_model_settings(; from_default_set = "P2D")
model_settings["UseSEIModel"] = "Bolay"
model_settings["UseThermalModel"] = "Sequential"
model_settings.all

model = LithiumIonBatteryModel(; model_settings);

empty_cell_parameters = load_cell_parameters(; from_model_template = model);

fn = "/home/lhendrix/repositories/BattMo.jl/src/input/defaults/cell_parameters/Xu2015.json"
write_to_json_file(fn, empty_cell_parameters)
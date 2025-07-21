using BattMo

model_settings = ModelSettings(Dict(
	"ModelFramework" => "P2D",
	"TransportInSolid" => "FullDiffusion",
	"RampUp" => "Sinusoidal"))

model_setup = LithiumIonBattery(; model_settings)


cell_parameters = load_cell_parameters(; from_model_template = model_setup)
write_to_json_file("Garapati2025.json", cell_parameters)

using BattMo

model_settings = ModelSettings(Dict(
	"ModelFramework" => "P4D Cylindrical",
	"TransportInSolid" => "FullDiffusion",
	"CurrentCollectors" => "Generic",
	"RampUp" => "Sinusoidal",
	# "SEIModel" => "Bolay",
))

model_setup = LithiumIonBattery(; model_settings)


cell_parameters = load_cell_parameters(; from_model_template = model_setup)
simulation_settings = load_simulation_settings(; from_model_template = model_setup)

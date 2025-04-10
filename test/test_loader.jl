using BattMo
using Test

@testset "loader" begin

	@test begin

		model_settings = load_model_settings(; from_default_set = "P2D")


		# We instantiate a Lithium-ion battery model with default model settings
		model = LithiumIonBatteryModel(; model_settings)
		file_path_cell = string(dirname(pathof(BattMo)), "/../src/input/defaults/cell_parameters/", "Chen2020_calibrated.json")
		file_path_cycling = string(dirname(pathof(BattMo)), "/../src/input/defaults/cycling_protocols/", "CCDischarge.json")
		file_path_model = string(dirname(pathof(BattMo)), "/../src/input/defaults/model_settings/", "P2D.json")
		file_path_simulation = string(dirname(pathof(BattMo)), "/../src/input/defaults/simulation_settings/", "P2D.json")

		model_settings = load_model_settings(; from_file_path = file_path_model)
		cell_parameter_set = load_cell_parameters(; from_file_path = file_path_cell)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)
		cyling_settings = load_cycling_protocol(; from_file_path = file_path_cycling)

		model_settings = load_model_settings(; from_default_set = "P2D")
		cell_parameter_set = load_cell_parameters(; from_default_set = "Chen2020")
		simulation_settings = load_simulation_settings(; from_default_set = "P2D")
		cyling_settings = load_cycling_protocol(; from_default_set = "CCCV")


		cell_parameter_set = load_cell_parameters(; from_model_template = model)
		simulation_settings = load_simulation_settings(; from_model_template = model)

		true

	end

end




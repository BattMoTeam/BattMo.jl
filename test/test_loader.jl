using BattMo
using Test

@testset "loader" begin

	@test begin

		model_settings = load_model_settings(; from_default_set = "P2D")


		# We instantiate a Lithium-ion battery model with default model settings
		model_setup = LithiumIonBattery(; model_settings)
		file_path_cell = parameter_file_path("cell_parameters", "Chen2020.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
		file_path_model = parameter_file_path("model_settings", "P2D.json")
		file_path_simulation = parameter_file_path("simulation_settings", "P2D.json")

		model_settings = load_model_settings(; from_file_path = file_path_model)
		cell_parameter_set = load_cell_parameters(; from_file_path = file_path_cell)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)
		cyling_settings = load_cycling_protocol(; from_file_path = file_path_cycling)

		model_settings = load_model_settings(; from_default_set = "P2D")
		cell_parameter_set = load_cell_parameters(; from_default_set = "Chen2020")
		simulation_settings = load_simulation_settings(; from_default_set = "P2D")
		cyling_settings = load_cycling_protocol(; from_default_set = "CCCV")


		cell_parameter_set = load_cell_parameters(; from_model_template = model_setup)
		simulation_settings = load_simulation_settings(; from_model_template = model_setup)
		simulation_settings = load_simulation_settings(; from_model_template = model_setup, empty = true)
		@test simulation_settings["TimeStepDuration"] == 0
		simulation_settings = load_solver_settings(; from_model_template = model_setup)

		true

	end

end

@testset "paths" begin
	@test isa(parameter_file_path(), String)
	@test isdir(parameter_file_path())
	@test isfile(parameter_file_path("cell_parameters", "Chen2020"))
	@test parameter_file_path("cell_parameters", "Chen2020") |> splitext |> last == ".json"
	@test_throws "File not found at" parameter_file_path("cell_parameters", "BadName")
	@test isa(parameter_file_path("cell_parameters", "BadName", check = false), String)
end

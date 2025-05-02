using BattMo
using Test


@testset "sei layer" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "SEI_example.json")
		file_path_model = parameter_file_path("model_settings", "P2D.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "CCCV.json")
		file_path_simulation = parameter_file_path("simulation_settings", "P2D.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)


		########################################

		model_settings["UseSEIModel"] = "Bolay"

		model = LithiumIonBattery(; model_settings)

		cycling_protocol["TotalNumberOfCycles"] = 10

		sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

		output = solve(sim)

		true

	end

end


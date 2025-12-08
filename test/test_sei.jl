using BattMo
using Test


@testset "sei layer" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "chen_2020.json")
		file_path_model = parameter_file_path("model_settings", "p2d.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "cccv.json")
		file_path_simulation = parameter_file_path("simulation_settings", "p2d.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)


		########################################

		model_settings["SEIModel"] = "Bolay"

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["TotalNumberOfCycles"] = 10

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

		output = solve(sim)

		states = output.states

		sei_thickness = states["SEIThickness"]
		voltage_drop = states["SEIVoltageDrop"]


		@test length(sei_thickness[:, 2]) ≈ 1836 atol = 0
		@test sei_thickness[2, 2] ≈ 1.0000000339846753e-8 atol = 1e-1
		@test voltage_drop[2, 2] ≈ -0.001401323958482127 atol = 1e-1

		@test sei_thickness[100, 2] ≈ 1.0000000339846753e-8 atol = 1e-1
		@test voltage_drop[100, 2] ≈ -0.001401323958482127 atol = 1e-1


		true

	end

end


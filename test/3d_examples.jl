using BattMo
using Test


@testset "3d" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "3D_demo_example.json")
		file_path_model = parameter_file_path("model_settings", "P4D_pouch.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
		file_path_simulation = parameter_file_path("simulation_settings", "P4D_pouch.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)

		model = LithiumIonBatteryModel(; model_settings)

		sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		Cc = map(x -> x[:Control][:Current][1], output.states)
		Phi = map(x -> x[:Control][:Phi][1], output.states)
		@test length(output.states) == 84
		@test Cc[2] ≈ 0.00343 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.0076079 atol = 1e-2
		end
		@test Phi[1] ≈ 4.163 atol = 1e-2
		true

	end

end


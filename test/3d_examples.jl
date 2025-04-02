using BattMo
using Test


@testset "3d" begin

	@test begin

		file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_3D_demoCase.json")
		file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P4D_pouch.json")
		file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")
		file_path_simulation = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simulation_settings/", "simulation_settings_3D_demoCase.json")

		cell_parameters = read_cell_parameters(file_path_cell)
		cycling_protocol = read_cycling_protocol(file_path_cycling)
		model_settings = read_model_settings(file_path_model)
		simulation_settings = read_simulation_settings(file_path_simulation)

		model = LithiumIonBatteryModel(; model_settings)

		sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		Cc = map(x -> x[:Control][:Current][1], output.states)
		Phi = map(x -> x[:Control][:Phi][1], output.states)
		@test length(output.states) == 77
		@test Cc[1] ≈ 0.00058 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.008165 atol = 1e-2
		end
		@test Phi[1] ≈ 4.185 atol = 1e-2
		@test Phi[end] ≈ 2.76 atol = 1e-2
		@test Phi[30] ≈ 3.67 atol = 1e-2
		true

	end

end


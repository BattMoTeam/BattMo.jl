using BattMo
using Test


@testset "3d" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "Xu2015.json")
		file_path_model = parameter_file_path("model_settings", "P4D_pouch.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
		file_path_simulation = parameter_file_path("simulation_settings", "P4D_pouch.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)

		model_setup = LithiumIonBattery(; model_settings)

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		jutul_states = output.jutul_output.states

		Cc = map(x -> x[:Control][:Current][1], jutul_states)
		Voltage = map(x -> x[:Control][:ElectricPotential][1], jutul_states)
		@test length(jutul_states) == 137
		@test Cc[2] ≈ 0.02321200713128439 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.0514688 atol = 1e-2
		end
		@test Voltage[1] ≈ 3.3147 atol = 1e-2
		true

	end

end


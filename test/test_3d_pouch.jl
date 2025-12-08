using BattMo
using Test


@testset "3d" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "xu_2015.json")
		file_path_model = parameter_file_path("model_settings", "p4d_pouch.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "cc_discharge.json")
		file_path_simulation = parameter_file_path("simulation_settings", "p4d_pouch.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)

		cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = cell_parameters["Cell"]["ElectrodeLength"] * cell_parameters["Cell"]["ElectrodeWidth"]

		model_setup = LithiumIonBattery(; model_settings)

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		jutul_states = output.jutul_output.states

		Cc = map(x -> x[:Control][:Current][1], jutul_states)
		Voltage = map(x -> x[:Control][:ElectricPotential][1], jutul_states)
		@test length(jutul_states) == 283
		@test Cc[2] ≈ 0.007655831434316383 atol = 1e-2
		for i in 10:length(Cc)
			@test Cc[i] ≈ 0.0908540179479099 atol = 1e-2
		end
		@test Voltage[1] ≈ 3.3506683313852914 atol = 1e-2
		true

	end

end


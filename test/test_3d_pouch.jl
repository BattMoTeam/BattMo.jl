using BattMo
using Jutul
using Test


@testset "3d single layer pouch" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "xu_2015.json")
		file_path_model = parameter_file_path("model_settings", "p4d_pouch.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "cc_discharge.json")
		file_path_simulation = parameter_file_path("simulation_settings", "p4d_pouch.json")

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
		@test length(jutul_states) == 142
		@test Cc[2] ≈ 0.03316973899191637 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.09085401794790987 atol = 1e-2
		end
		@test Voltage[1] ≈ 3.3506683313852914 atol = 1e-2
		cc_pos = output.states["NegativeElectrodeCurrentCollectorPosition"]
		cc_phi = output.states["NegativeElectrodeCurrentCollectorPotential"]
		@test cc_pos isa BattMoPosition
		@test cc_phi isa BattMoStateArray
		@test size(cc_phi, 2) == Jutul.number_of_cells(cc_pos.mesh)
		@test all(isfinite, cc_phi[end, :])
		@test length(cc_phi[end]) == Jutul.number_of_cells(cc_pos.mesh)
		@test Jutul.physical_representation(cc_pos) === Jutul.physical_representation(sim.grids["NegativeCurrentCollector"])
		true

	end

end

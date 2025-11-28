using BattMo
using Test


@testset "3d cylindrical" begin

	@test begin

		cell_parameters     = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol    = load_cycling_protocol(; from_default_set = "cc_discharge")
		model_settings      = load_model_settings(; from_default_set = "p4d_cylindrical")
		simulation_settings = load_simulation_settings(; from_default_set = "p4d_cylindrical")

		cell_parameters["Cell"]["OuterRadius"]                                   = 0.004
		cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.5]
		cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabFractions"] = [0.5]
		cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"]     = 0.002
		cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"]     = 0.002
		simulation_settings["AngularGridPoints"]                                 = 8

		model_setup = LithiumIonBattery(; model_settings)

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = BattMo.solve(sim)

		jutul_states = output.jutul_output.states

		Cc = map(x -> x[:Control][:Current][1], jutul_states)
		Voltage = map(x -> x[:Control][:ElectricPotential][1], jutul_states)
		@test length(jutul_states) == 127
		@test Cc[2] ≈ 0.13169734454474818 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.2920173995165871 atol = 1e-2
		end
		@test Voltage[1] ≈ 4.150564875292687 atol = 1e-2
		true

	end

end


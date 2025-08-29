using BattMo
using Test

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

@testset "sei layer" begin

	@test begin

		file_path_cell = parameter_file_path("cell_parameters", "Chayambuka2022.json")
		file_path_model = parameter_file_path("model_settings", "P2D.json")
		file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
		file_path_simulation = parameter_file_path("simulation_settings", "P2D.json")

		cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
		cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
		model_settings = load_model_settings(; from_file_path = file_path_model)
		simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)


		######### Alter model settings #########
		model_settings["ButlerVolmer"] = "Chayambuka"

		######### Alter simulation settings #########
		simulation_settings["GridNegativeElectrodeCoating"] = 8
		simulation_settings["GridPositiveElectrodeCoating"] = 50
		simulation_settings["GridNegativeElectrodeParticle"] = 50
		simulation_settings["GridPositiveElectrodeParticle"] = 50
		simulation_settings["GridSeparator"] = 5

		######### Alter cycling protocol #########
		cycling_protocol["InitialStateOfCharge"] = 0.99
		cycling_protocol["LowerVoltageLimit"] = 2.0
		cycling_protocol["UpperVoltageLimit"] = 4.2

		model = SodiumIonBattery(; model_settings)

		drates = [0.1, 1.4]
		delta_t = [200, 50]
		I_test = [0.0002664523159462069, 0.003730332423246896]
		c_test = [3974.731704738329, 4041.6330669116232]

		for (i, rate) in enumerate(drates)

			cycling_protocol["DRate"] = rate
			simulation_settings["TimeStepDuration"] = delta_t[i]

			sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

			output = solve(sim;)
			I = get_output_time_series(output)[:Current]
			c_pe = get_output_states(output)[:PeAmSurfaceConcentration]

			@test I[end] ≈ I_test[i] atol = 1e-1

			@test c_pe[2, 23] ≈ c_test[i] atol = 1e-1


		end


		true

	end

end


using BattMo
using Test


@testset "sei layer" begin

	@test begin

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
		model_settings = load_model_settings(; from_default_set = "p2d")

		########################################

		model_settings["TemperatureDependence"] = "Arrhenius"

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["InitialTemperature"] = 298.5 - 15
		sim_10 = Simulation(model_setup, cell_parameters, cycling_protocol)

		output_10 = solve(sim_10)

		cycling_protocol_2 = deepcopy(cycling_protocol)
		cycling_protocol_2["InitialTemperature"] = 298.5 + 20
		sim_45 = Simulation(model_setup, cell_parameters, cycling_protocol_2)

		output_45 = solve(sim_45)

		time_series_10 = output_10.time_series
		time_series_45 = output_45.time_series

		voltage_10 = time_series_10["Voltage"]
		voltage_45 = time_series_45["Voltage"]

		@test length(voltage_10) ≈ 145 atol = 1
		@test voltage_10[10] ≈ 4.000031958338107 atol = 1e-1
		@test voltage_10[end-10] ≈ 3.067277996724986 atol = 1e-1

		@test length(voltage_45) ≈ 145 atol = 1
		@test voltage_45[10] ≈ 3.9903508529579135 atol = 1e-1
		@test voltage_45[end-10] ≈ 3.0561237870691453 atol = 1e-1


		true

	end

end
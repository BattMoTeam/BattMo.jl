using BattMo
using Test

@testset "Crate" begin

	@test begin

		############################
		# cc_discharge

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
		model_settings = load_model_settings(; from_default_set = "p2d")
		simulation_settings = load_simulation_settings(; from_default_set = "p2d")

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["DRate"] = 1

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = output.time_series

		I_1 = time_series["Current"]

		@test I_1[2] ≈ 2.2957366076223953 atol = 1e-1

		cycling_protocol["DRate"] = 2

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = output.time_series

		I_2 = time_series["Current"]

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2


		############################
		# cc_charge

		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_charge")
		cycling_protocol["CRate"] = 1
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series

		I_1 = time_series["Current"]

		@test I_1[2] ≈ -2.2957366076223953 atol = 1e-1

		cycling_protocol["CRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series

		I_2 = time_series["Current"]

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2

		############################
		# constant_current_cycling

		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_cycling")
		cycling_protocol["CRate"] = 1
		cycling_protocol["DRate"] = 1
		cycling_protocol["InitialControl"] = "charging"
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series

		I_1 = time_series["Current"]

		@test I_1[2] ≈ -5.090421803494574 atol = 1e-1
		@test I_1[50] ≈ 5.090421803494574 atol = 1e-1

		cycling_protocol["CRate"] = 2
		cycling_protocol["DRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series

		I_2 = time_series["Current"]

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2
		@test I_2[50] ≈ I_1[50] * 2 atol = 1e-2


		############################
		# cccv

		cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")
		cycling_protocol["CRate"] = 1
		cycling_protocol["DRate"] = 1
		cycling_protocol["InitialControl"] = "charging"
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series



		I_1 = time_series["Current"]



		@test I_1[2] ≈ -5.090421803494574 atol = 1e-1
		@test I_1[765] ≈ 5.090421803494574 atol = 1e-1

		cycling_protocol["CRate"] = 2
		cycling_protocol["DRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = output.time_series

		I_2 = time_series["Current"]

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2
		@test I_2[200] ≈ I_1[765] * 2 atol = 1e-2

		true

	end

end


@testset "defaults" begin

	@test begin

		############################
		# cc_discharge

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
		model_settings = load_model_settings(; from_default_set = "p2d")
		simulation_settings = load_simulation_settings(; from_default_set = "p2d")

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["DRate"] = 1

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = output.time_series
		states = output.states

		I = time_series["Current"]
		V = time_series["Voltage"]

		c_pe = states["PositiveElectrodeActiveMaterialSurfaceConcentration"]

		@test length(I) ≈ 73 atol = 0
		@test I[2] ≈ 2.2957366076223953 atol = 1e-1
		@test V[2] ≈ 4.052549590713088 atol = 1e-1
		@test I[50] ≈ 5.090421803494574 atol = 1e-1
		@test V[50] ≈ 3.387878052062845 atol = 1e-1
		@test I[end] ≈ 5.090421803494574 atol = 1e-1
		@test V[end] ≈ 2.525881189309425 atol = 1e-1

		@test c_pe[2, 23] ≈ 18084.221948561288 atol = 1e-1
		@test c_pe[end, 23] ≈ 57329.88050522005 atol = 1e-1


		cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")


		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = output.time_series
		states = output.states

		I = time_series["Current"]
		V = time_series["Voltage"]

		c_pe = states["PositiveElectrodeActiveMaterialSurfaceConcentration"]

		@test length(I) ≈ 71 atol = 0
		@test I[2] ≈ 7.785132857514498 atol = 1e-1
		@test V[2] ≈ 3.274161650306443 atol = 1e-1
		@test I[50] ≈ 17.262263410102893 atol = 1e-1
		@test V[50] ≈ 3.1714628485061276 atol = 1e-1
		@test I[end] ≈ 17.262263410102893 atol = 1e-1
		@test V[end] ≈ 2.585957945404128 atol = 1e-1

		@test c_pe[2, 23] ≈ 4153.423114811395 atol = 1e-1
		@test c_pe[end, 23] ≈ 25408.889624542124 atol = 1e-1

		true


	end

end

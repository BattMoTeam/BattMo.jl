using BattMo
using Test
using GLMakie

@testset "Crate" begin

	@test begin

		############################
		# CCDischarge

		cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
		model_settings = load_model_settings(; from_default_set = "P2D")
		simulation_settings = load_simulation_settings(; from_default_set = "P2D")

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["DRate"] = 1

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = get_output_time_series(output)

		I_1 = time_series.Current

		@test I_1[2] ≈ 2.2957366076223953 atol = 1e-1

		cycling_protocol["DRate"] = 2

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = get_output_time_series(output)

		I_2 = time_series.Current

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2


		############################
		# CCCharge

		cycling_protocol = load_cycling_protocol(; from_default_set = "CCCharge")
		cycling_protocol["CRate"] = 1
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)

		I_1 = time_series.Current

		@test I_1[2] ≈ -2.2957366076223953 atol = 1e-1

		cycling_protocol["CRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)

		I_2 = time_series.Current

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2

		############################
		# CCCycling

		cycling_protocol = load_cycling_protocol(; from_default_set = "CCCycling")
		cycling_protocol["CRate"] = 1
		cycling_protocol["DRate"] = 1
		cycling_protocol["InitialControl"] = "charging"
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)

		I_1 = time_series.Current

		@test I_1[2] ≈ -5.090421803494574 atol = 1e-1
		@test I_1[50] ≈ 5.090421803494574 atol = 1e-1

		cycling_protocol["CRate"] = 2
		cycling_protocol["DRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)

		I_2 = time_series.Current

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2
		@test I_2[50] ≈ I_1[50] * 2 atol = 1e-2


		############################
		# CCCV

		cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
		cycling_protocol["CRate"] = 1
		cycling_protocol["DRate"] = 1
		cycling_protocol["InitialControl"] = "charging"
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)



		I_1 = time_series.Current



		@test I_1[2] ≈ -5.090421803494574 atol = 1e-1
		@test I_1[765] ≈ 5.090421803494574 atol = 1e-1

		cycling_protocol["CRate"] = 2
		cycling_protocol["DRate"] = 2
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)
		time_series = get_output_time_series(output)

		I_2 = time_series.Current

		@test I_2[2] ≈ I_1[2] * 2 atol = 1e-2
		@test I_2[200] ≈ I_1[765] * 2 atol = 1e-2

		true

	end

end


@testset "defaults" begin

	@test begin

		############################
		# CCDischarge

		cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
		model_settings = load_model_settings(; from_default_set = "P2D")
		simulation_settings = load_simulation_settings(; from_default_set = "P2D")

		model_setup = LithiumIonBattery(; model_settings)

		cycling_protocol["DRate"] = 1

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = get_output_time_series(output)
		states = get_output_states(output)

		I = time_series.Current
		V = time_series.Voltage

		c_pe = states.PeAmSurfaceConcentration

		@test length(I) ≈ 73 atol = 0
		@test I[2] ≈ 2.2957366076223953 atol = 1e-1
		@test V[2] ≈ 4.052549590713088 atol = 1e-1
		@test I[50] ≈ 5.090421803494574 atol = 1e-1
		@test V[50] ≈ 3.387878052062845 atol = 1e-1
		@test I[end] ≈ 5.090421803494574 atol = 1e-1
		@test V[end] ≈ 2.525881189309425 atol = 1e-1

		@test c_pe[2, 25] ≈ 17991.7558584136 atol = 1e-1
		@test c_pe[end, 25] ≈ 57138.82996751741 atol = 1e-1


		cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")


		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
		output = solve(sim)

		time_series = get_output_time_series(output)
		states = get_output_states(output)

		I = time_series.Current
		V = time_series.Voltage

		c_pe = states.PeAmSurfaceConcentration

		@test length(I) ≈ 66 atol = 0
		@test I[2] ≈ 0.057347311736114376 atol = 1e-1
		@test V[2] ≈ 3.274161650306443 atol = 1e-1
		@test I[50] ≈ 0.12715831819036466 atol = 1e-1
		@test V[50] ≈ 3.0611901672358672 atol = 1e-1
		@test I[end] ≈ 0.12715831819036466 atol = 1e-1
		@test V[end] ≈ 2.585957945404128 atol = 1e-1

		@test c_pe[2, 25] ≈ 4126.167301278676 atol = 1e-1
		@test c_pe[end, 25] ≈ 5365.118930294095 atol = 1e-1

		true


	end

end
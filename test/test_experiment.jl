using BattMo
using Test
using GLMakie


@testset "experiment" begin

	@test begin

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")



		cycling_protocol = CyclingProtocol(
			Dict(
				"Protocol" => "Experiment",
				"TotalTime" => 18000000,
				"InitialStateOfCharge" => 0.01,
				"Experiment" =>
					[
						"Rest for 1 hour",
						"Charge at 0.5 W for 800 s",
						"Charge at 0.5 C until 4.0 V",
						"Hold at 4.0 V until 1-e4 A/s",
						"Discharge at 1 A until 3.0 V",
						"Rest until 1e-4 V/s",
						"Charge at 1/20 C for 30 minutes",
					],
			),
		)

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)

		time_series = output.time_series

		Voltage = time_series["Voltage"]
		Current = time_series["Current"]


		@test length(Current) ≈ 464 atol = 0
		@test Voltage[5] ≈ 2.6952925314125666 atol = 1e-1
		@test Voltage[100] ≈ 3.3778613498753916 atol = 1e-1
		@test Voltage[300] ≈ 3.562169483882482 atol = 1e-1
		@test Voltage[400] ≈ 3.2650296286127776 atol = 1e-1
		@test Voltage[end-5] ≈ 3.1855346007007763 atol = 1e-1

		@test Current[5] ≈ 0.0 atol = 1e-1
		@test Current[100] ≈ -2.545210901747287 atol = 1e-1
		@test Current[300] ≈ 1.0 atol = 1e-1
		@test Current[400] ≈ 1.0 atol = 1e-4
		@test Current[end-5] ≈ -0.25452109017472874 atol = 0


		cycling_protocol2 = CyclingProtocol(
			Dict(
				"Protocol" => "Experiment",
				"TotalTime" => 18000000,
				"InitialStateOfCharge" => 0.01,
				"Experiment" =>
					[
						"Rest for 1 hour",
						[
							"Charge at 0.5 C until 4.0 V",
							"Hold at 4.0 V until 0.1 mA/s",
							"Discharge at 1/2 C until 3.0 V",
							"Rest until 1e-4 V/s",
							"Rest for 1 hour",
							"Charge at 0.5 C until 4.0 V",
							"Increase cycle count",
							"Repeat 1 times",
						],
						"Rest for 1 hour",
						"Repeat 1 times",
					],
			),
		)

		sim2 = Simulation(model_setup, cell_parameters, cycling_protocol2)

		output2 = solve(sim2)

		plot_dashboard(output2)

		time_series2 = output2.time_series

		Voltage2 = time_series2["Voltage"]
		Current2 = time_series2["Current"]


		@test length(Current2) ≈ 1203 atol = 0
		@test Voltage2[5] ≈ 2.6952925314125666 atol = 1e-1
		@test Voltage2[100] ≈ 3.571426080043763 atol = 1e-1
		@test Voltage2[300] ≈ 3.5423111082816585 atol = 1e-1
		@test Voltage2[500] ≈ 4.0 atol = 1e-1
		@test Voltage2[end-5] ≈ 3.0841146223690035 atol = 1e-1

		@test Current2[5] ≈ 0.0 atol = 1e-1
		@test Current2[100] ≈ -2.545210901747287 atol = 1e-1
		@test Current2[300] ≈ 2.545210901747287 atol = 1e-1
		@test Current2[500] ≈ -0.3782046805536095 atol = 1e-4
		@test Current2[end-5] ≈ 2.545210901747287 atol = 0



		true

	end

end

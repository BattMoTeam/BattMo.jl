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
				"Capacity" => 5,
				"Experiment" =>
					[
						"Rest for 1 hour",
						"Charge at 5 W for 4 hour or until 3.5 V",
						"Charge at 0.5 C until 4.0 V or until 1 hour",
						"Hold at 4.0 V until 1e-4 A/s",
						"Discharge at 1 A until 3.4 V",
						"Discharge at 2 W until 3.0 V",
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


		@test length(Current) ≈ 642 atol = 0
		@test Voltage[5] ≈ 2.6952925314125666 atol = 1e-1
		@test Voltage[100] ≈ 3.3778613498753916 atol = 1e-1
		@test Voltage[200] ≈ 4.0 atol = 1e-1
		@test Voltage[end-5] ≈ 3.167685446226638 atol = 1e-1

		@test Current[5] ≈ 0.0 atol = 1e-1
		@test Current[100] ≈ -1.472183853800583 atol = 1e-1
		@test Current[200] ≈ -1.5446054588210443 atol = 1e-1
		@test Current[end-5] ≈ -0.25 atol = 1e-1


		cycling_protocol_2 = CyclingProtocol(
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
							"Rest until 1e-4 V/s or until 100 s",
							"Increase cycle count",
							"Repeat 1 times",
						],
						"Rest for 1 hour",
						"Repeat 1 times",
					],
			),
		)

		sim_2 = Simulation(model_setup, cell_parameters, cycling_protocol_2)

		output_2 = solve(sim_2)

		time_series_2 = output_2.time_series

		voltage_2 = time_series_2["Voltage"]
		current_2 = time_series_2["Current"]
		cycle_count_2 = time_series_2["CycleCount"]
		step_index_2 = time_series_2["StepIndex"]



		@test length(current_2) ≈ 1436 atol = 0
		@test voltage_2[5] ≈ 2.6952925314125666 atol = 1e-1
		@test voltage_2[100] ≈ 3.571426080043763 atol = 1e-1
		@test voltage_2[300] ≈ 3.5423111082816585 atol = 1e-1
		@test voltage_2[500] ≈ 4.0 atol = 1e-1
		@test voltage_2[end-5] ≈ 3.0841146223690035 atol = 1e-1

		@test current_2[5] ≈ 0.0 atol = 1e-1
		@test current_2[100] ≈ -2.545210901747287 atol = 1e-1
		@test current_2[300] ≈ 2.545210901747287 atol = 1e-1
		@test current_2[500] ≈ -0.4651948979796583 atol = 1e-4
		@test current_2[end-5] ≈ 0.0 atol = 0

		@test cycle_count_2[5] ≈ 0.0 atol = 0
		@test cycle_count_2[100] ≈ 0.0 atol = 0
		@test cycle_count_2[300] ≈ 0.0 atol = 0
		@test cycle_count_2[500] ≈ 1.0 atol = 0
		@test cycle_count_2[900] ≈ 2.0 atol = 0
		@test cycle_count_2[end-5] ≈ 4.0 atol = 0

		@test step_index_2[5] ≈ 0.0 atol = 0
		@test step_index_2[100] ≈ 1.0 atol = 0
		@test step_index_2[300] ≈ 3.0 atol = 0
		@test step_index_2[500] ≈ 1.0 atol = 0
		@test step_index_2[end-5] ≈ 0.0 atol = 0



		true

	end

end

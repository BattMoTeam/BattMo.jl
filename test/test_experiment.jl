using BattMo
using Test


@testset "experiment" begin

	@test begin

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "experiment")

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)

		time_series = output.time_series

		Voltage = time_series["Voltage"]
		Current = time_series["Current"]


		@test length(Current) ≈ 919 atol = 0
		@test Voltage[5] ≈ 2.986094567048373 atol = 1e-1
		@test Voltage[100] ≈ 3.571426080043763 atol = 1e-1
		@test Voltage[300] ≈ 4.0 atol = 1e-1
		@test Voltage[500] ≈ 4.0 atol = 1e-1
		@test Voltage[end-5] ≈ 3.084316830075682 atol = 1e-1

		@test Current[5] ≈ -1.0 atol = 1e-1
		@test Current[100] ≈ -1.0 atol = 1e-1
		@test Current[300] ≈ -0.5407636994899332 atol = 1e-1
		@test Current[500] ≈ -0.0004673497652231279 atol = 1e-4
		@test Current[end-5] ≈ 0.0 atol = 0


		true

	end

end
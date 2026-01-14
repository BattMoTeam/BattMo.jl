using BattMo
using Test


@testset "capacity calculation" begin

	@test begin

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)

		cumulative_capacity = output.time_series["CumulativeCapacity"]
		net_capacity = output.time_series["NetCapacity"]
		discharge_capacity = output.metrics["DischargeCapacity"]
		charge_capacity = output.metrics["ChargeCapacity"]

		@test length(cumulative_capacity) ≈ 785 atol = 1
		@test length(net_capacity) ≈ 785 atol = 1
		@test cumulative_capacity[5] ≈ 0.2828012113052541 atol = 1e-1
		@test cumulative_capacity[end-5] ≈ 23.041417830290328 atol = 1e-1
		@test net_capacity[5] ≈ 0.2828012113052541 atol = 1e-1
		@test net_capacity[end-5] ≈ 0.5587215315225628 atol = 1e-1

		@test length(discharge_capacity) ≈ 3 atol = 1
		@test length(charge_capacity) ≈ 3 atol = 1
		@test discharge_capacity[1] ≈ 3.6764157469683036 atol = 1e-1
		@test discharge_capacity[2] ≈ 3.6764157469683036 atol = 1e-1
		@test charge_capacity[1] ≈ 4.237077101465274 atol = 1e-1
		@test charge_capacity[2] ≈ 3.6936471729205147 atol = 1e-1


		true

	end

end

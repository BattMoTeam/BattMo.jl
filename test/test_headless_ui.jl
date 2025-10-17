using BattMo
using Test

@testset "headless UI" begin

	@test begin

		simulation_input = load_full_simulation_input(; from_default_set = "chen_2020")

		output = run_simulation(simulation_input; info_level = -1)


		true

	end

end

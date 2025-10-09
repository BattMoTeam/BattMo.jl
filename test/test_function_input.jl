using BattMo

@testset "function_input" begin

	@test begin
		include("../examples/example_functions/current_function.jl")
		model_setup = LithiumIonBattery()
		cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
		simulation_settings = load_simulation_settings(; from_default_set = "P2D")
		simulation_settings["TimeStepDuration"] = 1


		cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")

		cycling_protocol["TotalTime"] = 1800

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

		output = solve(sim)

		true
	end

end

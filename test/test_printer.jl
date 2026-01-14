using BattMo
using Test

@testset "printer" begin

	@test begin

		############################
		# cc_discharge

		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)
		output = solve(sim)

		full_input = load_full_simulation_input(from_default_set = "chen_2020")
		quick_cell_check(cell_parameters)
		print_default_input_sets()
		print_submodels()
		print_info("GridPoints")
		print_info("Concentration")
		print_info("Potential"; view = "OutputVariable")
		print_info(full_input)
		print_info(cell_parameters)
		print_info(cell_parameters; view = "Electrolyte")
		print_info(cell_parameters; view = "Electrode")
		print_info(output)
		true
	end

end





using BattMo
using Test

@testset "printer" begin

	@test begin

		############################
		# CCDischarge

		cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
		cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)
		output = solve(sim)

		print_cell_info(cell_parameters)
		print_default_input_sets_info()
		print_submodels_info()
		print_setting_info("GridPoints")
		print_parameter_info("Concentration")
		print_overview(output)
		print_output_variable_info("Potential")

		true

	end

end

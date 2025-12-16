using BattMo
using Test
using GLMakie

@testset "current function" begin

	@test begin
		include("../examples/example_functions/current_function.jl")
		model_setup = LithiumIonBattery()
		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
		simulation_settings = load_simulation_settings(; from_default_set = "p2d")
		simulation_settings["TimeStepDuration"] = 1


		cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")

		cycling_protocol["TotalTime"] = 1800

		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

		output = solve(sim)
		plot_dashboard(output)
		true
	end

end


@testset "cell functions" begin

	@test begin
		include("./data/julia_files/function_parameters_Xu2015.jl")
		model_setup = LithiumIonBattery()
		cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")

		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"]["FunctionName"] = "open_circuit_potential_graphite_Xu_2015_test"
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"]["FunctionName"] = "open_circuit_potential_lfp_Xu_2015_test"
		cell_parameters["Electrolyte"]["IonicConductivity"] = Dict("FunctionName" => "electrolyte_conductivity_Xu_2015_test")
		cell_parameters["Electrolyte"]["DiffusionCoefficient"] = Dict("FunctionName" => "electrolyte_diffusivity_Xu_2015_test")


		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)

		model_settings = load_model_settings(; from_default_set = "p2d")
		model_settings["ButlerVolmer"] = "Chayambuka"
		model_setup = SodiumIonBattery(; model_settings)
		cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")

		file_path = "../../../../test/data/julia_files/function_parameters_chayambuka_2022.jl"
		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"]["FunctionName"] = "calc_ne_D_test"
		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"]["FilePath"] = file_path
		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]["FunctionName"] = "calc_ne_k_test"
		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]["FilePath"] = file_path
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"]["FunctionName"] = "calc_pe_D_test"
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"]["FilePath"] = file_path
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"]["FunctionName"] = "calc_pe_k_test"
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"]["FilePath"] = file_path

		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)

		true
	end

end


@testset "cell string expressions" begin

	@test begin

		model_setup = LithiumIonBattery()
		cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

		cell_parameters["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = "1.9793 * exp(-39.3631*(c/cmax)) + 0.2482 - 0.0909 * tanh(29.8538*((c/cmax) - 0.1234)) - 0.04478 * tanh(14.9159*((c/cmax) - 0.2769)) - 0.0205 * tanh(30.4444*((c/cmax) - 0.6103))"
		cell_parameters["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = "-0.8090 * (c/cmax) + 4.4875 - 0.0428 * tanh(18.5138*((c/cmax) - 0.5542)) - 17.7326 * tanh(15.7890*((c/cmax) - 0.3117)) + 17.5842 * tanh(15.9308*((c/cmax) - 0.3120))"
		cell_parameters["Electrolyte"]["IonicConductivity"] = "0.1297*(c/1000)^3 - 2.51*(c/1000)^(1.5) + 3.329*(c/1000)"
		cell_parameters["Electrolyte"]["DiffusionCoefficient"] = "8.794*10^(-11)*(c/1000)^2 - 3.972*10^(-10)*(c/1000) + 4.862*10^(-10)"


		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output = solve(sim)


		true
	end

end

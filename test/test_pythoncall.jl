using BattMo
using PythonCall
using Test
using Jutul

include("./data/julia_files/function_parameters_Xu2015.jl")

@testset "pythoncall" begin

	@test begin

		# Add folder to Python path
		pyimport("sys").path.append(joinpath(pwd(), "data", "python_files"))

		# Import module with python input functions
		func = pyimport("function_parameters_Xu2015")

		# Import the python functions to Main space
		@eval Main electrolyte_conductivity_Xu_2015 = $func.electrolyte_conductivity_Xu_2015
		@eval Main electrolyte_diffusivity_Xu_2015 = $func.electrolyte_diffusivity_Xu_2015

		cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
		cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

		cell_parameters["Electrolyte"]["IonicConductivity"] = Dict("FunctionName" => "electrolyte_conductivity_Xu_2015")
		cell_parameters["Electrolyte"]["DiffusionCoefficient"] = Dict("FunctionName" => "electrolyte_diffusivity_Xu_2015")

		model_setup = LithiumIonBattery()
		sim = Simulation(model_setup, cell_parameters, cycling_protocol)
		output = solve(sim)
		true

	end

end


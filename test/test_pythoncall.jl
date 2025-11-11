using BattMo
using PythonCall
using Test
using Jutul

@testset "pythoncall" begin

	@test begin

		# Add folder to Python path
		pyimport("sys").path.append(joinpath(dirname(@__FILE__), "data", "python_files"))

		# Import module with python input functions
		mod = pyimport("function_parameters_xu_2015")

		electrolyte_conductivity_Xu_2015_py = mod.electrolyte_conductivity_Xu_2015_py
		electrolyte_diffusivity_Xu_2015_py = mod.electrolyte_diffusivity_Xu_2015_py

		@eval Main electrolyte_conductivity_Xu_2015_py = $electrolyte_conductivity_Xu_2015_py
		@eval Main electrolyte_diffusivity_Xu_2015_py = $electrolyte_diffusivity_Xu_2015_py


		cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
		cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

		cell_parameters["Electrolyte"]["IonicConductivity"] = Dict("FunctionName" => "electrolyte_conductivity_Xu_2015_py")
		cell_parameters["Electrolyte"]["DiffusionCoefficient"] = Dict("FunctionName" => "electrolyte_diffusivity_Xu_2015_py")

		model_setup = LithiumIonBattery()
		sim = Simulation(model_setup, cell_parameters, cycling_protocol)
		output = solve(sim)
		true

	end

end


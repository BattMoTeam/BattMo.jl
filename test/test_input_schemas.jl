using BattMo
using Test

@testset "input_schemas" begin

	@test begin

		model_settings = load_model_settings(; from_default_set = "P2D")

		model_setup = LithiumIonBattery(; model_settings)

		empty_cell_parameters = load_cell_parameters(; from_model_template = model_setup)

		if haskey(empty_cell_parameters["Cell"], "ElectrodeWidth")
			error("The empty set should not have the parameter ElectrodeWidth.")
		end

		model_settings["SEIModel"] = "Bolay"

		model_setup = LithiumIonBattery(; model_settings)

		empty_cell_parameters = load_cell_parameters(; from_model_template = model_setup)

		if !haskey(empty_cell_parameters["NegativeElectrode"], "Interphase")
			error("The empty set should have the key Interphase.")
		end

		empty_simulation_settings = load_simulation_settings(; from_model_template = model_setup)

		if haskey(empty_simulation_settings["GridPoints"], "NegativeElectrodeCurrentCollector")
			error("The empty set should not have the key NegativeElectrodeCurrentCollector.")
		end

		if !haskey(empty_simulation_settings, "RampUpTime")
			error("The empty set should have the key RampUpTime.")
		end

		pop!(model_settings, "RampUp")
		@info model_settings
		model_setup = LithiumIonBattery(; model_settings)

		empty_simulation_settings = load_simulation_settings(; from_model_template = model_setup)
		@info empty_simulation_settings
		if haskey(empty_simulation_settings, "RampUpTime")
			error("The empty set should not have the key RampUpTime.")
		end

		model_settings = load_model_settings(; from_default_set = "P4D_pouch")

		model_setup = LithiumIonBattery(; model_settings)

		empty_cell_parameters = load_cell_parameters(; from_model_template = model_setup)

		if !haskey(empty_cell_parameters["Cell"], "ElectrodeWidth")
			error("The empty set should have the parameter ElectrodeWidth.")
		end

		if !haskey(empty_cell_parameters["NegativeElectrode"], "CurrentCollector")
			error("The empty set should have the key CurrentCollector.")
		end

		model_setup = LithiumIonBattery(; model_settings)

		empty_simulation_settings = load_simulation_settings(; from_model_template = model_setup)

		if !haskey(empty_simulation_settings["GridPoints"], "NegativeElectrodeCurrentCollector")
			error("The empty set should have the key NegativeElectrodeCurrentCollector.")
		end

		true

	end

end

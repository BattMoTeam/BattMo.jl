export LithiumIonBattery
export print_required_cell_parameters, get_lithium_ion_default_model_settings


"""
	struct LithiumIonBattery <: BatteryModelSetup

Represents a lithium-ion battery model based on the Doyle-Fuller-Newman approach.

# Fields
- `name ::String` : A descriptive name for the model.
- `model_settings ::ModelSettings` : Settings specific to the model.

# Constructor
	LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))

Creates an instance of `LithiumIonBattery` with the specified or default model settings.
The model name is automatically generated based on the model geometry.
"""
struct LithiumIonBattery <: BatteryModelSetup
	name::String
	model_settings::ModelSettings
	is_valid::Bool


	function LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))

		model_geometry = model_settings["ModelGeometry"]
		name = "$model_geometry Doyle-Fuller-Newman lithium-ion model"

		is_valid = validate_parameter_set(model_settings)


		return new{}(
			name,
			model_settings,
			is_valid,
		)
	end
end

function print_required_cell_parameters(::LithiumIonBattery)

	required_cell_parameters = [
		("CoatingThickness", "m", "Real"),
		("OCV", "V", "Function"),
	]

	println("┌──────────────────┬───────────┬───────────┐")
	println("│ Parameter Name   │ Unit      │ Type      │")
	println("├──────────────────┼───────────┼───────────┤")
	for (name, unit, type) in required_cell_parameters
		println("│ " * lpad(name, 16) * " │ " * lpad(unit, 9) * " │ " * lpad(type, 9) * " │")
	end
	println("└──────────────────┴───────────┴───────────┘")

end

function get_default_model_settings(::Type{LithiumIonBattery})
	settings = load_model_settings(; from_default_set = "P2D")
	return settings
end


function get_default_simulation_settings(st::LithiumIonBattery)

	settings = Dict(
		"GridPoints" => Dict(
			"ElectrodeWidth" => 10,
			"ElectrodeLength" => 10,
			"PositiveElectrodeCoating" => 3,
			"PositiveElectrodeActiveMaterial" => 10,
			"PositiveElectrodeCurrentCollector" => 2,
			"PositiveElectrodeCurrentCollectorTabWidth" => 3,
			"PositiveElectrodeCurrentCollectorTabLength" => 3,
			"NegativeElectrodeCoating" => 3,
			"NegativeElectrodeActiveMaterial" => 10,
			"NegativeElectrodeCurrentCollector" => 2,
			"NegativeElectrodeCurrentCollectorTabWidth" => 3,
			"NegativeElectrodeCurrentCollectorTabLength" => 3,
			"Separator" => 3,
		),
		"Grid" => [],
		"TimeStepDuration" => 50,
		"RampUpTime" => 10,
		"RampUpSteps" => 5,
	)
	return SimulationSettings(settings)

end

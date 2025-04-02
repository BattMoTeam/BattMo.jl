export LithiumIonBatteryModel
export print_required_cell_parameters, get_lithium_ion_default_model_settings

struct LithiumIonBatteryModel <: BatteryModel
	name::String
	model_settings::ModelSettings


	function LithiumIonBatteryModel(; model_settings = get_default_model_settings(LithiumIonBatteryModel))

		model_geometry = model_settings.dict["ModelGeometry"]
		name = "$model_geometry Doyle-Fuller-Newman lithium-ion model"


		return new{}(
			name,
			model_settings,
		)
	end
end

function print_required_cell_parameters(::LithiumIonBatteryModel)

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

function get_default_model_settings(::Type{LithiumIonBatteryModel})
	settings = Dict(
		"ModelGeometry" => "1D",
		"UseThermalModel" => false,
		"UseCurrentCollectors" => false,
		"UseSEIModel" => false,
		"GridPointsPositiveElectrode" => 10,
		"GridPointsPositiveElectrodeActiveMaterial" => 10,
		"GridPointsNegativeElectrode" => 10,
		"GridPointsNegativeElectrodeActiveMaterial" => 10,
		"GridPointsSeparator" => 10,
		"Grid" => [],
		"TimeStepDuration" => 50,
		"UseRampUp" => true,
		"RampUpSteps" => 5,
	)
	return ModelSettings(settings)
end


function get_default_simulation_settings(st::LithiumIonBatteryModel)

	settings = Dict(
		"Grid" => [],
		"TimeStepDuration" => 50,
		"RampUpSteps" => 5,
		"RampUpTime" => 10,
		"GridPoints" => Dict(
			"ElectrodeWidth" => 5,
			"ElectrodeLength" => 5,
			"PositiveElectrodeCoating" => 10,
			"PositiveElectrodeActiveMaterial" => 10,
			"PositiveElectrodeCurrentCollector" => 10,
			"PositiveElectrodeCurrentCollectorTabWidth" => 10,
			"PositiveElectrodeCurrentCollectorTabLength" => 10,
			"NegativeElectrodeCoating" => 10,
			"NegativeElectrodeActiveMaterial" => 10,
			"NegativeElectrodeCurrentCollector" => 10,
			"NegativeElectrodeCurrentCollectorTabWidth" => 10,
			"NegativeElectrodeCurrentCollectorTabLength" => 10,
			"Separator" => 10,
		),
	)
	return SimulationSettings(settings)

end

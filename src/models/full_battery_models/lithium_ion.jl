export LithiumIon
export print_required_cell_parameters, get_lithium_ion_default_model_settings

struct LithiumIon <: BatteryModel
	name::String
	model_settings::ModelSettings


	function LithiumIon(; model_settings = get_lithium_ion_default_model_settings())

		model_geometry = model_settings.dict["ModelGeometry"]
		name = "$model_geometry Doyle-Fuller-Newman lithium-ion model"


		return new{}(
			name,
			model_settings,
		)
	end
end

function print_required_cell_parameters(::LithiumIon)

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

function get_lithium_ion_default_model_settings()
	settings = Dict(
		"ModelGeometry" => "1D",
		"UseThermalModel" => false,
		"UseCurrentCollectors" => false,
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


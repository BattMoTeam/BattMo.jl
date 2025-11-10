export LithiumIonBattery
export print_required_cell_parameters, get_lithium_ion_default_model_settings
export run_battery
export setup_model!


"""
	struct LithiumIonBattery <: Battery

Represents a lithium-ion battery model based on the Doyle-Fuller-Newman approach.

# Fields
- `name ::String` : A descriptive name for the model.
- `model_settings ::ModelSettings` : Settings specific to the model.

# Constructor
	LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))

Creates an instance of `LithiumIonBattery` with the specified or default model settings.
The model name is automatically generated based on the model geometry.
"""
mutable struct LithiumIonBattery <: IntercalationBattery
	name::String
	settings::ModelSettings
	is_valid::Bool
	multimodel::Union{Missing, MultiModel}


	function LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))

		model_geometry = model_settings["ModelFramework"]
		name = "Setup object for a $model_geometry lithium-ion model"

		is_valid = validate_parameter_set(model_settings)


		return new{}(
			name,
			model_settings,
			is_valid,
		)
	end
end

function get_default_model_settings(::Type{LithiumIonBattery})
	settings = load_model_settings(; from_default_set = "p2d")
	return settings
end

function get_default_solver_settings(model::LithiumIonBattery)
	settings = load_solver_settings(; from_default_set = "direct")
	return settings
end

function get_default_simulation_settings(model::LithiumIonBattery)

	model_framework = model.settings["ModelFramework"]
	if model_framework == "P2D"
		settings = load_simulation_settings(; from_default_set = "p2d")
	elseif model_framework == "P4D Pouch"
		settings = load_simulation_settings(; from_default_set = "p4d_pouch")
	elseif model_framework == "P4D Cylindrical"
		settings = load_simulation_settings(; from_default_set = "p4d_cylindrical")
	else
		error("ModelFramework $model_famework not recognized")
	end

	return settings

end


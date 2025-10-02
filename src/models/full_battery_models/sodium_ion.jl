export SodiumIonBattery



"""
	struct SodiumIonBattery <: Battery

Represents a lithium-ion battery model based on the Doyle-Fuller-Newman approach.

# Fields
- `name ::String` : A descriptive name for the model.
- `model_settings ::ModelSettings` : Settings specific to the model.

# Constructor
	SodiumIonBattery(; model_settings = get_default_model_settings(SodiumIonBattery))

Creates an instance of `SodiumIonBattery` with the specified or default model settings.
The model name is automatically generated based on the model geometry.
"""
mutable struct SodiumIonBattery <: IntercalationBattery
	name::String
	settings::ModelSettings
	is_valid::Bool
	multimodel::Union{Missing, MultiModel}


	function SodiumIonBattery(; model_settings = get_default_model_settings(SodiumIonBattery))

		is_valid = validate_parameter_set(model_settings)

		model_geometry = model_settings["ModelFramework"]
		name = "Setup object for a $model_geometry lithium-ion model"




		return new{}(
			name,
			model_settings,
			is_valid,
		)
	end
end

function get_default_model_settings(::Type{SodiumIonBattery})
	settings = load_model_settings(; from_default_set = "P2D")
	return settings
end

function get_default_solver_settings(model::SodiumIonBattery)
	settings = load_solver_settings(; from_default_set = "direct")
	return settings
end

function get_default_simulation_settings(model::SodiumIonBattery)

	model_framework = model.settings["ModelFramework"]
	if model_framework == "P2D"
		settings = load_simulation_settings(; from_default_set = "P2D_fine_resolution")
	elseif model_framework == "P4D Pouch"
		settings = load_simulation_settings(; from_default_set = "P4D_pouch")
	elseif model_framework == "P4D Cylindrical"
		settings = load_simulation_settings(; from_default_set = "P4D_cylindrical")
	else
		error("ModelFramework $model_famework not recognized")
	end

	return settings

end

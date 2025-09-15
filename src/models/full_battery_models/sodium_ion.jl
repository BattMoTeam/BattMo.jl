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

function get_default_solver_settings(::Type{SodiumIonBattery})
	settings = load_solver_settings(; from_default_set = "Direct")
	return settings
end

function get_default_simulation_settings(st::SodiumIonBattery)

	settings = Dict(
		"GridResolutionElectrodeWidth" => 10,
		"GridResolutionElectrodeLength" => 10,
		"GridResolutionPositiveElectrodeCoating" => 20,
		"GridResolutionPositiveElectrodeParticle" => 30,
		"GridResolutionPositiveElectrodeCurrentCollector" => 2,
		"GridResolutionPositiveElectrodeCurrentCollectorTabWidth" => 3,
		"GridResolutionPositiveElectrodeCurrentCollectorTabLength" => 3,
		"GridResolutionNegativeElectrodeCoating" => 10,
		"GridResolutionNegativeElectrodeParticle" => 30,
		"GridResolutionNegativeElectrodeCurrentCollector" => 2,
		"GridResolutionNegativeElectrodeCurrentCollectorTabWidth" => 3,
		"GridResolutionNegativeElectrodeCurrentCollectorTabLength" => 3,
		"GridResolutionSeparator" => 3, "Grid" => [],
		"TimeStepDuration" => 50,
		"RampUpTime" => 10,
		"RampUpSteps" => 5,
	)
	return SimulationSettings(settings; source_path = nothing)

end

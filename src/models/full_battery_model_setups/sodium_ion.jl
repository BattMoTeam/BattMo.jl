export SodiumIonBattery


mutable struct SodiumIonBattery <: BatteryModel
	name::String
	settings::ModelSettings
	is_valid::Bool
	multimodel::Union{Missing, MultiModel}


	function SodiumIonBattery(; model_settings = get_default_model_settings(SodiumIonBattery))

		model_geometry = model_settings["ModelFramework"]
		name = "Setup object for a $model_geometry sodium-ion model"

		# is_valid = validate_parameter_set(model_settings)
		is_valid = true


		return new{}(
			name,
			model_settings,
			is_valid,
		)
	end
end


function print_required_cell_parameters(::SodiumIonBattery)

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

function get_default_model_settings(::Type{SodiumIonBattery})
	settings = load_model_settings(; from_default_set = "P2D")
	return settings
end


function get_default_simulation_settings(st::SodiumIonBattery)

	settings = Dict(
		"GridResolution" => Dict(
			"ElectrodeWidth" => 10,
			"ElectrodeLength" => 10,
			"PositiveElectrodeCoating" => 10,
			"PositiveElectrodeActiveMaterial" => 5,
			"PositiveElectrodeCurrentCollector" => 2,
			"PositiveElectrodeCurrentCollectorTabWidth" => 3,
			"PositiveElectrodeCurrentCollectorTabLength" => 3,
			"NegativeElectrodeCoating" => 10,
			"NegativeElectrodeActiveMaterial" => 5,
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
	return SimulationSettings(settings; source_path = nothing)

end


function setup_model(model::SodiumIonBattery, input, grids, couplings; kwargs...)
	return _setup_model(model, input, grids, couplings; kwargs...)
end

function setup_submodels(model::SodiumIonBattery, input, grids, couplings; kwargs...)
	return _setup_submodels(model, input, grids, couplings; kwargs...)
end

function setup_multimodel(model::SodiumIonBattery, submodels, input)
	return _setup_multimodel(model, submodels, input)
end

function setup_volume_fractions!(model::SodiumIonBattery, grids, coupling)
	_setup_volume_fractions!(model, grids, coupling)
end

function setup_electrolyte(model::SodiumIonBattery, input, grids)
	return _setup_electrolyte(model, input, grids)
end

function setup_ne_current_collector(model::SodiumIonBattery, input, grids, couplings)
	return _setup_ne_current_collector(model, input, grids, couplings)
end

function setup_pe_current_collector(model::SodiumIonBattery, input, grids, couplings)
	return _setup_pe_current_collector(model, input, grids, couplings)
end

function setup_active_material(model::SodiumIonBattery, name::Symbol, input, grids, couplings)
	return _setup_active_material(model, name, input, grids, couplings)

end

function set_parameters(model::SodiumIonBattery, input)
	return _set_parameters(model, input)
end

function setup_coupling_cross_terms!(model::SodiumIonBattery, parameters, couplings)
	return _setup_coupling_cross_terms!(model, parameters, couplings)
end

function setup_initial_state(input, model::SodiumIonBattery)
	return _setup_initial_state(input, model)
end
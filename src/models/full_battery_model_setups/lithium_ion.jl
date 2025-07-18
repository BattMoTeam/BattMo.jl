export LithiumIonBattery
export print_required_cell_parameters, get_lithium_ion_default_model_settings
export run_battery
export setup_model


"""
	struct LithiumIonBattery <: ModelConfigured

Represents a lithium-ion battery model based on the Doyle-Fuller-Newman approach.

# Fields
- `name ::String` : A descriptive name for the model.
- `model_settings ::ModelSettings` : Settings specific to the model.

# Constructor
	LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))

Creates an instance of `LithiumIonBattery` with the specified or default model settings.
The model name is automatically generated based on the model geometry.
"""
mutable struct LithiumIonBattery <: BatteryModel
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


function setup_model(model::LithiumIonBattery, input, grids, couplings; kwargs...)
	return _setup_model(model, input, grids, couplings; kwargs...)
end

function setup_submodels(model::LithiumIonBattery, input, grids, couplings; kwargs...)
	return _setup_submodels(model, input, grids, couplings; kwargs...)
end

function setup_multimodel(model::LithiumIonBattery, submodels, input)
	return _setup_multimodel(model, submodels, input)
end

function setup_volume_fractions!(model::LithiumIonBattery, grids, coupling)
	_setup_volume_fractions!(model, grids, coupling)
end

function setup_electrolyte(model::LithiumIonBattery, input, grids)
	return _setup_electrolyte(model, input, grids)
end

function setup_ne_current_collector(model::LithiumIonBattery, input, grids, couplings)
	return _setup_ne_current_collector(model, input, grids, couplings)
end

function setup_pe_current_collector(model::LithiumIonBattery, input, grids, couplings)
	return _setup_pe_current_collector(model, input, grids, couplings)
end

function compute_volume_fraction(codict)
	# We compute the volume fraction form the coating data

	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductiveAdditive"

	compnames = [am, bd, ad]

	# Do it this way since values could be AD.
	get_specific_volume(compname) = codict[compname]["MassFraction"] / codict[compname]["Density"]
	specificVolumes = map(get_specific_volume, compnames)

	sumSpecificVolumes = sum(specificVolumes)
	volumeFractions = [sv / sumSpecificVolumes for sv in specificVolumes]

	effectiveDensity = codict["ElectrodeCoating"]["EffectiveDensity"]
	volumeFraction = sumSpecificVolumes * effectiveDensity

	return volumeFraction, volumeFractions, effectiveDensity

end

"""
	Helper function to setup the active materials
	"""
function setup_active_material(model::LithiumIonBattery, name::Symbol, input, grids, couplings)
	return _setup_active_material(model, name, input, grids, couplings)
end

function compute_effective_conductivity(comodel, coinputparams)

	# Compute effective conductivity for the coating

	# First we compute the intrinsic conductivity as volume weight average of the subcomponents
	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductiveAdditive"

	compnames = [am, bd, ad]

	vfs = comodel.system.params[:volume_fractions]
	kappa = 0
	for icomp in eachindex(compnames)
		compname = compnames[icomp]
		vf = vfs[icomp]
		kappa += vf * coinputparams[compname]["ElectronicConductivity"]
	end

	vf = comodel.system.params[:volume_fraction]
	bg = coinputparams["ElectrodeCoating"]["BruggemanCoefficient"]

	kappaeff = (vf^bg) * kappa

	return kappaeff

end

function set_parameters(model::LithiumIonBattery, input)
	return _set_parameters(model, input)
end

function setup_coupling_cross_terms!(model::LithiumIonBattery, parameters, couplings)
	return _setup_coupling_cross_terms!(model, parameters, couplings)
end

function setup_initial_state(input, model::LithiumIonBattery)
	return _setup_initial_state(input, model)
end
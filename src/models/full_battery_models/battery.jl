export ModelConfigured


"""
	abstract type ModelConfigured

Abstract type representing a model.
All models should inherit from this type.
"""
abstract type ModelConfigured end

abstract type Battery <: ModelConfigured end


function setup_model(model::M, input, grids, couplings; kwargs...) where {M <: Battery}

	# setup the submodels and also return a coupling structure which is used to setup later the cross-terms
	submodels = setup_submodels(model, input, grids, couplings; kwargs...)

	# Combine sub models into MultiModel
	model = setup_multimodel(model, submodels, input)

	# Compute the volume fractions
	setup_volume_fractions!(model, grids, couplings["Electrolyte"])

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)
	parameters = set_parameters(model, input)

	# setup the cross terms which couples the submodels.
	setup_coupling_cross_terms!(model, parameters, couplings)

	setup_initial_control_policy!(model.multimodel[:Control].system.policy, input, parameters)
	#model.context = DefaultContext()

	output = (model = model,
		parameters = parameters)

	return output

end

#################################################################
# Setup grids and coupling for the given geometrical parameters #
#################################################################

function setup_grids_and_couplings(model::M, input) where {M <: Battery}


	case_type = input.model_settings["ModelFramework"]

	if case_type == "P2D"

		grids, couplings = one_dimensional_grid(input)

	elseif case_type == "P4D Pouch"

		grids, couplings = pouch_grid(input)

	elseif case_type == "P4D Cylindrical"

		grids, couplings = jelly_roll_grid(input)

	else
		error("geometry case type not recognized")

	end

	return grids, couplings

end
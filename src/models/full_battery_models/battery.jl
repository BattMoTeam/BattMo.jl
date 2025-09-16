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

function setup_component(grid::FiniteVolumeMesh,
	sys;
	flow_discretization::String = "GeneralAD",
	dirichletBoundary = nothing,
	kwargs...)

	domain = DataDomain(grid)

	# opertors only use geometry not property
	k = ones(number_of_cells(grid))

	T    = compute_face_trans(domain, k)
	T_hf = compute_half_face_trans(domain, k)
	T_b  = compute_boundary_trans(domain, k)

	domain[:trans, Faces()]           = T
	domain[:halfTrans, HalfFaces()]   = T_hf
	domain[:halftransfaces, Faces()]  = setupHalfTransFaces(domain)
	domain[:bcTrans, BoundaryFaces()] = T_b

	if !isnothing(dirichletBoundary)

		bfaces = dirichletBoundary["boundaryfaces"]
		nb = size(bfaces, 1)
		domain.entities[BoundaryDirichletFaces()] = nb

		bcDirFace = dirichletBoundary["boundaryfaces"] # in BoundaryFaces indexing
		bcDirCell = dirichletBoundary["cells"]

		bcDirInd                                          = Vector{Int64}(1:nb)
		domain[:bcDirHalfTrans, BoundaryDirichletFaces()] = domain[:bcTrans][bcDirFace]
		domain[:bcDirCells, BoundaryDirichletFaces()]     = bcDirCell
		domain[:bcDirInds, BoundaryDirichletFaces()]      = bcDirInd

	end

	if flow_discretization == "GeneralAD"
		flow = PotentialFlow(grid)
	else
		flow = TwoPointPotentialFlowHardCoded(grid)
	end
	disc = (flow = flow,)
	domain = DiscretizedDomain(domain, disc)

	model = SimulationModel(domain, sys; kwargs...)

	return model

end

######################
# Transmissibilities #
######################

function getTrans(model1::Dict{String, <:Any},
	model2::Dict{String, Any},
	faces,
	cells,
	quantity::String)
	""" setup transmissibility for coupling between models at boundaries"""

	T_all1 = model1["G"]["operators"]["T_all"][faces[:, 1]]
	T_all2 = model2["G"]["operators"]["T_all"][faces[:, 2]]


	function getcellvalues(values, cellinds)

		if length(values) == 1
			values = values * ones(length(cellinds))
		else
			values = values[cellinds]
		end
		return values

	end

	s1 = getcellvalues(model1[quantity], cells[:, 1])
	s2 = getcellvalues(model2[quantity], cells[:, 2])

	T = 1.0 ./ ((1.0 ./ (T_all1 .* s1)) + (1.0 ./ (T_all2 .* s2)))

	return T

end

function getTrans(model1::SimulationModel,
	model2::SimulationModel,
	bcfaces,
	bccells,
	parameters1,
	parameters2,
	quantity)
	""" setup transmissibility for coupling between models at boundaries. Intermediate 1d version"""

	d1 = physical_representation(model1)
	d2 = physical_representation(model2)

	bcTrans1 = d1[:bcTrans][bcfaces[:, 1]]
	bcTrans2 = d2[:bcTrans][bcfaces[:, 2]]
	cells1   = bccells[:, 1]
	cells2   = bccells[:, 2]

	s1 = parameters1[quantity][cells1]
	s2 = parameters2[quantity][cells2]

	T = 1.0 ./ ((1.0 ./ (bcTrans1 .* s1)) + (1.0 ./ (bcTrans2 .* s2)))

	return T

end

function getHalfTrans(model::SimulationModel,
	bcfaces,
	bccells,
	parameters,
	quantity)
	""" recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the corresponding given cells. Intermediate 1d version. Note the indexing in BoundaryFaces is used"""

	d       = physical_representation(model)
	bcTrans = d[:bcTrans][bcfaces]
	s       = parameters[quantity][bccells]

	T = bcTrans .* s

	return T
end

function getHalfTrans(model::Dict{String, Any},
	faces,
	cells,
	quantity::String)
	""" recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the given cells.
	Here, the faces should belong the corresponding cells at the same index"""

	T_all = model["G"]["operators"]["T_all"]
	s = model[quantity]
	if length(s) == 1
		s = s * ones(length(cells))
	else
		s = s[cells]
	end

	T = T_all[faces] .* s

	return T

end

function getHalfTrans(model::Dict{String, <:Any},
	faces)
	""" recover the half transmissibilities for boundary faces"""

	T_all = model["G"]["operators"]["T_all"]
	T = T_all[faces]

	return T

end

function include_current_collectors(model)

	if haskey(model.models, :NegativeElectrodeCurrentCollector)
		include_cc = true
		@assert haskey(model.models, :PositiveElectrodeCurrentCollector)
	else
		include_cc = false
		@assert !haskey(model.models, :PositiveElectrodeCurrentCollector)
	end

	return include_cc

end
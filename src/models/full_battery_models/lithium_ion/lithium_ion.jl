#################################################################################
# In this module we define methods to handle the LithiumIon model. This model
# builds on BatteryModel and can be used to setup specific LithiumIon classes.
# 
# File structure:
#
#
#################################################################################

export LithiumIon, setup_grids_and_couplings


# Define the LithiumIon struct
mutable struct LithiumIon{
	A <: SimulationModel,
	C <: SimulationModel,
	E <: SimulationModel,
	D <: Dict{Any, Any}} <: BatteryModel

	negative_electrode_active_material::A
	positive_electrode_active_material::A
	negative_electrode_current_collector::C
	positive_electrode_current_collector::C
	electrolyte::E
	meshes::D
	couplings::D
	model_settings::Any

	# Constructor function
	function LithiumIon(inputparams::InputParams; model_settings = Dict(:discretization_type => "P2D", :include_cc => false), kwargs...)


		meshes, couplings = setup_grids_and_couplings(inputparams, model_settings[:discretization_type])


		negative_electrode_current_collector = setup_negative_electrode_current_collector(inputparams, meshes, couplings; kwargs...)
		positive_electrode_current_collector = setup_positive_electrode_current_collector(inputparams, meshes, couplings; kwargs...)




		negative_electrode_active_material = setup_negative_electrode_active_material(inputparams, meshes, couplings, model_settings)
		positive_electrode_active_material = setup_negative_electrode_active_material(inputparams, meshes, couplings, model_settings)
		electrolyte = setup_electrolyte(inputparams, meshes; kwargs...)


		type_am = typeof(negative_electrode_active_material)
		type_cc = typeof(negative_electrode_current_collector)
		type_elyte = typeof(electrolyte)
		type_mesh = typeof(meshes)

		return new{type_am, type_cc, type_elyte, type_mesh}(
			negative_electrode_active_material,
			positive_electrode_active_material,
			negative_electrode_current_collector,
			positive_electrode_current_collector,
			electrolyte,
			meshes,
			couplings,
			model_settings,
		)
	end
end


# Factory functions to create components
function setup_negative_electrode_active_material(inputparams, mesh, couplings, model_settings)

	model_am = setup_active_material(inputparams.dict, :NegativeElectrode, mesh, couplings, model_settings)

	return model_am

end

function setup_positive_electrode_active_material(inputparams, mesh, couplings, model_settings)
	model_am = setup_active_material(inputparams.dict, :PositiveElectrode, mesh, couplings, model_settings)

	return model_am
end

function setup_negative_electrode_current_collector(inputparams, meshes, couplings; kwargs...)

	model_am = setup_current_collector(inputparams.dict, "NegativeElectrode", meshes, couplings; kwargs...)

	return model_am

end

function setup_positive_electrode_current_collector(inputparams, meshes, couplings; kwargs...)
	model_am = setup_current_collector(inputparams.dict, "PositiveElectrode", meshes, couplings; kwargs...)

	return model_am
end

function setup_electrolyte(inputparams, meshes; kwargs...)
	jsondict = inputparams.dict
	params = JutulStorage()
	inputparams_elyte = jsondict["Electrolyte"]

	params[:transference]        = inputparams_elyte["species"]["transferenceNumber"]
	params[:charge]              = inputparams_elyte["species"]["chargeNumber"]
	params[:separator_porosity]  = jsondict["Separator"]["porosity"]
	params[:bruggeman]           = inputparams_elyte["bruggemanCoefficient"]
	params[:electrolyte_density] = jsondict["Separator"]["porosity"]
	params[:separator_density]   = inputparams_elyte["density"]

	# setup diffusion coefficient function
	if haskey(inputparams_elyte["diffusionCoefficient"], "function")

		exp = setup_diffusivity_evaluation_expression_from_string(inputparams_elyte["diffusionCoefficient"]["function"])
		params[:diffusivity_func] = @RuntimeGeneratedFunction(exp)

	elseif haskey(inputparams_elyte["diffusionCoefficient"], "functionname")

		funcname = inputparams_elyte["diffusionCoefficient"]["functionname"]
		params[:diffusivity_func] = getfield(BattMo, Symbol(funcname))

	else
		data_x = inputparams_elyte["diffusionCoefficient"]["data_x"]
		data_y = inputparams_elyte["diffusionCoefficient"]["data_y"]

		interpolation = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		params[:diffusivity_data] = true
		params[:diffusivity_func] = interpolation

	end

	# setup conductivity function
	if haskey(inputparams_elyte["ionicConductivity"], "function")

		exp = setup_conductivity_evaluation_expression_from_string(inputparams_elyte["ionicConductivity"]["function"])
		params[:conductivity_func] = @RuntimeGeneratedFunction(exp)

	elseif haskey(inputparams_elyte["ionicConductivity"], "functionname")

		funcname = inputparams_elyte["ionicConductivity"]["functionname"]
		params[:conductivity_func] = getfield(BattMo, Symbol(funcname))

	else
		data_x = inputparams_elyte["ionicConductivity"]["data_x"]
		data_y = inputparams_elyte["ionicConductivity"]["data_y"]

		interpolation = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		params[:conductivity_data] = true
		params[:conductivity_func] = interpolation

	end

	elyte = Electrolyte(params)

	model_elyte = setup_component(meshes["Electrolyte"], elyte, general_ad = true; kwargs...)

	return model_elyte
end

function setup_current_collector(jsondict, name, meshes, couplings; kwargs...)


	mesh     = meshes[name]
	coupling = couplings[name]

	boundary = coupling["External"]
	cc_params = JutulStorage()
	cc_params[:density] = jsondict[name]["CurrentCollector"]["density"]

	sys_necc = CurrentCollector(cc_params)
	model_cc = setup_component(mesh,
		sys_necc,
		dirichletBoundary = boundary,
		general_ad = true; kwargs...)

	return model_cc

end


function setup_active_material(jsondict::Dict, name::Symbol, meshes, couplings, model_settings; kwargs...)

	stringName = string(name)
	discretization_type = model_settings[:discretization_type]
	include_cc = model_settings[:include_cc]

	inputparams_am = jsondict[stringName]["Coating"]["ActiveMaterial"]

	am_params                           = JutulStorage()
	vf, vfs, eff_dens                   = compute_volume_fraction(jsondict[stringName]["Coating"])
	am_params[:volume_fraction]         = vf
	am_params[:volume_fractions]        = vfs
	am_params[:effective_density]       = eff_dens
	am_params[:n_charge_carriers]       = inputparams_am["Interface"]["numberOfElectronsTransferred"]
	am_params[:maximum_concentration]   = inputparams_am["Interface"]["saturationConcentration"]
	am_params[:volumetric_surface_area] = inputparams_am["Interface"]["volumetricSurfaceArea"]
	am_params[:theta0]                  = inputparams_am["Interface"]["guestStoichiometry0"]
	am_params[:theta100]                = inputparams_am["Interface"]["guestStoichiometry100"]

	k0  = inputparams_am["Interface"]["reactionRateConstant"]
	Eak = inputparams_am["Interface"]["activationEnergyOfReaction"]

	am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)

	if haskey(inputparams_am["Interface"]["openCircuitPotential"], "function")

		am_params[:ocp_funcexp] = true
		ocp_exp = inputparams_am["Interface"]["openCircuitPotential"]["function"]
		exp = setup_ocp_evaluation_expression_from_string(ocp_exp)
		am_params[:ocp_func] = @RuntimeGeneratedFunction(exp)

	elseif haskey(inputparams_am["Interface"]["openCircuitPotential"], "functionname")

		funcname = inputparams_am["Interface"]["openCircuitPotential"]["functionname"]
		am_params[:ocp_func] = getfield(BattMo, Symbol(funcname))

	else
		am_params[:ocp_funcdata] = true
		data_x = inputparams_am["Interface"]["openCircuitPotential"]["data_x"]
		data_y = inputparams_am["Interface"]["openCircuitPotential"]["data_y"]

		interpolation_object = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		am_params[:ocp_func] = interpolation_object
	end

	if discretization_type == "P2D"
		rp = inputparams_am["SolidDiffusion"]["particleRadius"]
		N  = Int64(inputparams_am["SolidDiffusion"]["N"])
		D  = inputparams_am["SolidDiffusion"]["referenceDiffusionCoefficient"]
		if haskey(inputparams_am, "SEImodel") && inputparams_am["SEImodel"] == "Bolay"
			label = :sei
			fds = ["SEIlengthInitial",
				"SEIvoltageDropRef",
				"SEIlengthRef",
				"SEIstoichiometricCoefficient",
				"SEImolarVolume",
				"SEIelectronicDiffusionCoefficient",
				"SEIintersticialConcentration",
				"SEIionicConductivity"]
			for fd in fds
				am_params[Symbol(fd)] = inputparams_am["Interface"][fd]
			end
		else
			label = nothing
		end
		sys_am = ActiveMaterialP2D(am_params, rp, N, D; label = label)
	elseif discretisation_type == "NoParticleDiffusion"
		sys_am = ActiveMaterialNoParticleDiffusion(am_params)
	else
		error("Discretization type $discretization_type is not handled.")
	end

	mesh = meshes[stringName]
	coupling = couplings[stringName]

	boundary = nothing
	if !include_cc && name == :NeAm
		addDirichlet = true
		boundary = coupling["External"]
	else
		addDirichlet = false
		boundary = nothing
	end

	model_am = setup_component(mesh,
		sys_am;
		general_ad = true,
		dirichletBoundary = boundary,
		kwargs...)

	return model_am

end

#################################################################
# Setup grids and coupling for the given geometrical parameters #
#################################################################

function setup_grids_and_couplings(inputparams::InputParams, discretization_type)

	if discretization_type == "P2D"

		mesh, couplings = one_dimensional_grid(inputparams)

	elseif discretization_type == "P4D"

		mesh, couplings = pouch_grid(inputparams)

	else

		error("geometry case type not recognized")

	end

	return mesh, couplings

end

function setup_component(grid::Jutul.FiniteVolumeMesh,
	sys;
	general_ad::Bool = true,
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

	if general_ad
		flow = PotentialFlow(grid)
	else
		flow = TwoPointPotentialFlowHardCoded(grid)
	end
	disc = (charge_flow = flow,)
	domain = DiscretizedDomain(domain, disc)

	model = SimulationModel(domain, sys; kwargs...)

	return model

end

function compute_volume_fraction(codict)
	# We compute the volume fraction form the coating data

	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductingAdditive"

	compnames = [am, bd, ad]

	specificVolumes = zeros(length(compnames))
	for icomp in eachindex(compnames)
		compname = compnames[icomp]
		rho = codict[compname]["density"]
		mf = codict[compname]["massFraction"]
		specificVolumes[icomp] = mf / rho
	end

	sumSpecificVolumes = sum(specificVolumes)
	volumeFractions = [sv / sumSpecificVolumes for sv in specificVolumes]

	effectiveDensity = codict["effectiveDensity"]
	volumeFraction = sumSpecificVolumes * effectiveDensity

	return volumeFraction, volumeFractions, effectiveDensity

end


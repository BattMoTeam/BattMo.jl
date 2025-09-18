
################################################
# control policy setup (Matlab input specific) #
################################################

function setup_initial_control_policy!(policy::SimpleCVPolicy, inputparams::MatlabInput, parameters)

	Imax = Float64(inputparams["model"]["Control"]["Imax"])
	tup = Float64(inputparams["model"]["Control"]["rampupTime"])

	cFun(time) = currentFun(time, Imax, tup)

	policy.current_function = cFun
	policy.Imax             = Imax
	policy.voltage          = Float64(inputparams["model"]["Control"]["lowerCutoffVoltage"])

end


function setup_initial_control_policy!(policy::CyclingCVPolicy, inputparams::MatlabInput, parameters)

	error("not updated, use inputparams to get values")
	policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
	policy.ImaxCharge    = only(parameters[:Control][:ImaxCharge])

end


######################
# Setup timestepping #
######################

function setup_timesteps(inputparams::MatlabInput;
	max_step::Union{Integer, Nothing} = nothing,
	kwarg...)
	"""
		Method setting up the timesteps from a mat file object. If use_state_ref is true
		the simulation will use the same timesteps as the pre-run matlab simulation.
	"""

	if inputparams["use_state_ref"]

		steps = size(inputparams.all["states"], 1)
		alltimesteps = Vector{Float64}(undef, steps)
		time = 0
		end_step = 0

		#Alternative to minE=3.2
		minE = inputparams["model"]["Control"]["lowerCutoffVoltage"]

		for i ∈ 1:steps
			alltimesteps[i] = inputparams["states"][i]["time"] - time
			time = inputparams["states"][i]["time"]
			E = inputparams["states"][i]["Control"]["E"]
			if (E > minE + 0.001)
				end_step = i
			end
		end
		if !isnothing(max_step)
			end_step = min(max_step, end_step)
		end
		timesteps = alltimesteps[1:end_step]
	else
		timesteps = inputparams["schedule"]["step"]["val"][:]

	end

	return timesteps
end




##################
# Setup coupling #
##################

function setup_coupling_cross_terms!(inputparams::MatlabInput,
	model::MultiModel,
	parameters::Dict{Symbol, <:Any},
	couplings)

	exported_all = inputparams.all

	include_cc = include_current_collectors(model)

	#################################
	# setup coupling NeAm <-> Elyte #
	#################################

	srange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 1]) # negative electrode
	trange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 2]) # electrolyte (negative side)

	if discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	#################################
	# setup coupling Elyte <-> PeAm #
	#################################

	srange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:, 1]) # postive electrode
	trange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:, 2]) # electrolyte (positive side)

	if discretisation_type(model[:PositiveElectrodeActiveMaterial]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeActiveMaterial, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeActiveMaterial, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:PositiveElectrodeActiveMaterial]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	if include_cc

		################################
		# setup coupling NeCc <-> NeAm #
		################################

		srange = Int64.(
			exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 1]
		)
		trange = Int64.(
			exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 2]
		)

		msource = exported_all["model"]["NegativeElectrode"]["CurrentCollector"]
		mtarget = exported_all["model"]["NegativeElectrode"]["Coating"]
		couplingfaces = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingfaces"])
		couplingcells = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"])
		trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "effectiveElectronicConductivity")

		ct = TPFAInterfaceFluxCT(trange, srange, trans)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :NegativeElectrodeCurrentCollector, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange, trange, trans)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeCurrentCollector, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		#######################################
		# setup coupling PeCc <-> PeAm charge #
		#######################################

		target = Dict(
			:model => :PositiveElectrodeActiveMaterial,
			:equation => :charge_conservation,
		)
		source = Dict(
			:model => :PositiveElectrodeCurrentCollector,
			:equation => :charge_conservation,
		)
		srange = Int64.(
			exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingcells"][:, 1]
		)
		trange = Int64.(
			exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingcells"][:, 2]
		)
		msource = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
		ct = exported_all["model"]["PositiveElectrode"]["couplingTerm"]
		couplingfaces = Int64.(ct["couplingfaces"])
		couplingcells = Int64.(ct["couplingcells"])
		trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "effectiveElectronicConductivity")

		ct = TPFAInterfaceFluxCT(trange, srange, trans)
		ct_pair = setup_cross_term(ct, target = :PositiveElectro:PositiveElectrodeCurrentCollectoriveMaterial, source = :PositiveElectrodeCurrentCollector, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange, trange, trans)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeCurrentCollector, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

	end

	if include_cc

		##########################################
		# setup coupling PeCc <-> Control charge #
		##########################################

		trange = convert_to_int_vector(
			exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["externalCouplingTerm"]["couplingcells"],
		)
		srange = Int64.(ones(size(trange)))
		msource = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
		couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
		couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"])

		component = :PositiveElectrodeCurrentCollector

	else

		##########################################
		# setup coupling PeAm <-> Control charge #
		##########################################

		trange = convert_to_int_vector(
			exported_all["model"]["PositiveElectrode"]["Coating"]["externalCouplingTerm"]["couplingcells"],
		)
		srange = Int64.(ones(size(trange)))
		msource = exported_all["model"]["PositiveElectrode"]["Coating"]
		couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
		couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"])

		component = :PositiveElectrodeActiveMaterial

	end

	trans = getHalfTrans(msource, couplingfaces, couplingcells, "effectiveElectronicConductivity")

	ct = TPFAInterfaceFluxCT(trange, srange, trans)
	ct_pair = setup_cross_term(ct, target = component, source = :Control, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)

	# Accmulation of charge
	ct = AccumulatorInterfaceFluxCT(1, trange, trans)
	ct_pair = setup_cross_term(ct, target = :Control, source = component, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)


end


########################################################################
# Setup model
########################################################################



function include_current_collectors(inputparams::MatlabInput)

	model = inputparams["model"]

	if haskey(model, "include_current_collectors")
		if isempty(model["include_current_collectors"])
			include_cc = false
		elseif isa(model["include_current_collectors"], Bool) && model["include_current_collectors"] == false
			include_cc = false
		else
			include_cc = true
		end
	else
		include_cc = true
	end

	return include_cc

end


#######################
# Setup battery model #
#######################

function setup_submodels(model, inputparams::MatlabInput, grids, couplings)

	use_groups::Bool = false
	use_p2d::Bool = true
	general_ad::Bool = true
	include_cc = include_current_collectors(inputparams)

	function setup_component(obj::Dict,
		sys,
		general_ad::Bool,
		bcfaces = nothing)

		domain = exported_model_to_domain(obj, bcfaces = bcfaces, general_ad = general_ad)
		G = MRSTWrapMesh(obj["G"])
		data_domain = DataDomain(G)
		for (k, v) in domain.entities
			data_domain.entities[k] = v
		end

		model = SimulationModel(domain, sys, context = DefaultContext(), data_domain = data_domain)
		return model

	end

	stringNames = Dict(
		:NegativeElectrodeActiveMaterial => "NegativeElectrode",
		:PositiveElectrodeActiveMaterial => "PositiveElectrode",
	)

	inputparams = inputparams["model"]

	""" Setup the properties of the active material
	"""
	function setup_active_material(name::Symbol, general_ad::Bool)

		stringName = stringNames[name]

		inputparams_co  = inputparams[stringName]["Coating"]
		inputparams_itf = inputparams[stringName]["Coating"]["ActiveMaterial"]["Interface"]
		inputparams_sd  = inputparams[stringName]["Coating"]["ActiveMaterial"]["SolidDiffusion"]

		am_params                           = JutulStorage()
		am_params[:n_charge_carriers]       = inputparams_itf["numberOfElectronsTransferred"]
		am_params[:maximum_concentration]   = inputparams_itf["saturationConcentration"]
		am_params[:volumetric_surface_area] = inputparams_itf["volumetricSurfaceArea"]
		am_params[:volume_fraction]         = inputparams_co["volumeFraction"]
		am_params[:volume_fractions]        = inputparams_co["volumeFractions"]

		k0 = inputparams_itf["reactionRateConstant"]
		Eak = inputparams_itf["activationEnergyOfReaction"]
		am_params[:reaction_rate_constant_func] = (T) -> arrhenius(T, k0, Eak)

		funcname = inputparams_itf["openCircuitPotential"]["functionname"] # This matlab parameter must have been converted from function handle to string before call
		func = getfield(BattMo, Symbol(funcname))
		am_params[:ocp_func] = func

		am_params[:theta0]   = inputparams_itf["guestStoichiometry0"]
		am_params[:theta100] = inputparams_itf["guestStoichiometry100"]

		if use_p2d
			rp = inputparams_sd["particleRadius"]
			N = Int64(inputparams_sd["N"])
			D = inputparams_sd["referenceDiffusionCoefficient"]
			sys_am = ActiveMaterialP2D(am_params, rp, N, D)
		else
			sys_am = ActiveMaterialNoParticleDiffusion(am_params)
		end

		if !include_cc && name == :NegativeElectrodeActiveMaterial
			bcfaces  = convert_to_int_vector(inputparams_co["externalCouplingTerm"]["couplingfaces"])
			model_am = setup_component(inputparams_co, sys_am, general_ad, bcfaces)
		else
			model_am = setup_component(inputparams_co, sys_am, general_ad, nothing)
		end

		return model_am

	end

	###########################################
	# Setup negative current collector if any #
	###########################################

	if include_cc

		inputparams_necc = inputparams["NegativeElectrode"]["CurrentCollector"]

		necc_params = JutulStorage()
		necc_params[:density] = inputparams_necc["density"]

		sys_necc = CurrentCollector(necc_params)

		bcfaces = convert_to_int_vector(inputparams_necc["externalCouplingTerm"]["couplingfaces"])

		model_necc = setup_component(inputparams_necc, sys_necc, general_ad, bcfaces)


	end


	##############
	# Setup NeAm #
	##############

	model_neam = setup_active_material(:NegativeElectrodeActiveMaterial, general_ad)

	###############
	# Setup Elyte #
	###############

	params                = JutulStorage()
	inputparams_elyte     = inputparams["Electrolyte"]
	params[:transference] = inputparams_elyte["species"]["transferenceNumber"]
	params[:charge]       = inputparams_elyte["species"]["chargeNumber"]
	params[:bruggeman]    = inputparams_elyte["bruggemanCoefficient"]

	# setup diffusion coefficient function, hard coded for the moment because function name is not passed throught model
	# TODO : add general code
	funcname = "computeDiffusionCoefficient_default"
	func = getfield(BattMo, Symbol(funcname))
	params[:diffusivity_func] = func

	# setup diffusion coefficient function
	# TODO : add general code
	funcname = "computeElectrolyteConductivity_default"
	func = getfield(BattMo, Symbol(funcname))
	params[:conductivity_func] = func

	elyte = Electrolyte(params)
	model_elyte = setup_component(inputparams["Electrolyte"],
		elyte, general_ad, nothing)

	##############
	# Setup PeAm #
	##############


	model_peam = setup_active_material(:PositiveElectrodeActiveMaterial, general_ad)

	if include_cc

		###########################################
		# Setup positive current collector if any #
		###########################################
		inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]

		pecc_params = JutulStorage()
		pecc_params[:density] = inputparams_pecc["density"]

		sys_pecc = CurrentCollector(pecc_params)


		model_pecc = setup_component(inputparams_pecc, sys_pecc, general_ad, nothing)

	end

	#######################
	# Setup control model #
	#######################

	controlPolicy = inputparams["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge"

		minE   = inputparams["Control"]["lowerCutoffVoltage"]
		inputI = inputparams["Control"]["Imax"]
		dtup   = inputparams["Control"]["rampupTime"]

		cFun(time) = currentFun(time, inputI, dtup)

		policy = SimpleCVPolicy(current_function = cFun, voltage = minE)

	elseif controlPolicy == "CCCV"

		ctrl = inputparams["Control"]

		policy = CyclingCVPolicy(ctrl["lowerCutoffVoltage"],
			ctrl["upperCutoffVoltage"],
			ctrl["dIdtLimit"],
			ctrl["dEdtLimit"],
			ctrl["initialControl"],
			ctrl["numberOfCycles"])

	else

		error("controlPolicy $controlPolicy not recognized.")

	end

	sys_control    = CurrentAndVoltageSystem(policy)
	domain_control = CurrentAndVoltageDomain()
	model_control  = SimulationModel(domain_control, sys_control, context = DefaultContext())

	if !include_cc
		groups = nothing
		model = MultiModel(
			(
				NeAm = model_neam,
				Electrolyte = model_elyte,
				PeAm = model_peam,
				Control = model_control,
			),
			Val(:Battery);
			groups = groups)
	else
		models = (
			NeCc = model_necc,
			NeAm = model_neam,
			Electrolyte = model_elyte,
			PeAm = model_peam,
			PeCc = model_pecc,
			Control = model_control,
		)
		if use_groups
			groups = ones(Int64, length(models))
			# Should be Control
			groups[end] = 2
			reduction = :schur_apply
		else
			groups    = nothing
			reduction = :reduction
		end
		model = MultiModel(models,
			Val(:Battery);
			groups = groups, reduction = reduction)

	end

	couplings = nothing

	return model, couplings

end


############################
# Setup battery parameters #
############################


function setup_battery_parameters(inputparams::MatlabInput,
	model::MultiModel,
)

	parameters = Dict{Symbol, Any}()

	exported = inputparams.all

	T0 = exported["model"]["initT"]

	include_cc = include_current_collectors(model)

	if include_cc

		#####################
		# Current collector #
		#####################

		prm_necc = Dict{Symbol, Any}()
		exported_necc = exported["model"]["NegativeElectrode"]["CurrentCollector"]
		prm_necc[:Conductivity] = exported_necc["effectiveElectronicConductivity"][1]
		parameters[:NegativeElectrodeCurrentCollector] = setup_parameters(model[:NegativeElectrodeCurrentCollector], prm_necc)
	end

	############################
	# Negative active material #
	############################

	prm_neam = Dict{Symbol, Any}()
	exported_neam = exported["model"]["NegativeElectrode"]["Coating"]
	prm_neam[:Conductivity] = exported_neam["effectiveElectronicConductivity"][1]
	prm_neam[:Temperature] = T0

	if discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion
		prm_neam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
	end

	parameters[:NegativeElectrodeActiveMaterial] = setup_parameters(model[:NegativeElectrodeActiveMaterial], prm_neam)

	###############
	# Electrolyte #
	###############


	prm_elyte = Dict{Symbol, Any}()
	prm_elyte[:Temperature] = T0

	parameters[:Electrolyte] = setup_parameters(model[:Electrolyte], prm_elyte)

	############################
	# Positive active material #
	############################

	prm_peam = Dict{Symbol, Any}()
	exported_peam = exported["model"]["PositiveElectrode"]["Coating"]
	prm_peam[:Conductivity] = exported_peam["effectiveElectronicConductivity"][1]
	prm_peam[:Temperature] = T0

	if discretisation_type(model[:PositiveElectrodeActiveMaterial]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion
		prm_peam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
	end

	parameters[:PositiveElectrodeActiveMaterial] = setup_parameters(model[:PositiveElectrodeActiveMaterial], prm_peam)

	if include_cc

		#######################################
		# Positive current collector (if any) #
		#######################################

		prm_pecc = Dict{Symbol, Any}()
		exported_pecc = exported["model"]["PositiveElectrode"]["CurrentCollector"]
		prm_pecc[:Conductivity] = exported_pecc["effectiveElectronicConductivity"][1]

		parameters[:PositiveElectrodeCurrentCollector] = setup_parameters(model[:PositiveElectrodeCurrentCollector], prm_pecc)
	end

	parameters[:Control] = setup_parameters(model[:Control])

	return parameters

end


#######################
# Setup initial state #
#######################

function setup_initial_state(inputparams::MatlabInput,
	model::MultiModel,
)

	exported = inputparams.all

	state0 = exported["initstate"]

	include_cc = include_current_collectors(model)

	if include_cc
		stringNames = Dict(
			:NegativeElectrodeCurrentCollector => "NegativeElectrode",
			:NegativeElectrodeActiveMaterial => "NegativeElectrode",
			:PositiveElectrodeActiveMaterial => "PositiveElectrode",
			:PositiveElectrodeCurrentCollector => "PositiveElectrode",
		)
	else
		stringNames = Dict(
			:NegativeElectrodeActiveMaterial => "NegativeElectrode",
			:PositiveElectrodeActiveMaterial => "PositiveElectrode",
		)
	end


	""" initialize values for the current collector"""
	function initialize_current_collector!(initState, name::Symbol)

		init = Dict()
		init[:Voltage] = state0[stringNames[name]]["Coating"]["phi"][1]
		initState[name] = init

	end

	""" initialize values for the active material"""
	function initialize_active_material!(initState, name::Symbol)

		stringName = stringNames[name]

		sys = model[name].system

		init = Dict()

		init[:Voltage] = state0[stringName]["Coating"]["phi"][1]
		c = state0[stringName]["Coating"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]

		if discretisation_type(sys) == :P2Ddiscretization
			init[:ParticleConcentration] = c
			init[:SurfaceConcentration] = c
		else
			@assert discretisation_type(sys) == :NoParticleDiffusion
			init[:Concentration] = c
		end

		initState[name] = init

	end

	function initialize_electrolyte!(initState)

		init = Dict()

		init[:Voltage] = state0["Electrolyte"]["phi"][1]
		init[:Concentration] = state0["Electrolyte"]["c"][1]

		initState[:Electrolyte] = init

	end

	function initialize_control!(initState)

		init = Dict(:Voltage => state0["Control"]["E"], :Current => state0["Control"]["I"])

		initState[:Control] = init

	end

	initState = Dict()

	initialize_active_material!(initState, :NegativeElectrodeActiveMaterial)
	initialize_electrolyte!(initState)
	initialize_active_material!(initState, :PositiveElectrodeActiveMaterial)

	if include_cc
		initialize_current_collector!(initState, :NegativeElectrodeCurrentCollector)
		initialize_current_collector!(initState, :PositiveElectrodeCurrentCollector)
	end

	initialize_control!(initState)

	initState = setup_state(model, initState)

	return initState

end

function exported_model_to_domain(exported; bcfaces = nothing,
	general_ad = true)

	""" Returns domain"""

	N = exported["G"]["faces"]["neighbors"]
	N = Int64.(N)

	if !isnothing(bcfaces)
		isboundary = (N[bcfaces, 1] .== 0) .| (N[bcfaces, 2] .== 0)
		@assert all(isboundary)

		bc_cells = N[bcfaces, 1] + N[bcfaces, 2]
		bc_hfT = getHalfTrans(exported, bcfaces)
	else
		bc_hfT = []
		bc_cells = []
	end

	vf = []
	if haskey(exported, "volumeFraction")
		if length(exported["volumeFraction"]) == 1
			vf = exported["volumeFraction"]
		else
			vf = exported["volumeFraction"][:, 1]
		end
	end

	internal_faces = (N[:, 2] .> 0) .& (N[:, 1] .> 0)
	N = copy(N[internal_faces, :]')

	face_areas   = vec(exported["G"]["faces"]["areas"][internal_faces])
	face_normals = exported["G"]["faces"]["normals"][internal_faces, :] ./ face_areas
	face_normals = copy(face_normals')
	if length(exported["G"]["cells"]["volumes"]) == 1
		volumes    = exported["G"]["cells"]["volumes"]
		volumes    = Vector{Float64}(undef, 1)
		volumes[1] = exported["G"]["cells"]["volumes"]
	else
		volumes = vec(exported["G"]["cells"]["volumes"])
	end
	# P = exported["G"]["operators"]["cellFluxOp"]["P"]
	# S = exported["G"]["operators"]["cellFluxOp"]["S"]
	P = []
	S = []
	T = exported["G"]["operators"]["T"] .* 1.0
	G = MinimalECTPFAGrid(volumes, N, vec(T);
		bc_cells = bc_cells,
		bc_hfT   = bc_hfT,
		P        = P,
		S        = S,
		vf       = vf)

	nc = length(volumes)
	if general_ad
		flow = PotentialFlow(G)
	else
		flow = TwoPointPotentialFlowHardCoded(G)
	end
	disc = (flow = flow,)
	domain = DiscretizedDomain(G, disc)

	return domain

end


function convert_to_int_vector(x::Float64)
	vec = Int64.(Vector{Float64}([x]))
	return vec
end

function convert_to_int_vector(x::Matrix{Float64})
	vec = Int64.(Vector{Float64}(x[:, 1]))
	return vec
end

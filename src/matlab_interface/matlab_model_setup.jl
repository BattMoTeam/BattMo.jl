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

	include_cc = include_current_collectors(inputparams)

	#################################
	# setup coupling NeAm <-> Elyte #
	#################################

	srange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 1]) # negative electrode
	trange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 2]) # electrolyte (negative side)

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	#################################
	# setup coupling Elyte <-> PeAm #
	#################################

	srange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:, 1]) # postive electrode
	trange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:, 2]) # electrolyte (positive side)

	if discretisation_type(model[:PeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:PeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PeAm, equation = :mass_conservation)
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
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange, trange, trans)
		ct_pair = setup_cross_term(ct, target = :NeCc, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		#######################################
		# setup coupling PeCc <-> PeAm charge #
		#######################################

		target = Dict(
			:model => :PeAm,
			:equation => :charge_conservation,
		)
		source = Dict(
			:model => :PeCc,
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
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange, trange, trans)
		ct_pair = setup_cross_term(ct, target = :PeCc, source = :PeAm, equation = :charge_conservation)
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

		component = :PeCc

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

		component = :PeAm

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

function get_simulation_input(inputparams::MatlabInput;
	                          use_model_scaling::Bool           = true,
	                          extra_timing::Bool                = false,
	                          max_step::Union{Integer, Nothing} = nothing,
	                          config_kwargs::NamedTuple         = NamedTuple())

	model, parameters, couplings = setup_model!(inputparams)

	state0 = setup_initial_state(inputparams, model)

	forces = setup_forces(model)

	simulator = Simulator(model; state0 = state0, parameters = parameters, copy_state = true)

	timesteps = setup_timesteps(inputparams; max_step = max_step)

	output = Dict(:simulator   => simulator,
		          :forces      => forces,
		          :state0      => state0,
		          :parameters  => parameters,
		          :inputparams => inputparams,
		          :model       => model,
		          :couplings   => couplings,
		          :timesteps   => timesteps)

	return output

end

function setup_model!(inputparams::MatlabInput)
    
	# setup the submodels and also return a coupling structure which is used to setup later the cross-terms
	model, couplings = setup_submodels(inputparams)

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)
	parameters = setup_battery_parameters(inputparams, model)

	# setup the cross terms which couples the submodels.
	setup_coupling_cross_terms!(inputparams, model, parameters, couplings)

	setup_initial_control_policy!(model[:Control].system.policy, inputparams, parameters)
	#model.context = DefaultContext()

	output = (model = model,
		      parameters = parameters,
		      couplings = couplings)

	return output

end


function run_battery(inputparams::MatlabInput;
	                 hook = nothing,
	                 use_p2d = true,
	                 kwargs...)
    
	#Setup simulation
	output = get_simulation_input(deepcopy(inputparams); use_p2d = use_p2d, kwargs...)

	simulator = output[:simulator]
	model     = output[:model]
	state0    = output[:state0]
	forces    = output[:forces]
	timesteps = output[:timesteps]
	cfg       = output[:cfg]


	if !isnothing(hook)
		hook(simulator,
			model,
			state0,
			forces,
			timesteps,
			cfg)
	end

	# Perform simulation
	states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	extra = output
	extra[:timesteps] = timesteps

	if isa(inputparams, MatlabInputParamsOld)
		cellSpecifications = nothing
	else
		cellSpecifications = computeCellSpecifications(model)
	end

	return (states             = states,
		cellSpecifications = cellSpecifications,
		reports            = reports,
		inputparams        = inputparams,
		extra              = extra)

end


function setup_submodels(inputparams::MatlabInput)

	use_groups::Bool = false
	use_p2d::Bool    = true
	general_ad::Bool = true
    
	include_cc = include_current_collectors(inputparams)

	function setup_component(obj::Dict,
		                     sys,
		                     general_ad::Bool,
                             dirichlet_boundary = false)
        
		domain = exported_model_to_domain(obj; dirichlet_boundary = dirichlet_boundary, general_ad = general_ad)
		# G = MRSTWrapMesh(obj["G"])
		data_domain = DataDomain(domain)
		for (k, v) in domain.entities
			data_domain.entities[k] = v
		end
		model = SimulationModel(domain, sys, context = DefaultContext(), data_domain = data_domain)
		return model

	end

	stringNames = Dict(
		:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode",
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

		am_params[:volume_fraction]         = inputparams_co["volumeFraction"]
		am_params[:volume_fractions]        = inputparams_co["volumeFractions"]

		# Interface
        
        am_params[:n_charge_carriers]       = inputparams_itf["numberOfElectronsTransferred"]
		am_params[:maximum_concentration]   = inputparams_itf["saturationConcentration"]
		am_params[:volumetric_surface_area] = inputparams_itf["volumetricSurfaceArea"]
		am_params[:setting_butler_volmer]   = "Standard"
		k0  = inputparams_itf["reactionRateConstant"]
        Eak = inputparams_itf["activationEnergyOfReaction"]
        
		am_params[:setting_temperature_dependence] = true
        am_params[:reaction_rate_constant_func]    = k0
        am_params[:ecd_funcconstant]               = true
        am_params[:activation_energy_of_reaction]  = Eak
        
        funcname = inputparams_itf["openCircuitPotential"]["functionName"] # This matlab parameter must have been converted from function handle to string before call
		func = getfield(BattMo, Symbol(funcname))
		am_params[:ocp_func] = func

		am_params[:theta0]   = inputparams_itf["guestStoichiometry0"]
		am_params[:theta100] = inputparams_itf["guestStoichiometry100"]

        # Solid diffusion
		if use_p2d
			rp = inputparams_sd["particleRadius"]
			N = Int64(inputparams_sd["N"])
			D = inputparams_sd["referenceDiffusionCoefficient"]

            am_params[:diff_funcconstant] = true
            am_params[:diff_func] = D
            
			sys_am = ActiveMaterialP2D(am_params, rp, N, D)
		else
			sys_am = ActiveMaterialNoParticleDiffusion(am_params)
		end

		if !include_cc && name == :NeAm
			model_am = setup_component(inputparams_co, sys_am, general_ad, true)
		else
			model_am = setup_component(inputparams_co, sys_am, general_ad)
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

		model_necc = setup_component(inputparams_necc, sys_necc, general_ad, true)

	end


	##############
	# Setup NeAm #
	##############

	model_neam = setup_active_material(:NeAm, general_ad)

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
		                          elyte, general_ad)

	##############
	# Setup PeAm #
	##############


	model_peam = setup_active_material(:PeAm, general_ad)

	if include_cc

		###########################################
		# Setup positive current collector if any #
		###########################################
		inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]

		pecc_params = JutulStorage()
		pecc_params[:density] = inputparams_pecc["density"]

		sys_pecc = CurrentCollector(pecc_params)

		model_pecc = setup_component(inputparams_pecc, sys_pecc, general_ad)

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
	                              model::MultiModel)
    
	parameters = Dict{Symbol, Any}()

	exported = inputparams.all

	T0 = exported["model"]["initT"]

	include_cc = include_current_collectors(inputparams)

	if include_cc

		#####################
		# Current collector #
		#####################

		prm_necc = Dict{Symbol, Any}()
		exported_necc = exported["model"]["NegativeElectrode"]["CurrentCollector"]
		prm_necc[:Conductivity] = exported_necc["effectiveElectronicConductivity"][1]
		parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)
        
	end

	############################
	# Negative active material #
	############################

	prm_neam = Dict{Symbol, Any}()
	exported_neam = exported["model"]["NegativeElectrode"]["Coating"]
	prm_neam[:Conductivity] = exported_neam["effectiveElectronicConductivity"][1]
	prm_neam[:Temperature] = T0

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_neam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
	end

	parameters[:NeAm] = setup_parameters(model[:NeAm], prm_neam)

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

	if discretisation_type(model[:PeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_peam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
	end

	parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

	if include_cc

		#######################################
		# Positive current collector (if any) #
		#######################################

		prm_pecc = Dict{Symbol, Any}()
		exported_pecc = exported["model"]["PositiveElectrode"]["CurrentCollector"]
		prm_pecc[:Conductivity] = exported_pecc["effectiveElectronicConductivity"][1]

		parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
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

	include_cc = include_current_collectors(inputparams)

	if include_cc
		stringNames = Dict(
			:NeCc => "NegativeElectrode",
			:NeAm => "NegativeElectrode",
			:PeAm => "PositiveElectrode",
			:PeCc => "PositiveElectrode",
		)
	else
		stringNames = Dict(
			:NeAm => "NegativeElectrode",
			:PeAm => "PositiveElectrode",
		)
	end


	""" initialize values for the current collector"""
	function initialize_current_collector!(initState, name::Symbol)

		init = Dict()
		init[:ElectricPotential] = state0[stringNames[name]]["Coating"]["phi"][1]
		initState[name] = init

	end

	""" initialize values for the active material"""
	function initialize_active_material!(initState, name::Symbol)

		stringName = stringNames[name]

		sys = model[name].system

		init = Dict()

		init[:ElectricPotential] = state0[stringName]["Coating"]["phi"][1]
		c = state0[stringName]["Coating"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]

		if discretisation_type(sys) == :P2Ddiscretization
			init[:ParticleConcentration] = c
			init[:SurfaceConcentration] = c
		else
			@assert discretisation_type(sys) == :NoParticleDiffusion
			init[:ElectrolyteConcentration] = c
		end

		initState[name] = init

	end

	function initialize_electrolyte!(initState)

		init = Dict()

		init[:ElectricPotential] = state0["Electrolyte"]["phi"][1]
		init[:ElectrolyteConcentration] = state0["Electrolyte"]["c"][1]

		initState[:Electrolyte] = init

	end

	function initialize_control!(initState)

		init = Dict(:ElectricPotential => state0["Control"]["E"], :Current => state0["Control"]["I"])

		initState[:Control] = init

	end

	initState = Dict()

	initialize_active_material!(initState, :NeAm)
	initialize_electrolyte!(initState)
	initialize_active_material!(initState, :PeAm)

	if include_cc
		initialize_current_collector!(initState, :NeCc)
		initialize_current_collector!(initState, :PeCc)
	end

	initialize_control!(initState)

	initState = setup_state(model, initState)

	return initState

end

function exported_model_to_domain(exported; dirichlet_boundary = false,
	                              general_ad = true)

	""" Returns domain"""

	volumes = vec(exported["G"]["volumes"])

	N = exported["G"]["neighborship"]
	N = Int64.(N)

    N_hT = exported["G"]["half_trans"]

    cf    = Int64.(exported["G"]["cell_face_tbl"])
    cf_hT = vec(exported["G"]["cell_face_hT"])
    
    bc_cells = vec(Int64.(exported["G"]["boundary_cells"]))
    bc_hT    = vec(exported["G"]["boundary_hT"])
    
	vf = []
	if haskey(exported, "volumeFraction")
		if length(exported["volumeFraction"]) == 1
			vf = exported["volumeFraction"]
		else
			vf = exported["volumeFraction"][:, 1]
		end
	end

	# P = exported["G"]["operators"]["cellFluxOp"]["P"]
	# S = exported["G"]["operators"]["cellFluxOp"]["S"]
	P = []
	S = []
    
	G = MinimalTpfaGrid(volumes,
                        N,
                        N_hT,
                        cf,
                        cf_hT,
                        bc_cells,
                        bc_hT,
                        vf)
    
	if general_ad
		flow = PotentialFlow(G)
	else
		flow = TwoPointPotentialFlowHardCoded(G)
	end
	disc = (flow = flow,)
	domain = DiscretizedDomain(G, disc)

    if dirichlet_boundary
        domain.entities[BoundaryDirichletFaces()] = length(bc_cells)
    end
    
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

function getHalfTrans(model::Dict{String, Any},
	                  faces,
	                  cells,
	                  quantity::String)
	""" recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the given cells.
	Here, the faces should belong the corresponding cells at the same index"""

	s = model[quantity]
	if length(s) == 1
		s = s * ones(length(cells))
	else
		s = s[cells]
	end

    hT = getHalfTrans(model, faces)
    
	hT = hT .* s

	return hT

end

function getHalfTrans(model::Dict{String, <:Any},
	                  faces)
	""" recover the half transmissibilities for boundary faces"""

    hT = Vector{Float64}(undef, length(faces))

    hT_all        = model["G"]["cell_face_hT"]
    cell_face_tbl = model["G"]["cell_face_tbl"]
    
    faces_all = cell_face_tbl[2, :]
    
    for (i, f) in enumerate(faces)
        for (ii, ff) in enumerate(faces_all)
            if f == ff
                hT[i] = hT_all[ii]
            end
        end
    end

	return hT

end


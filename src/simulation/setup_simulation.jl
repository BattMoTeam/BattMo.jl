export setup_simulation

####################
# Setup simulation #
####################

function setup_simulation(inputparams::AbstractInputParams, battery_model;
	use_p2d::Bool                     = true,
	use_model_scaling::Bool           = true,
	extra_timing::Bool                = false,
	max_step::Union{Integer, Nothing} = nothing,
	linear_solver::Symbol             = :direct,
	general_ad::Bool                  = true,
	use_groups::Bool                  = false,
	model_kwargs::NamedTuple          = NamedTuple(),
	config_kwargs::NamedTuple         = NamedTuple())

	model = prepare_jutul_model(inputparams, battery_model; kwargs...)

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)
	parameters = setup_battery_parameters(inputparams, model)

	state0 = setup_initial_state(inputparams, model)

	forces = setup_forces(model)

	simulator = Simulator(model; state0 = state0, parameters = parameters, copy_state = true)

	timesteps = setup_timesteps(inputparams; max_step = max_step)

	cfg = setup_config(simulator,
		model,
		parameters,
		linear_solver,
		extra_timing,
		use_model_scaling;
		config_kwargs...)

	output = Dict(:simulator   => simulator,
		:forces      => forces,
		:state0      => state0,
		:parameters  => parameters,
		:inputparams => inputparams,
		:model       => model,
		:timesteps   => timesteps,
		:cfg         => cfg)

	return output

end

function prepare_jutul_model(inputparams, battery_model; kwargs...)

	cycling_model = setup_cycling_model(inputparams; kwargs...)

	model = setup_multi_model(battery_model, cycling_model)

	# setup the cross terms which couples the submodels.
	setup_coupling_cross_terms!(inputparams, model, parameters, couplings)

	setup_initial_control_policy!(model[:Control].system.policy, inputparams, parameters)

	return model

end

function setup_multi_model(battery_model, cycling_model)

	if !include_cc
		groups = nothing
		model = MultiModel(
			(
				NeAm    = battery_model.negative_electrode_active_material,
				Elyte   = battery_model.electrolyte,
				PeAm    = battery_model.positive_electrode_active_material,
				Control = cycling_model,
			),
			Val(:Battery);
			groups = groups)
	else
		models = (
			NeCc    = battery_model.negative_electrode_current_collector,
			NeAm    = battery_model.negative_electrode_active_material,
			Elyte   = battery_model.electrolyte,
			PeAm    = battery_model.positive_electrode_active_material,
			PeCc    = battery_model.positive_electrode_current_collector,
			Control = cycling_model,
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

	setup_volume_fractions!(model, battery_model.mesh, battery_model.couplings["Electrolyte"])

	return model
end

function setup_cycling_model(inputparams; kwargs...)
	jsondict = inputparams.dict
	controlPolicy = jsondict["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge"

		minE = jsondict["Control"]["lowerCutoffVoltage"]

		policy = SimpleCVPolicy()

	elseif controlPolicy == "CCCV"

		ctrl = jsondict["Control"]

		policy = CyclingCVPolicy(ctrl["lowerCutoffVoltage"],
			ctrl["upperCutoffVoltage"],
			ctrl["dIdtLimit"],
			ctrl["dEdtLimit"],
			ctrl["initialControl"],
			ctrl["numberOfCycles"])

	else

		error("controlPolicy not recognized.")

	end

	sys_control    = CurrentAndVoltageSystem(policy)
	domain_control = CurrentAndVoltageDomain()
	model_control  = SimulationModel(domain_control, sys_control; kwargs...)
	return model_control

end

function setup_initial_state(inputparams::InputParams,
	model::MultiModel)

	include_cc = include_current_collectors(model)

	T        = inputparams["initT"]
	SOC_init = inputparams["SOC"]

	function setup_init_am(name, model)

		theta0   = model[name].system[:theta0]
		theta100 = model[name].system[:theta100]
		cmax     = model[name].system[:maximum_concentration]
		N        = model[name].system.discretization[:N]
		refT     = 298.15

		theta     = SOC_init * (theta100 - theta0) + theta0
		c         = theta * cmax
		SOC       = SOC_init
		nc        = count_entities(model[name].data_domain, Cells())
		init      = Dict()
		init[:Cs] = c * ones(nc)
		init[:Cp] = c * ones(N, nc)

		if model[name] isa SEImodel
			init[:normalizedSEIlength] = 1.0 * ones(nc)
			init[:normalizedSEIvoltageDrop] = 0.0 * ones(nc)
		end

		if haskey(model[name].system.params, :ocp_funcexp)
			OCP = model[name].system[:ocp_func](c, T, refT, cmax)
		elseif haskey(model[name].system.params, :ocp_funcdata)

			OCP = model[name].system[:ocp_func](theta)

		else
			OCP = model[name].system[:ocp_func](c, T, cmax)
		end

		return (init, nc, OCP)

	end

	function setup_current_collector(name, phi, model)
		nc = count_entities(model[name].data_domain, Cells())
		init = Dict()
		init[:Phi] = phi * ones(nc)
		return init
	end

	initState = Dict()

	# Setup initial state in negative active material

	init, nc, negOCP = setup_init_am(:NeAm, model)
	init[:Phi] = zeros(nc)
	initState[:NeAm] = init

	# Setup initial state in electrolyte

	nc = count_entities(model[:Elyte].data_domain, Cells())

	init       = Dict()
	init[:C]   = inputparams["Electrolyte"]["initialConcentration"] * ones(nc)
	init[:Phi] = -negOCP * ones(nc)

	initState[:Elyte] = init

	# Setup initial state in positive active material

	init, nc, posOCP = setup_init_am(:PeAm, model)
	init[:Phi] = (posOCP - negOCP) * ones(nc)

	initState[:PeAm] = init

	if include_cc
		# Setup negative current collector
		initState[:NeCc] = setup_current_collector(:NeCc, 0, model)
		# Setup positive current collector
		initState[:PeCc] = setup_current_collector(:PeCc, posOCP - negOCP, model)
	end

	init           = Dict()
	init[:Phi]     = posOCP - negOCP
	init[:Current] = getInitCurrent(model[:Control])

	initState[:Control] = init

	initState = setup_state(model, initState)

	return initState

end

function setup_timesteps(inputparams::InputParams;
	kwargs...)
	"""
		Method setting up the timesteps from a json file object. 
	"""

	controlPolicy = inputparams["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge"

		DRate = inputparams["Control"]["DRate"]
		con = Constants()
		totalTime = 1.1 * con.hour / DRate

		if haskey(inputparams["TimeStepping"], "totalTime")
			@warn "totalTime value is given but not used"
		end

		if haskey(inputparams["TimeStepping"], "timeStepDuration")
			dt = inputparams["TimeStepping"]["timeStepDuration"]
			if haskey(inputparams["TimeStepping"], "numberOfTimeSteps")
				@warn "Number of time steps is given but not used"
			end
		else
			n = inputparams["TimeStepping"]["numberOfTimeSteps"]
			dt = totalTime / n
		end
		if haskey(inputparams["TimeStepping"], "useRampup") && inputparams["TimeStepping"]["useRampup"]
			nr = inputparams["TimeStepping"]["numberOfRampupSteps"]
		else
			nr = 1
		end

		timesteps = rampupTimesteps(totalTime, dt, nr)

	elseif controlPolicy == "CCCV"

		ncycles = inputparams["Control"]["numberOfCycles"]
		DRate = inputparams["Control"]["DRate"]
		CRate = inputparams["Control"]["CRate"]

		con = Constants()

		totalTime = ncycles * 1.5 * (1 * con.hour / CRate + 1 * con.hour / DRate)

		if haskey(inputparams["TimeStepping"], "totalTime")
			@warn "totalTime value is given but not used"
		end

		if haskey(inputparams["TimeStepping"], "timeStepDuration")
			dt = inputparams["TimeStepping"]["timeStepDuration"]
			n  = Int64(floor(totalTime / dt))
			if haskey(inputparams["TimeStepping"], "numberOfTimeSteps")
				@warn "Number of time steps is given but not used"
			end
		else
			n  = inputparams["TimeStepping"]["numberOfTimeSteps"]
			dt = totalTime / n
		end

		timesteps = repeat([dt], n)

	else

		error("Control policy $controlPolicy not recognized")

	end

	return timesteps
end

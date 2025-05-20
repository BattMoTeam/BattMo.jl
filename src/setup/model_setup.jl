
export
	run_battery,
	setup_simulation,
	setup_model,
	Simulation,
	Optimization,
	solve


#########################
# Solving problem types #
#########################

"""
	abstract type SolvingProblem

Abstract type for all problem definitions related to solving battery simulations.
Subtypes of `SolvingProblem` represent specific simulation or solving configurations.
"""
abstract type SolvingProblem end


"""
	struct Simulation <: SolvingProblem

Represents a battery simulation problem to be solved.

# Fields
- `function_to_solve ::Function` : The function responsible for running the simulation.
- `model ::BatteryModelSetup` : The battery model being simulated.
- `cell_parameters ::CellParameters` : The cell parameters for the simulation.
- `cycling_protocol ::CyclingProtocol` : The cycling protocol used.
- `simulation_settings ::SimulationSettings` : The simulation settings applied.
- `is_valid ::Bool` : A flag indicating if the simulation is valid.

# Constructor
	Simulation(model::BatteryModelSetup, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol; simulation_settings::SimulationSettings = get_default_simulation_settings(model))

Creates an instance of `Simulation`, initializing it with the given parameters and defaulting
simulation settings if not provided.
"""
struct Simulation <: SolvingProblem
	function_to_solve::Function
	model_setup::BatteryModelSetup
	cell_parameters::CellParameters
	cycling_protocol::CyclingProtocol
	simulation_settings::SimulationSettings
	is_valid::Bool

	function Simulation(model_setup::BatteryModelSetup, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol; simulation_settings::SimulationSettings = get_default_simulation_settings(model_setup))

		if model_setup.is_valid
			function_to_solve = run_battery

			# Here will come a validation function
			model_settings = model_setup.model_settings
			cell_parameters_is_valid = validate_parameter_set(cell_parameters, model_settings)
			cycling_protocol_is_valid = validate_parameter_set(cycling_protocol)
			simulation_settings_is_valid = validate_parameter_set(simulation_settings, model_settings)

			if cell_parameters_is_valid && cycling_protocol_is_valid && simulation_settings_is_valid
				is_valid = true
			else
				is_valid = false
			end
		else
			error("""
			Oops! Your Model object is not valid. 🛑

			TIP: Validation happens when instantiating the Model object. 
			Check the warnings to see exactly where things went wrong. 🔍

			""")
		end
		return new{}(function_to_solve, model_setup, cell_parameters, cycling_protocol, simulation_settings, is_valid)
	end
end

struct Optimization <: SolvingProblem
	function_to_solve::Function
	setup::Any
	parameters::Any
	model::Any
	sensitivities::Any
	initial_results::Any

	function Optimization(initial_results, objective::Function; info_level = 0, end_report = false)

		function_to_solve = run_optimization

		reports = initial_results[:reports]
		states = initial_results[:states]
		extra = initial_results[:extra]
		parameters = extra[:parameters]
		model = extra[:model]
		state0 = extra[:state0]
		forces = extra[:forces]
		config = extra[:cfg]
		time_steps = extra[:timesteps]

		reports = reports[1:end-1]

		dG = solve_adjoint_sensitivities(model, states, reports, objective,
			forces = forces, state0 = state0, parameters = parameters)

		config[:info_level] = info_level
		config[:end_report] = end_report

		cfg = optimization_config(model, parameters, rel_min = 0.5, rel_max = 5, use_scaling = true)

		opt_setup = setup_parameter_optimization(model, state0, parameters, time_steps, forces, objective, cfg, config = config)

		return new{}(function_to_solve, opt_setup, parameters, model, dG, initial_results)
	end
end


#########
# Solve #
#########

"""
	solve(problem::Simulation; hook=nothing, kwargs...)

Solves a given `Simulation` problem by running the associated simulation function.

# Arguments
- `problem ::Simulation` : The simulation problem instance.
- `hook` (optional) : A user-defined function or callback to modify the solving process.
- `kwargs...` : Additional keyword arguments passed to the solver.

# Returns
The output of the simulation if the problem is valid. 

# Throws
Throws an error if the `Simulation` object is not valid, prompting the user to check warnings during instantiation.
"""
function solve(problem::Simulation; accept_invalid = false, hook = nothing, info_level = 0, end_report = true, kwargs...)

	config_kwargs = (info_level = info_level, end_report = end_report)

	use_p2d = true


	if accept_invalid == true
		output = problem.function_to_solve(problem.model_setup, problem.cell_parameters, problem.cycling_protocol, problem.simulation_settings;
			hook = nothing,
			use_p2d = use_p2d,
			config_kwargs = config_kwargs,
			kwargs...)
	else
		if problem.is_valid == true
			output = problem.function_to_solve(problem.model_setup, problem.cell_parameters, problem.cycling_protocol, problem.simulation_settings;
				hook = nothing,
				use_p2d = use_p2d,
				config_kwargs = config_kwargs,
				kwargs...)

			return output
		else

			error("""
			Oops! Your Simulation object is not valid. 🛑

			TIP: Validation happens when instantiating the Simulation object. 
			Check the warnings to see exactly where things went wrong. 🔍

			If you’re confident you know what you're doing, you can bypass the validation result 
			by setting the flag "accept_invalid = true": 

				solve(sim; accept_invalid = true)

			But proceed with caution! 😎 
			""")
		end
	end

end


function solve(problem::Optimization; hook = nothing, info_level = 0, end_report = false, kwargs...)


	output = problem.function_to_solve(problem.setup, problem.initial_results,
		hook = nothing,
		info_level = info_level,
		end_report = end_report,
		kwargs...)

	return output


end

######################
# Run optimization #
######################

function run_optimization(opt_setup, initial_results; hook = nothing, info_level = 0, end_report = false, kwargs...)

	extra = initial_results[:extra]
	parameters = extra[:parameters]
	model = extra[:model]
	state0 = extra[:state0]
	forces = extra[:forces]
	config = extra[:cfg]
	time_steps = extra[:timesteps]

	config[:info_level] = info_level
	config[:end_report] = end_report

	## Print starting values

	x0 = opt_setup.x0
	F0 = opt_setup.F!(x0)
	dF0 = opt_setup.dF!(similar(x0), x0)

	@info "Initial objective: $F0, gradient norm $(sum(abs, dF0))"

	## Perform optimization loop using LBFGSB package


	lower = opt_setup.limits.min
	upper = opt_setup.limits.max
	x0 = opt_setup.x0
	prt = 1
	f! = opt_setup.F!
	g! = opt_setup.dF!
	results, final_x = lbfgsb(f!, g!, x0, lb = lower, ub = upper, iprint = prt, maxfun = 200, maxiter = 100)

	## Verify the results

	F_final = opt_setup.F!(final_x)
	prm_tuned = deepcopy(parameters)
	data = opt_setup.data
	devectorize_variables!(prm_tuned, model, final_x, data[:mapper], config = data[:config])
	states_t, rep_t = simulate(state0, model, time_steps, parameters = prm_tuned, forces = forces, config = config)

	return (states = states_t, report = rep_t, final_x = final_x)
end


###############
# Run battery #
###############



"""
	run_battery(model::BatteryModelSetup, cell_parameters::CellParameters, 
				cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings; 
				hook=nothing, kwargs...)

Runs a battery simulation using the provided model, cell parameters, cycling protocol, and simulation settings.

# Arguments
- `model ::BatteryModelSetup` : The battery model to be used.
- `cell_parameters ::CellParameters` : The cell parameter set.
- `cycling_protocol ::CyclingProtocol` : The cycling protocol parameter set.
- `simulation_settings ::SimulationSettings` : The simulation settings parameter set.
- `hook` (optional) : A user-defined function or callback to modify the process.
- `kwargs...` : Additional keyword arguments.

# Returns
The output of the battery simulation after executing `run_battery` with formatted input.
"""
function run_battery(model::BatteryModelSetup, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings;
	hook = nothing,
	use_p2d = true,
	kwargs...)

	model_settings = model.model_settings

	battmo_formatted_input = convert_parameter_sets_to_battmo_input(model_settings, cell_parameters, cycling_protocol, simulation_settings)

	# @info JSON.json(battmo_formatted_input, 2)

	output = run_battery(battmo_formatted_input; hook = hook, use_p2d = use_p2d, kwargs...)

	return output
end


"""
	run_battery(inputparams::AbstractInputParams; hook = nothing)

Simulate a battery for a given input. The input is expected to be an instance of AbstractInputParams. Such input can be
prepared from a json file using the function [`load_battmo_formatted_input`](@ref).


"""
function run_battery(inputparams::BattMoFormattedInput;
	hook = nothing,
	use_p2d = true,
	kwargs...)
	"""
		Run battery wrapper method. Call setup_simulation function and run the simulation with the setup that is returned. A hook function can be given to modify the setup after the call to setup_simulation
	"""

	#Setup simulation
	output = setup_simulation(deepcopy(inputparams); use_p2d = use_p2d, kwargs...)

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

	if isa(inputparams, MatlabInputParams)
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


####################
# Setup simulation #
####################

function setup_simulation(inputparams::BattMoFormattedInput;
	use_p2d::Bool                     = true,
	use_model_scaling::Bool           = true,
	extra_timing::Bool                = false,
	max_step::Union{Integer, Nothing} = nothing,
	linear_solver::Symbol             = :direct,
	general_ad::Bool                  = true,
	use_groups::Bool                  = false,
	model_kwargs::NamedTuple          = NamedTuple(),
	config_kwargs::NamedTuple         = NamedTuple())

	model, parameters = setup_model(inputparams;
		use_groups = use_groups,
		general_ad = general_ad,
		use_p2d = use_p2d,
		model_kwargs...)

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


###############
# Setup model #
###############

function setup_model(inputparams::BattMoFormattedInput;
	use_p2d::Bool    = true,
	use_groups::Bool = false,
	general_ad       = true,
	kwargs...)

	# setup the submodels and also return a coupling structure which is used to setup later the cross-terms
	model, couplings = setup_submodels(inputparams,
		use_groups = use_groups,
		use_p2d    = use_p2d;
		general_ad = general_ad,
		kwargs...)

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)
	parameters = setup_battery_parameters(inputparams, model)

	# setup the cross terms which couples the submodels.
	setup_coupling_cross_terms!(inputparams, model, parameters, couplings)

	setup_initial_control_policy!(model[:Control].system.policy, inputparams, parameters)
	#model.context = DefaultContext()
	return model, parameters

end


function setup_submodels(inputparams::InputParams;
	use_groups::Bool = false,
	general_ad::Bool = true,
	use_p2d = true,
	T = Float64,
	kwargs...)

	include_cc = include_current_collectors(inputparams)

	jsondict = inputparams.all

	grids, couplings = setup_grids_and_couplings(inputparams)

	stringNames = Dict(
		:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode",
	)

	"""
	Helper function to setup the active materials
	"""
	function setup_active_material(name::Symbol; kwargs...)

		stringName = stringNames[name]

		function computeVolumeFraction(codict)
			# We compute the volume fraction form the coating data

			am = "ActiveMaterial"
			bd = "Binder"
			ad = "ConductingAdditive"

			compnames = [am, bd, ad]

			# Do it this way since values could be AD.
			get_specific_volume(compname) = codict[compname]["massFraction"] / codict[compname]["density"]
			specificVolumes = map(get_specific_volume, compnames)

			sumSpecificVolumes = sum(specificVolumes)
			volumeFractions = [sv / sumSpecificVolumes for sv in specificVolumes]

			effectiveDensity = codict["effectiveDensity"]
			volumeFraction = sumSpecificVolumes * effectiveDensity

			return volumeFraction, volumeFractions, effectiveDensity

		end

		inputparams_am = jsondict[stringName]["Coating"]["ActiveMaterial"]

		am_params                           = JutulStorage()
		vf, vfs, eff_dens                   = computeVolumeFraction(jsondict[stringName]["Coating"])
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
			fcn = setup_function_from_function_name(funcname)
			am_params[:ocp_func] = fcn

		else
			am_params[:ocp_funcdata] = true
			data_x = inputparams_am["Interface"]["openCircuitPotential"]["data_x"]
			data_y = inputparams_am["Interface"]["openCircuitPotential"]["data_y"]

			interpolation_object = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
			am_params[:ocp_func] = interpolation_object
		end

		if use_p2d
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
		else
			sys_am = ActiveMaterialNoParticleDiffusion(am_params)
		end

		grid     = grids[stringName]
		coupling = couplings[stringName]

		boundary = nothing
		if !include_cc && name == :NeAm
			addDirichlet = true
			boundary = coupling["External"]
		else
			addDirichlet = false
			boundary = nothing
		end

		model_am = setup_component(grid,
			sys_am;
			general_ad = general_ad,
			dirichletBoundary = boundary,
			kwargs...)

		return model_am

	end

	####################################
	# Setup negative current collector #
	####################################

	if include_cc

		grid     = grids["NegativeCurrentCollector"]
		coupling = couplings["NegativeCurrentCollector"]

		boundary = coupling["External"]
		necc_params = JutulStorage()
		necc_params[:density] = jsondict["NegativeElectrode"]["CurrentCollector"]["density"]

		sys_necc = CurrentCollector(necc_params)
		model_necc = setup_component(grid,
			sys_necc,
			dirichletBoundary = boundary,
			general_ad = general_ad; kwargs...)
	end

	##############
	# Setup NeAm #
	##############

	model_neam = setup_active_material(:NeAm; kwargs...)

	###############
	# Setup Elyte #
	###############

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
		fcn = setup_function_from_function_name(funcname)
		params[:diffusivity_func] = fcn

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
		fcn = setup_function_from_function_name(funcname)
		params[:conductivity_func] = fcn

	else
		data_x = inputparams_elyte["ionicConductivity"]["data_x"]
		data_y = inputparams_elyte["ionicConductivity"]["data_y"]

		interpolation = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		params[:conductivity_data] = true
		params[:conductivity_func] = interpolation

	end

	elyte = Electrolyte(params)

	model_elyte = setup_component(grids["Electrolyte"], elyte, general_ad = general_ad; kwargs...)

	##############
	# Setup PeAm #
	##############

	model_peam = setup_active_material(:PeAm; kwargs...)

	###########################################
	# Setup negative current collector if any #
	###########################################

	if include_cc

		grid = grids["PositiveCurrentCollector"]
		pecc_params = JutulStorage()
		pecc_params[:density] = jsondict["PositiveElectrode"]["CurrentCollector"]["density"]

		sys_pecc = CurrentCollector(pecc_params)

		model_pecc = setup_component(grid, sys_pecc,
			general_ad = general_ad; kwargs...)
	end

	#######################
	# Setup control model #
	#######################

	controlPolicy = jsondict["Control"]["controlPolicy"]
	use_ramp_up = jsondict["TimeStepping"]["useRampup"]

	if controlPolicy == "CCDischarge" || controlPolicy == "CCCharge" || controlPolicy == "CCCycling"
		ctrl = jsondict["Control"]
		if jsondict["Control"]["useCVswitch"]

			policy = SimpleCVPolicy()
		else
			if haskey(ctrl, "initialControl")
				initial_control = ctrl["initialControl"]
			else
				if controlPolicy == "CCDischarge"
					initial_control = "discharging"
				else
					initial_control = "charging"
				end
			end
			if haskey(ctrl, "numberOfCycles")
				number_of_cycles = ctrl["numberOfCycles"]
			else
				if controlPolicy == "CCDischarge" || controlPolicy == "CCCharge"
					number_of_cycles = 0
				else
					error("CCCycling parameters miss numberOfcycles")
				end
			end
			policy = CCPolicy(number_of_cycles,
				initial_control,
				ctrl["lowerCutoffVoltage"],
				ctrl["upperCutoffVoltage"],
				use_ramp_up,
				T = T
			)
		end

	elseif controlPolicy == "CCCV"

		ctrl = jsondict["Control"]

		policy = CyclingCVPolicy(ctrl["lowerCutoffVoltage"],
			ctrl["upperCutoffVoltage"],
			ctrl["dIdtLimit"],
			ctrl["dEdtLimit"],
			ctrl["initialControl"],
			ctrl["numberOfCycles"];
			use_ramp_up = use_ramp_up)

	elseif controlPolicy == "Function"

		ctrl = jsondict["Control"]
		function_name = ctrl["functionName"]

		policy = FunctionPolicy(function_name)

	else

		error("controlPolicy not recognized.")

	end

	sys_control    = CurrentAndVoltageSystem(policy)
	domain_control = CurrentAndVoltageDomain()
	model_control  = SimulationModel(domain_control, sys_control; kwargs...)

	#####################
	# Setup multi-model #
	#####################

	if !include_cc
		groups = nothing
		model = MultiModel(
			(
				NeAm    = model_neam,
				Elyte   = model_elyte,
				PeAm    = model_peam,
				Control = model_control,
			),
			Val(:Battery);
			groups = groups)
	else
		models = (
			NeCc    = model_necc,
			NeAm    = model_neam,
			Elyte   = model_elyte,
			PeAm    = model_peam,
			PeCc    = model_pecc,
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

	setup_volume_fractions!(model, grids, couplings["Electrolyte"])

	output = (model     = model,
		couplings = couplings,
		grids     = grids)

	return output

end

#################################################################
# Setup grids and coupling for the given geometrical parameters #
#################################################################

function setup_grids_and_couplings(inputparams::InputParams)


	case_type = inputparams["Geometry"]["case"]

	if case_type == "1D"

		grids, couplings = one_dimensional_grid(inputparams)

	elseif case_type == "3D-demo"

		grids, couplings = pouch_grid(inputparams)

	else

		error("geometry case type not recognized")

	end

	return grids, couplings

end

function setup_component(grid::FiniteVolumeMesh,
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

############################
# Setup battery parameters #
############################

function setup_battery_parameters(inputparams::InputParams,
	model::MultiModel,
)

	function computeEffectiveConductivity(comodel, coinputparams)

		# Compute effective conductivity for the coating

		# First we compute the intrinsic conductivity as volume weight average of the subcomponents
		am = "ActiveMaterial"
		bd = "Binder"
		ad = "ConductingAdditive"

		compnames = [am, bd, ad]

		vfs = comodel.system.params[:volume_fractions]
		kappa = 0
		for icomp in eachindex(compnames)
			compname = compnames[icomp]
			vf = vfs[icomp]
			kappa += vf * coinputparams[compname]["electronicConductivity"]
		end

		vf = comodel.system.params[:volume_fraction]
		bg = coinputparams["bruggemanCoefficient"]

		kappaeff = (vf^bg) * kappa

		return kappaeff

	end

	parameters = Dict{Symbol, Any}()

	T0 = inputparams["initT"]

	include_cc = include_current_collectors(model)

	if include_cc

		#######################################
		# Negative current collector (if any) #
		#######################################

		prm_necc = Dict{Symbol, Any}()
		inputparams_necc = inputparams["NegativeElectrode"]["CurrentCollector"]
		prm_necc[:Conductivity] = inputparams_necc["electronicConductivity"]
		parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)

	end

	############################
	# Negative active material #
	############################

	prm_neam = Dict{Symbol, Any}()
	inputparams_neam = inputparams["NegativeElectrode"]["Coating"]["ActiveMaterial"]

	prm_neam[:Conductivity] = computeEffectiveConductivity(model[:NeAm], inputparams["NegativeElectrode"]["Coating"])
	prm_neam[:Temperature] = T0

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_neam[:Diffusivity] = inputparams_neam["InterDiffusionCoefficient"]
	end

	parameters[:NeAm] = setup_parameters(model[:NeAm], prm_neam)

	###############
	# Electrolyte #
	###############

	prm_elyte = Dict{Symbol, Any}()
	prm_elyte[:Temperature] = T0
	prm_elyte[:BruggemanCoefficient] = inputparams["Electrolyte"]["bruggemanCoefficient"]


	parameters[:Elyte] = setup_parameters(model[:Elyte], prm_elyte)

	############################
	# Positive active material #
	############################

	prm_peam = Dict{Symbol, Any}()
	inputparams_peam = inputparams["PositiveElectrode"]["Coating"]["ActiveMaterial"]

	prm_peam[:Conductivity] = computeEffectiveConductivity(model[:PeAm], inputparams["PositiveElectrode"]["Coating"])
	prm_peam[:Temperature] = T0


	if discretisation_type(model[:PeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_peam[:Diffusivity] = inputparams_peam["InterDiffusionCoefficient"]
	end

	parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

	if include_cc

		#######################################
		# Positive current collector (if any) #
		#######################################

		prm_pecc = Dict{Symbol, Any}()
		inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]
		prm_pecc[:Conductivity] = inputparams_pecc["electronicConductivity"]

		parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
	end

	###########
	# Control #
	###########

	prm_control = Dict{Symbol, Any}()

	controlPolicy = inputparams["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge"

		cap = computeCellCapacity(model)
		con = Constants()

		DRate = inputparams["Control"]["DRate"]

		prm_control[:ImaxDischarge] = (cap / con.hour) * DRate


		parameters[:Control] = setup_parameters(model[:Control], prm_control)


	elseif controlPolicy == "CCCharge"
		cap = computeCellCapacity(model)
		con = Constants()

		CRate = inputparams["Control"]["CRate"]

		prm_control[:ImaxCharge] = (cap / con.hour) * CRate

		parameters[:Control] = setup_parameters(model[:Control], prm_control)

	elseif controlPolicy == "Function"
		cap = computeCellCapacity(model)
		con = Constants()
		parameters[:Control] = setup_parameters(model[:Control])

	elseif controlPolicy == "CCCV" || controlPolicy == "CCCycling"

		cap = computeCellCapacity(model)
		con = Constants()

		DRate                       = inputparams["Control"]["DRate"]
		CRate                       = inputparams["Control"]["CRate"]
		prm_control[:ImaxDischarge] = (cap / con.hour) * DRate
		prm_control[:ImaxCharge]    = (cap / con.hour) * CRate


		parameters[:Control] = setup_parameters(model[:Control], prm_control)

	else
		error("control policy $controlPolicy not recognized")
	end

	return parameters

end

#######################
# Setup initial state #
#######################

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

##################
# Setup coupling #
##################

function setup_coupling_cross_terms!(inputparams::InputParams,
	model::MultiModel,
	parameters::Dict{Symbol, <:Any},
	couplings)

	include_cc = inputparams["include_current_collectors"]


	stringNames = Dict(:NeCc => "NegativeCurrentCollector",
		:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode",
		:PeCc => "PositiveCurrentCollector")

	#################################
	# Setup coupling NeAm <-> Elyte #
	#################################

	srange = collect(couplings["NegativeElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["NegativeElectrode"]["cells"]) # electrolyte (negative side)

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

		if model[:NeAm] isa SEImodel
			ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :sei_mass_cons)
			add_cross_term!(model, ct_pair)
			ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :sei_voltage_drop)
			add_cross_term!(model, ct_pair)
		end

	else

		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	#################################
	# setup coupling Elyte <-> PeAm #
	#################################

	srange = collect(couplings["PositiveElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["PositiveElectrode"]["cells"])

	if discretisation_type(model[:PeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:PeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	if include_cc

		################################
		# Setup coupling NeCc <-> NeAm #
		################################

		#Ncc  = geomparams[:NeCc][:N]

		srange_cells = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["cells"])
		trange_cells = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["cells"])

		srange_faces = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["faces"])
		trange_faces = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["faces"])

		msource = model[:NeCc]
		mtarget = model[:NeAm]

		psource = parameters[:NeCc]
		ptarget = parameters[:NeAm]

		# Here, the indexing in BoundaryFaces is used
		couplingfaces = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingfaces[:, 1] = srange_faces
		couplingfaces[:, 2] = trange_faces

		couplingcells = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingcells[:, 1] = srange_cells
		couplingcells[:, 2] = trange_cells

		trans = getTrans(msource, mtarget,
			couplingfaces,
			couplingcells,
			psource, ptarget,
			:Conductivity)
		@assert size(trans, 1) == size(srange_cells, 1)
		ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :NeCc, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		################################
		# setup coupling PeCc <-> PeAm #
		################################

		#Npam  = geomparams[:PeAm][:N]

		srange_cells = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["cells"])
		trange_cells = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["cells"])

		srange_faces = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["faces"])
		trange_faces = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["faces"])

		msource = model[:PeCc]
		mtarget = model[:PeAm]

		psource = parameters[:PeCc]
		ptarget = parameters[:PeAm]

		# Here, the indexing in BoundaryFaces is used
		couplingfaces = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingfaces[:, 1] = srange_faces
		couplingfaces[:, 2] = trange_faces


		couplingcells = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingcells[:, 1] = srange_cells
		couplingcells[:, 2] = trange_cells

		trans = getTrans(msource, mtarget,
			couplingfaces,
			couplingcells,
			psource, ptarget,
			:Conductivity)
		@assert size(trans, 1) == size(srange_cells, 1)
		ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :PeCc, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

	end

	########################################
	# setup coupling PeCc/NeAm <-> control #
	########################################

	if include_cc
		controlComp = :PeCc
	else
		controlComp = :PeAm
	end

	stringControlComp = stringNames[controlComp]

	trange = couplings[stringControlComp]["External"]["cells"]
	srange = Int64.(ones(size(trange)))

	msource     = model[controlComp]
	mparameters = parameters[controlComp]

	# Here the indexing in BoundaryFaces in used
	couplingfaces = couplings[stringControlComp]["External"]["boundaryfaces"]
	couplingcells = trange
	trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

	ct = TPFAInterfaceFluxCT(trange, srange, trans)
	ct_pair = setup_cross_term(ct, target = controlComp, source = :Control, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)

	ct = AccumulatorInterfaceFluxCT(1, trange, trans)
	ct_pair = setup_cross_term(ct, target = :Control, source = controlComp, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)

	ct1 = AccumulatorInterfaceFluxCT(1, trange, trans * 0.0)
	ct1_pair = setup_cross_term(ct1, target = :Control, source = controlComp, equation = :control)
	add_cross_term!(model, ct1_pair)


end

##################
# Setup scalings #
##################

function get_scalings(model, parameters)

	refT = 298.15

	electrolyte = model[:Elyte].system

	eldes = (:NeAm, :PeAm)

	j0s   = Array{Float64}(undef, 2)
	Rvols = Array{Float64}(undef, 2)

	F = FARADAY_CONSTANT

	for (i, elde) in enumerate(eldes)

		rate_func = model[elde].system.params[:reaction_rate_constant_func]
		cmax      = model[elde].system[:maximum_concentration]
		vsa       = model[elde].system[:volumetric_surface_area]

		c_a            = 0.5 * cmax
		R0             = rate_func(c_a, refT)
		c_e            = 1000.0
		activematerial = model[elde].system

		j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial)
		Rvols[i] = j0s[i] * vsa / F

	end

	j0Ref   = mean(j0s)
	RvolRef = mean(Rvols)

	if include_current_collectors(model)
		component_names = (:NeCc, :NeAm, :Elyte, :PeAm, :PeCc)
		cc_mapping      = Dict(:NeAm => :NeCc, :PeAm => :PeCc)
	else
		component_names = (:NeAm, :Elyte, :PeAm)
	end

	volRefs = Dict()

	for name in component_names

		rep = model[name].domain.representation
		if rep isa MinimalECTPFAGrid
			volRefs[name] = mean(rep.volumes)
		else
			volRefs[name] = mean(rep[:volumes])
		end

	end

	scalings = []

	scaling = (model_label = :Elyte, equation_label = :charge_conservation, value = F * volRefs[:Elyte] * RvolRef)
	push!(scalings, scaling)

	scaling = (model_label = :Elyte, equation_label = :mass_conservation, value = volRefs[:Elyte] * RvolRef)
	push!(scalings, scaling)

	for elde in eldes

		scaling = (model_label = elde, equation_label = :charge_conservation, value = F * volRefs[elde] * RvolRef)
		push!(scalings, scaling)

		if include_current_collectors(model)

			# We use the same scaling as for the coating multiplied by the conductivity ration
			cc = cc_mapping[elde]
			coef = parameters[cc][:Conductivity] / parameters[elde][:Conductivity]

			scaling = (model_label = cc, equation_label = :charge_conservation, value = F * coef[1] * volRefs[elde] * RvolRef)
			push!(scalings, scaling)

		end

		rp   = model[elde].system.discretization[:rp]
		volp = 4 / 3 * pi * rp^3

		coef = RvolRef * volp

		scaling = (model_label = elde, equation_label = :mass_conservation, value = coef)
		push!(scalings, scaling)
		scaling = (model_label = elde, equation_label = :solid_diffusion_bc, value = coef)
		push!(scalings, scaling)

		if model[elde] isa SEImodel

			vsa = model[elde].system[:volumetric_surface_area]
			L   = model[elde].system[:SEIlengthInitial]
			k   = model[elde].system[:SEIionicConductivity]

			SEIvoltageDropRef = F * RvolRef / vsa * L / k

			scaling = (model_label = elde, equation_label = :sei_voltage_drop, value = SEIvoltageDropRef)
			push!(scalings, scaling)

			De = model[elde].system[:SEIelectronicDiffusionCoefficient]
			ce = model[elde].system[:SEIintersticialConcentration]

			scaling = (model_label = elde, equation_label = :sei_mass_cons, value = De * ce / L)
			push!(scalings, scaling)

		end

	end

	return scalings

end

######################
# Setup timestepping #
######################

function setup_timesteps(inputparams::InputParams;
	kwargs...)
	"""
		Method setting up the timesteps from a json file object. 
	"""

	controlPolicy = inputparams["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge" || controlPolicy == "CCCharge"

		if controlPolicy == "CCDischarge"
			CRate = inputparams["Control"]["DRate"]
		else
			CRate = inputparams["Control"]["CRate"]
		end

		con = Constants()
		totalTime = 1.1 * con.hour / CRate

		if haskey(inputparams["TimeStepping"], "totalTime") && !isnothing(inputparams["TimeStepping"]["totalTime"])
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

	elseif controlPolicy == "CCCycling"

		ncycles = inputparams["Control"]["numberOfCycles"]
		DRate = inputparams["Control"]["DRate"]
		CRate = inputparams["Control"]["CRate"]

		con = Constants()

		totalTime = ncycles * 2 * (1 * con.hour / CRate + 1 * con.hour / DRate)


		if haskey(inputparams["TimeStepping"], "totalTime") && !isnothing(inputparams["TimeStepping"]["totalTime"])
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

	elseif controlPolicy == "CCCV"

		ncycles = inputparams["Control"]["numberOfCycles"]
		DRate = inputparams["Control"]["DRate"]
		CRate = inputparams["Control"]["CRate"]

		con = Constants()

		totalTime = ncycles * 2.5 * (1 * con.hour / CRate + 1 * con.hour / DRate)

		if haskey(inputparams["TimeStepping"], "totalTime") && !isnothing(inputparams["TimeStepping"]["totalTime"])
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

	elseif controlPolicy == "Function"
		totalTime = inputparams["TimeStepping"]["totalTime"]
		dt = inputparams["TimeStepping"]["timeStepDuration"]
		n = totalTime / dt
		timesteps = repeat([dt], Int64(floor(n)))

	else

		error("Control policy $controlPolicy not recognized")

	end

	return timesteps
end

######################################
# Setup solver configuration options #
######################################

"""
	setup_config(sim::JutulSimulator,
					  model::MultiModel        ,
					  linear_solver::Symbol    ,
					  extra_timing::Bool;
					  kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function setup_config(sim::JutulSimulator,
	model::MultiModel,
	parameters,
	linear_solver::Symbol,
	extra_timing::Bool,
	use_model_scaling::Bool;
	kwargs...)

	cfg = simulator_config(sim; kwargs...)

	cfg[:linear_solver]            = battery_linsolve(model, linear_solver)
	cfg[:debug_level]              = 0
	cfg[:max_timestep_cuts]        = 10
	cfg[:max_residual]             = 1e20
	cfg[:output_substates]         = true
	cfg[:min_nonlinear_iterations] = 1
	cfg[:extra_timing]             = extra_timing
	# cfg[:max_nonlinear_iterations] = 5
	cfg[:safe_mode]             = true
	cfg[:error_on_incomplete]   = false
	cfg[:failure_cuts_timestep] = true

	if use_model_scaling
		scalings = get_scalings(model, parameters)
		tol_default = 1e-5
		for scaling in scalings
			model_label = scaling[:model_label]
			equation_label = scaling[:equation_label]
			value = scaling[:value]
			cfg[:tolerances][model_label][equation_label] = value * tol_default
		end
	else
		for key in submodels_symbols(model)
			cfg[:tolerances][key][:default] = 1e-5
		end
	end

	if model[:Control].system.policy isa CyclingCVPolicy || model[:Control].system.policy isa CCPolicy
		if model[:Control].system.policy isa CyclingCVPolicy

			cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)

		elseif model[:Control].system.policy isa CCPolicy && model[:Control].system.policy.numberOfCycles > 0
			cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)
		end

		function post_hook(done, report, sim, dt, forces, max_iter, cfg)

			s = get_simulator_storage(sim)
			m = get_simulator_model(sim)

			if model[:Control].system.policy isa CyclingCVPolicy

				if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
					report[:stopnow] = true
				else
					report[:stopnow] = false
				end

			elseif model[:Control].system.policy isa CCPolicy

				if m[:Control].system.policy.numberOfCycles == 0

					if m[:Control].system.policy.initialControl == "charging"

						if s.state.Control.Phi[1] >= m[:Control].system.policy.upperCutoffVoltage
							report[:stopnow] = true
						else
							report[:stopnow] = false
						end

					elseif m[:Control].system.policy.initialControl == "discharging"

						if s.state.Control.Phi[1] <= m[:Control].system.policy.lowerCutoffVoltage
							report[:stopnow] = true

						else

							report[:stopnow] = false
						end
					end
				else
					if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
						report[:stopnow] = true
					else
						report[:stopnow] = false
					end
				end
			end

			return (done, report)

		end

		cfg[:post_ministep_hook] = post_hook


	end


	return cfg

end


####################
# Current function #
####################

function currentFun(t::Real, inputI::Real, tup::Real = 0.1)
	t, inputI, tup, val = promote(t, inputI, tup, 0.0)
	if t <= tup
		val = sineup(0.0, inputI, 0.0, tup, t)
	else
		val = inputI
	end
	return val
end

#########################
# Setup volume fraction # 
#########################

function setup_volume_fractions!(model::MultiModel, grids, coupling)

	Nelyte      = number_of_cells(grids["Electrolyte"])

	names = [:NeAm, :PeAm]
	stringNames = Dict(:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode")

	vfracs = map(name -> model[name].system[:volume_fraction], names)
	T = Base.promote_type(map(typeof, vfracs)...)

	vfelyte     = zeros(T, Nelyte)
	vfseparator = zeros(T, Nelyte)

	for (i, name) in enumerate(names)
		stringName = stringNames[name]
		ncell = number_of_cells(grids[stringName])
		ammodel = model[name]
		vf = vfracs[i]
		ammodel.domain.representation[:volumeFraction] = vf * ones(ncell)
		elytecells = coupling[stringName]["cells"]
		vfelyte[elytecells] .= 1 - vf
	end

	separator_porosity = model[:Elyte].system[:separator_porosity]
	elytecells         = coupling["Separator"]["cells"]

	vfelyte[elytecells]     .= separator_porosity * ones()
	vfseparator[elytecells] .= (1 - separator_porosity)

	model[:Elyte].domain.representation[:volumeFraction] = vfelyte
	model[:Elyte].domain.representation[:separator_volume_fraction] = vfseparator

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


#############
# Utilities #
#############

function include_current_collectors(inputparams::InputParams)

	jsondict = inputparams.all

	if haskey(jsondict, "include_current_collectors") && !jsondict["include_current_collectors"]
		include_cc = false
	else
		include_cc = true
	end

	return include_cc

end

function include_current_collectors(model)

	if haskey(model.models, :NeCc)
		include_cc = true
		@assert haskey(model.models, :PeCc)
	else
		include_cc = false
		@assert !haskey(model.models, :PeCc)
	end

	return include_cc

end

function rampupTimesteps(time::Real, dt::Real, n::Integer = 8)

	ind = collect(range(n, 1, step = -1))
	dt_init = [dt / 2^k for k in ind]
	cs_time = cumsum(dt_init)
	if any(cs_time .> time)
		dt_init = dt_init[cs_time.<time]
	end
	dt_left = time .- sum(dt_init)

	# Even steps
	dt_rem = dt * ones(floor(Int64, dt_left / dt))
	# Final ministep if present
	dt_final = time - sum(dt_init) - sum(dt_rem)
	# Less than to account for rounding errors leading to a very small
	# negative time-step.
	if dt_final <= 0
		dt_final = []
	end
	# Combined timesteps
	dT = [dt_init; dt_rem; dt_final]

	return dT
end


struct SourceAtCell
	cell::Any
	src::Any
	function SourceAtCell(cell, src)
		new(cell, src)
	end
end

function convert_to_int_vector(x::Float64)
	vec = Int64.(Vector{Float64}([x]))
	return vec
end

function convert_to_int_vector(x::Matrix{Float64})
	vec = Int64.(Vector{Float64}(x[:, 1]))
	return vec
end

function amg_precond(; max_levels = 10, max_coarse = 10, type = :smoothed_aggregation)

	gs_its = 1
	cyc = AlgebraicMultigrid.V()
	if type == :smoothed_aggregation
		m = smoothed_aggregation
	else
		m = ruge_stuben
	end
	gs = GaussSeidel(ForwardSweep(), gs_its)

	return AMGPreconditioner(m, max_levels = max_levels, max_coarse = max_coarse, presmoother = gs, postsmoother = gs, cycle = cyc)

end



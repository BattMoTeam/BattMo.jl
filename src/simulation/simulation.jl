export Simulation
export solve
export get_simulation_input

"""
	abstract type AbstractSimulation

Abstract type for Simulation structs. Subtypes of `AbstractSimulation` represent specific simulation configurations.
"""
abstract type AbstractSimulation end


"""
	struct Simulation <: AbstractSimulation

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
struct Simulation <: AbstractSimulation
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
function solve(problem::Simulation; accept_invalid = false, hook = nothing, info_level = 0, end_report = info_level > -1, kwargs...)

	config_kwargs = (info_level = info_level, end_report = end_report)

	use_p2d = true

	# Note: Typically function_to_solve is run_battery
	if accept_invalid == true
		output = problem.function_to_solve(problem.model_setup, problem.cell_parameters, problem.cycling_protocol, problem.simulation_settings;
			hook,
			use_p2d = use_p2d,
			config_kwargs = config_kwargs,
			kwargs...)
	else
		if problem.is_valid == true
			output = problem.function_to_solve(problem.model_setup, problem.cell_parameters, problem.cycling_protocol, problem.simulation_settings;
				hook,
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


####################
# Setup simulation #
####################

function get_simulation_input(problem::Simulation; kwargs...)

	inputparams = convert_parameter_sets_to_old_input_format(problem.model_setup.model_settings,
		problem.cell_parameters,
		problem.cycling_protocol,
		problem.simulation_settings)

	output = get_simulation_input(inputparams; kwargs...)

end

function get_simulation_input(inputparams::BattMoFormattedInput;
	use_p2d::Bool                     = true,
	use_model_scaling::Bool           = true,
	extra_timing::Bool                = false,
	max_step::Union{Integer, Nothing} = nothing,
	general_ad::Bool                  = true,
	use_groups::Bool                  = false,
	model_kwargs::NamedTuple          = NamedTuple(),
	config_kwargs::NamedTuple         = NamedTuple())

	model, parameters, couplings = setup_model(inputparams;
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
		parameters;
		inputparams,
		extra_timing,
		use_model_scaling,
		config_kwargs...)


	grids = get_grids(model)

	output = Dict(:simulator   => simulator,
		:forces      => forces,
		:state0      => state0,
		:parameters  => parameters,
		:inputparams => inputparams,
		:model       => model,
		:couplings   => couplings,
		:grids       => grids,
		:timesteps   => timesteps,
		:cfg         => cfg)

	return output

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


######################################
# Setup solver configuration options #
######################################

"""
	setup_config(sim::JutulSimulator,
					  model::MultiModel,
					  parameters;
					  inputparams::BattMoFormattedInput,
					  extra_timing::Bool,
					  use_model_scaling,
					  kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function setup_config(sim::JutulSimulator,
	model::MultiModel,
	parameters;
	inputparams::BattMoFormattedInput = InputParams(),
	extra_timing::Bool = false,
	use_model_scaling::Bool = true,
	kwargs...)

	cfg = simulator_config(sim; kwargs...)

	set_default_input_params!(inputparams, ["NonLinearSolver", "maxTimestepCuts"], 10)
	set_default_input_params!(inputparams, ["NonLinearSolver", "maxIterations"], 20)
	set_default_input_params!(inputparams, ["NonLinearSolver", "LinearSolver"], Dict())

	cfg[:linear_solver]            = battery_linsolve(inputparams["NonLinearSolver"]["LinearSolver"])
	cfg[:debug_level]              = 0
	cfg[:max_timestep_cuts]        = inputparams["NonLinearSolver"]["maxTimestepCuts"]
	cfg[:max_residual]             = 1e20
	cfg[:output_substates]         = true
	cfg[:min_nonlinear_iterations] = 1
	cfg[:extra_timing]             = extra_timing
	cfg[:max_nonlinear_iterations] = inputparams["NonLinearSolver"]["maxIterations"]
	cfg[:safe_mode]                = true
	cfg[:error_on_incomplete]      = false
	cfg[:failure_cuts_timestep]    = true

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

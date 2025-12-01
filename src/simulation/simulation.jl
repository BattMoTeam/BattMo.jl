export Simulation
export solve
export setup_config

"""
	abstract type AbstractSimulation

Abstract type for Simulation structs. Subtypes of `AbstractSimulation` represent specific simulation configurations.
"""
abstract type AbstractSimulation end


"""
	Simulation(model::ModelConfigured, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol; simulation_settings::SimulationSettings = get_default_simulation_settings(model))

Constructs a `Simulation` object that sets up and validates all necessary components for simulating a battery model.

# Arguments
- `model::ModelConfigured`: A fully configured model object that includes the physical and numerical setup.
- `cell_parameters::CellParameters`: Parameters defining the physical characteristics of the battery cell.
- `cycling_protocol::CyclingProtocol`: The protocol specifying the charging/discharging cycles for the simulation.
- `simulation_settings::SimulationSettings` (optional): Configuration settings controlling solver behavior, time stepping, etc. If not provided, default settings are generated based on the model.

# Behavior
- Validates `model`, `cell_parameters`, `cycling_protocol`, and `simulation_settings`.
- Sets up default solver options if not explicitly defined.
- Initializes computational grids and couplings.
- Configures the physical model and parameters.
- Prepares the initial simulation state and external forcing functions.
- Instantiates a `Simulator` from the Jutul framework with the prepared state and parameters.
- Defines the time-stepping strategy for the simulation.
- Assembles a simulation configuration object used to control execution.

# Returns
A `Simulation` struct instance that includes:
- Validation flag (`is_valid`)
- Prepared simulation components: model, grids, couplings, parameters, initial state, forces, time steps, and simulator instance.

# Throws
- An error if `model.is_valid == false`, halting construction with a helpful message.

"""
struct Simulation <: AbstractSimulation
	is_valid::Bool
	model::ModelConfigured
	cell_parameters::CellParameters
	cycling_protocol::CyclingProtocol
	settings::SimulationSettings
	time_steps::Any
	forces::Any
	initial_state::Any
	grids::Any
	couplings::Any
	parameters::Any
	simulator::Any
	termination_criterion::Union{AbstractTerminationCriterion, Nothing}
	jutul_case::Any


	function Simulation(
		model::M,
		cell_parameters::CellParameters,
		cycling_protocol::CyclingProtocol;
		simulation_settings::SimulationSettings = get_default_simulation_settings(model),
		hook = nothing,
		kwargs...,
	) where {M <: ModelConfigured}

		if model.is_valid

			# Here will come a validation function
			model_settings = model.settings
			cell_parameters_is_valid = validate_parameter_set(cell_parameters, model_settings)
			cycling_protocol_is_valid = validate_parameter_set(cycling_protocol, model_settings)
			simulation_settings_is_valid = validate_parameter_set(simulation_settings, model_settings)

			if cell_parameters_is_valid && cycling_protocol_is_valid && simulation_settings_is_valid
				is_valid = true

			else
				is_valid = false
			end

			# Combine the parameter sets and settings
			input = (model_settings = model_settings,
				cell_parameters = cell_parameters,
				cycling_protocol = cycling_protocol,
				simulation_settings = simulation_settings,
			)

			try
				# Run configuration with all warnings and errors silenced
				sim_cfg = Logging.with_logger(Logging.NullLogger()) do
					simulation_configuration(model, input)
				end

				model = sim_cfg.model
				grids = sim_cfg.grids
				couplings = sim_cfg.couplings
				parameters = sim_cfg.parameters
				initial_state = sim_cfg.initial_state
				forces = sim_cfg.forces
				simulator = sim_cfg.simulator
				time_steps = sim_cfg.time_steps
				termination_criterion = sim_cfg.termination_criterion
				jutul_case = sim_cfg.jutul_case

				return new{}(is_valid, model, cell_parameters, cycling_protocol, simulation_settings, time_steps, forces, initial_state, grids, couplings, parameters, simulator, termination_criterion, jutul_case)
			catch e
				if is_valid == false
					error(
						"""
						  Oops! Your Simulation object cannot be configured because some of you input is not valid. 🛑

						  Check the warnings to see where things went wrong. 🔍

						  """,
					)
				else
					rethrow(e)
				end
			end

		else
			error("""
			Oops! Your Model object is not valid. 🛑

			TIP: Validation happens when instantiating the Model object. 
			Check the warnings to see exactly where things went wrong. 🔍

			""")
		end

	end
end


function simulation_configuration(model, input)

	# Setup grids and couplings
	grids, couplings = setup_grids_and_couplings(model, input)

	# Setup simulation
	model, parameters = setup_model!(model, input, grids, couplings)

	# setup initial state
	initial_state = setup_initial_state(input, model)

	# setup forces
	forces = setup_forces(model.multimodel)

	# setup jutul simulator
	simulator = Simulator(model.multimodel; state0 = initial_state, parameters = parameters, copy_state = true)

	# setup time steps
	time_steps = Float64.(setup_timesteps(input))

	# setup termination criterion
	termination_criterion = setup_termination_criterion(model.multimodel)

	# setup jutul case
	if isnothing(termination_criterion)
		jutul_case = JutulCase(model.multimodel, time_steps, forces; parameters = parameters, state0 = initial_state)
	else
		jutul_case = JutulCase(model.multimodel, time_steps, forces; parameters = parameters, state0 = initial_state, termination_criterion = termination_criterion)
	end

	return (
		model = model,
		grids = grids,
		couplings = couplings,
		parameters = parameters,
		initial_state = initial_state,
		forces = forces,
		simulator = simulator,
		time_steps = time_steps,
		termination_criterion = termination_criterion,
		jutul_case = jutul_case,
	)

end


function setup_termination_criterion(multimodel)

	if multimodel[:Control].system.policy isa CyclingCVPolicy

		termination_criterion = CycleIndexTermination(multimodel[:Control].system.policy.numberOfCycles)

	elseif multimodel[:Control].system.policy isa CCPolicy

		if multimodel[:Control].system.policy.numberOfCycles == 0
			direction = multimodel[:Control].system.policy.initialControl
			tol = 1e-4

			if multimodel[:Control].system.policy.initialControl == "charging"

				termination_criterion = VoltageTermination(multimodel[:Control].system.policy.upperCutoffVoltage, direction, tol)

			elseif multimodel[:Control].system.policy.initialControl == "discharging"

				termination_criterion = VoltageTermination(multimodel[:Control].system.policy.lowerCutoffVoltage, direction, tol)

			end
		else
			termination_criterion = CycleIndexTermination(multimodel[:Control].system.policy.numberOfCycles)

		end
	elseif multimodel[:Control].system.policy isa GenericProtocol
		termination_criterion = ControlStepIndexTermination(length(multimodel[:Control].system.policy.steps))

	elseif multimodel[:Control].system.policy isa FunctionPolicy
		termination_criterion = nothing

	else
		error("Unknown control policy")
	end
	return termination_criterion
end

#########
# Solve #
#########

"""
	solve(problem::Simulation; accept_invalid = false, hook = nothing, info_level = 0, end_report = info_level > -1, kwargs...)

Solves a battery `Simulation` problem by executing the simulation workflow defined in `solve_simulation`.

# Arguments
- `problem::Simulation`: A fully constructed `Simulation` object, containing all model parameters, solver settings, and initial conditions.
- `accept_invalid::Bool` (optional): If `true`, bypasses the internal validation check on the `Simulation` object. Use with caution. Default is `false`.
- `hook` (optional): A user-defined callback or observer function that can be inserted into the simulation loop.
- `info_level::Int` (optional): Controls verbosity of simulation logging and output. Default is `0`.
- `end_report::Bool` (optional): Whether to print a summary report after simulation. Defaults to `true` if `info_level > -1`.
- `kwargs...`: Additional keyword arguments forwarded to `solve_simulation`.

# Behavior
- Validates the `Simulation` object unless `accept_invalid` is `true`.
- Prepares simulation configuration options, including verbosity and report behavior.
- Calls `solve_simulation`, passing in the simulation problem and configuration.

# Returns
- The result of `solve_simulation`, typically containing simulation outputs such as state trajectories, solver diagnostics, and performance metrics.

# Throws
- An error if the `Simulation` object is invalid and `accept_invalid` is not set to `true`.

# Example
```julia
sim = Simulation(model, cell_parameters, cycling_protocol)
result = solve(sim; info_level = 1)
```
"""
function solve(problem::Simulation; accept_invalid = false, solver_settings = get_default_solver_settings(problem.model), logger = nothing, kwargs...)


	# Note: Typically function_to_solve is run_battery
	if accept_invalid == true
		output = solve_simulation(problem; solver_settings, logger, kwargs...)
	else
		if problem.is_valid == true
			output = solve_simulation(problem; solver_settings, logger, kwargs...)

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


"""
	solve_simulation(sim::Simulation; hook = nothing, use_p2d = true, kwargs...)

Executes the simulation workflow for a battery `Simulation` object by advancing the system state over the defined time steps using the configured solver and model.

# Arguments
- `sim::Simulation`: A `Simulation` instance containing all preconfigured simulation components including model, state, solver, time steps, and settings.
- `hook` (optional): A user-supplied callback function to be invoked *before* the simulation begins. Useful for modifying or logging internal simulation structures (e.g., for debugging, monitoring, or visualization).
- `use_p2d::Bool` (optional): Currently unused placeholder; included for compatibility or future extensions. Default is `true`.
- `kwargs...`: Additional keyword arguments passed to the lower-level solver configuration.

# Behavior
- Extracts all relevant simulation components from the `Simulation` object.
- Optionally invokes a user-defined `hook` function with simulation internals.
- Calls the `simulate` function to perform time integration across defined time steps.
- Constructs a set of metadata dictionaries for downstream analysis or inspection.

# Returns
A named tuple with the following fields:
- `states`: The computed simulation states over all time steps.
- `cellSpecifications`: Cell-level metrics computed from the final model state.
- `reports`: Simulation logs and diagnostics generated during execution.
- `input`: A dictionary of the original input settings used in the simulation.
- `extra`: A dictionary containing internal simulation structures such as:
  - Simulator, initial state, parameters
  - Grids and couplings
  - Time steps and configuration
  - Model, cell parameters, cycling protocol

# Example
```julia
result = solve_simulation(sim)
```
"""
function solve_simulation(sim::Union{Simulation, NamedTuple}; solver_settings, logger = nothing, kwargs...)

	simulator = sim.simulator
	model = sim.model
	state0 = sim.initial_state
	forces = sim.forces
	timesteps = sim.time_steps
	termination_criterion = sim.termination_criterion
	grids = sim.grids
	couplings = sim.couplings
	parameters = sim.parameters
	simulation_settings = sim.settings
	cell_parameters = sim.cell_parameters
	cycling_protocol = sim.cycling_protocol
	jutul_case = sim.jutul_case


	# setup solver configuration
	cfg = solver_configuration(simulator,
		model.multimodel,
		parameters;
		solver_settings,
		logger,
		kwargs...,
	)

	# Setup hook if given
	hook = get(kwargs, :hook, nothing)
	if !isnothing(hook)
		hook(simulator,
			model.multimodel,
			initial_state,
			forces,
			time_steps,
			cfg)
	end



	# Perform simulation
	jutul_states, jutul_reports = simulate(jutul_case; config = cfg)
	# jutul_states, jutul_reports = simulate(state0, simulator, termination_criterion; forces = forces, config = cfg)

	jutul_output = (
		states = jutul_states,
		reports = jutul_reports,
		solver_configuration = cfg,
		multimodel = model.multimodel,
	)

	input = FullSimulationInput(
		Dict(
			"BaseModel" => string(nameof(typeof(model))),
			"ModelSettings" => model.settings.all,
			"CellParameters" => cell_parameters.all,
			"CyclingProtocol" => cycling_protocol.all,
			"SimulationSettings" => simulation_settings.all,
			"SolverSettings" => solver_settings.all),
	)

	time_series = get_output_time_series(jutul_output)
	states = get_output_states(jutul_output, input)
	metrics = get_output_metrics(jutul_output)


	return SimulationOutput(
		time_series,
		states,
		metrics,
		input,
		jutul_output,
		model,
		sim)

end

function overwrite_solver_settings_kwargs!(solver_settings; kwargs...)
	settings = kwarg_dict(; kwargs...)  # Convert kwargs to Dict

	# Initialize return variables as nothing
	linear_solver = nothing
	relaxation = nothing
	timestep_selectors = nothing

	for (dict_key, dict) in settings
		if !isnothing(dict) && !ismissing(dict)
			if dict_key == "LinearSolver"
				if isa(dict, Dict)
					solver_settings[dict_key] = dict
				else
					solver_settings[dict_key] = Dict("Method" => "UserDefined")
					linear_solver = dict
				end

			else

				for (key, value) in dict

					if !isnothing(value) && !ismissing(value)

						if key == :TimeStepSelectors
							if isa(value, String)
								solver_settings[dict_key][key] = value
							else
								solver_settings[dict_key][key] = "UserDefined"
								timestep_selectors = value
							end


						elseif key == :Relaxation
							if isa(value, String)
								solver_settings[dict_key][key] = value
							else
								solver_settings[dict_key][key] = "UserDefined"
								relaxation = value
							end


						else
							# Overwrite for all other keys
							solver_settings[dict_key][key] = value

						end
					end
				end

			end
		end

	end

	return (solver_settings = solver_settings,
		linear_solver = linear_solver,
		relaxation = relaxation,
		timestep_selectors = timestep_selectors)

end


function kwarg_dict(; kwargs...)
	kwarg_dict = Dict(
		"NonLinearSolver" => Dict(
			"MaxTimestepCuts" => get(kwargs, :max_timestep_cuts, nothing),
			"MaxTimestep" => get(kwargs, :max_timestep, nothing),
			"TimestepMaxIncrease" => get(kwargs, :timestep_max_increase, nothing),
			"TimestepMaxDecrease" => get(kwargs, :timestep_max_decrease, nothing),
			"MaxResidual" => get(kwargs, :max_residual, nothing),
			"MaxNonLinearIterations" => get(kwargs, :max_nonlinear_iterations, nothing),
			"MinNonLinearIterations" => get(kwargs, :min_nonlinear_iterations, nothing),
			"FailureCutsTimesteps" => get(kwargs, :failure_cuts_timestep, nothing),
			"CheckBeforeSolve" => get(kwargs, :check_before_solve, nothing),
			"AlwaysUpdateSecondary" => get(kwargs, :always_update_secondary, nothing),
			"ErrorOnIncomplete" => get(kwargs, :error_on_incomplete, nothing),
			"CuttingCriterion" => get(kwargs, :cutting_criterion, nothing),
			"Tolerances" => get(kwargs, :tolerances, nothing),
			"TolFactorFinalIteration" => get(kwargs, :tol_factor_final_iteration, nothing),
			"SafeMode" => get(kwargs, :safe_mode, nothing),
			"ExtraTiming" => get(kwargs, :extra_timing, nothing),
			"TimeStepSelectors" => get(kwargs, :timestep_selectors, nothing),
			"Relaxation" => get(kwargs, :relaxation, nothing),
		),
		"LinearSolver" => get(kwargs, :linear_solver, nothing),
		"Verbose" => Dict(
			"InfoLevel" => get(kwargs, :info_level, nothing),
			"DebugLevel" => get(kwargs, :debug_level, nothing),
			"EndReport" => get(kwargs, :end_report, nothing),
			"ASCIITerminal" => get(kwargs, :ascii_terminal, nothing),
			"ID" => get(kwargs, :id, nothing),
			"ProgressColor" => get(kwargs, :progress_color, nothing),
			"ProgressGlyphs" => get(kwargs, :progress_glyphs, nothing),
		),
		"Output" => Dict(
			"OutputPath" => get(kwargs, :output_path, nothing),
			"OutputStates" => get(kwargs, :output_states, nothing),
			"OutputReports" => get(kwargs, :output_reports, nothing),
			"InMemoryReports" => get(kwargs, :in_memory_reports, nothing),
			"ReportLevel" => get(kwargs, :report_level, nothing),
			"OutputSubstrates" => get(kwargs, :output_substates, nothing),
		))

	return kwarg_dict
end

function process_solver_settings_kwargs(solver_settings; kwargs...)


	# Validate solver settings
	solver_settings_is_valid = validate_parameter_set(solver_settings)
	return solver_settings_is_valid
end

######################################
# Setup solver configuration options #
######################################

"""
	setup_config(sim::JutulSimulator,
					  model::MultiModel,
					  parameters;
					  inputparams::AdvancedDictInput,
					  extra_timing::Bool,
					  use_model_scaling,
					  kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function solver_configuration(sim::JutulSimulator,
	model::MultiModel,
	parameters;
	use_model_scaling::Bool = true,
	solver_settings,
	logger = nothing,
	kwargs...)

	# Overwrite solver settings with kwargs
	overwritten_settings = overwrite_solver_settings_kwargs!(solver_settings; kwargs...)
	solver_settings = overwritten_settings.solver_settings

	# Validate solver settings
	solver_settings_is_valid = validate_parameter_set(solver_settings)


	non_linear_solver = solver_settings["NonLinearSolver"]
	linear_solver_dict = solver_settings["LinearSolver"]
	output = solver_settings["Output"]
	verbose = solver_settings["Verbose"]

	relaxation = non_linear_solver["Relaxation"]
	timestep_selector = non_linear_solver["TimeStepSelectors"]
	if relaxation == "NoRelaxation"
		relax = NoRelaxation()
	else
		relax = SimpleRelaxation()
	end

	if timestep_selector == "TimestepSelector"
		timesel = [TimestepSelector()]
	else
		timesel = timestep_selector
	end

	if linear_solver_dict["Method"] == "UserDefined"
		linear_solver = overwritten_settings.linear_solver
	else
		linear_solver = battery_linsolve(linear_solver_dict)

	end

	cfg = simulator_config(
		sim;
		info_level = verbose["InfoLevel"],
		debug_level = verbose["DebugLevel"],
		end_report = verbose["EndReport"],
		ascii_terminal = verbose["ASCIITerminal"],
		id = verbose["ID"],
		progress_color = Symbol(verbose["ProgressColor"]),
		progress_glyphs = Symbol(verbose["ProgressGlyphs"]),
		max_timestep_cuts = non_linear_solver["MaxTimestepCuts"],
		max_timestep = non_linear_solver["MaxTimestep"],
		timestep_max_increase = non_linear_solver["TimestepMaxIncrease"],
		timestep_max_decrease = non_linear_solver["TimestepMaxDecrease"],
		max_residual = non_linear_solver["MaxResidual"],
		max_nonlinear_iterations = non_linear_solver["MaxNonLinearIterations"],
		min_nonlinear_iterations = non_linear_solver["MinNonLinearIterations"],
		failure_cuts_timestep = non_linear_solver["FailureCutsTimesteps"],
		check_before_solve = non_linear_solver["CheckBeforeSolve"],
		always_update_secondary = non_linear_solver["AlwaysUpdateSecondary"],
		error_on_incomplete = non_linear_solver["ErrorOnIncomplete"],
		cutting_criterion = non_linear_solver["CuttingCriterion"],
		tol_factor_final_iteration = non_linear_solver["TolFactorFinalIteration"],
		safe_mode = non_linear_solver["SafeMode"],
		extra_timing = non_linear_solver["ExtraTiming"],
		linear_solver = linear_solver,
		relaxation = relax,
		timestep_selectors = timesel,
		output_states = output["OutputStates"],
		output_reports = output["OutputReports"],
		output_path = output["OutputPath"] == "" ? nothing : output["OutputPath"],
		in_memory_reports = output["InMemoryReports"],
		report_level = output["ReportLevel"],
		output_substates = output["OutputSubstrates"],
	)

	if !isempty(non_linear_solver["Tolerances"])
		cfg[:tolerances] = non_linear_solver["Tolerances"]
	end

	if !isnothing(logger)
		cfg[:post_iteration_hook] = logger
	end

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

	if model[:Control].system.policy isa CyclingCVPolicy || model[:Control].system.policy isa CCPolicy || model[:Control].system.policy isa GenericProtocol
		if model[:Control].system.policy isa CyclingCVPolicy || model[:Control].system.policy isa GenericProtocol

			cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)

		elseif model[:Control].system.policy isa CCPolicy && model[:Control].system.policy.numberOfCycles > 0
			cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)
		end

		# function post_hook(done, report, sim, dt, forces, max_iter, cfg)

		# 	s = get_simulator_storage(sim)
		# 	m = get_simulator_model(sim)

		# 	if model[:Control].system.policy isa CyclingCVPolicy

		# 		if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
		# 			report[:stopnow] = true
		# 		else
		# 			report[:stopnow] = false
		# 		end

		# 	elseif model[:Control].system.policy isa CCPolicy

		# 		if m[:Control].system.policy.numberOfCycles == 0

		# 			if m[:Control].system.policy.initialControl == "charging"

		# 				if s.state.Control.ElectricPotential[1] >= m[:Control].system.policy.upperCutoffVoltage
		# 					report[:stopnow] = true
		# 				else
		# 					report[:stopnow] = false
		# 				end

		# 			elseif m[:Control].system.policy.initialControl == "discharging"

		# 				if s.state.Control.ElectricPotential[1] <= m[:Control].system.policy.lowerCutoffVoltage
		# 					report[:stopnow] = true

		# 				else

		# 					report[:stopnow] = false
		# 				end
		# 			end
		# 		else
		# 			if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
		# 				report[:stopnow] = true
		# 			else
		# 				report[:stopnow] = false
		# 			end
		# 		end
		# 	elseif model[:Control].system.policy isa GenericProtocol
		# 		number_of_steps = model[:Control].system.policy.number_of_control_steps
		# 		if s.state.Control.Controller.step_number > number_of_steps
		# 			report[:stopnow] = true
		# 		else
		# 			report[:stopnow] = false
		# 		end
		# 		# Do nothing
		# 	else
		# 		error("Unknown control policy")
		# 	end


		# 	return (done, report)

		# end

		# cfg[:post_ministep_hook] = post_hook


	end


	return cfg

end



function get_scalings(model, parameters)

	refT = 298.15

	eldes = (:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial)

	j0s   = Array{Float64}(undef, 2)
	Rvols = Array{Float64}(undef, 2)

	F = FARADAY_CONSTANT

	for (i, elde) in enumerate(eldes)

		rate_func = model[elde].system.params[:reaction_rate_constant_func]
		cmax      = model[elde].system[:maximum_concentration]
		# Eak       = model[elde].system[:activation_energy_of_reaction]
		vsa = model[elde].system[:volumetric_surface_area]

		if hasproperty(model[elde].system.params, :activation_energy_of_reaction)
			Ea = model[elde].system[:activation_energy_of_reaction]
		else
			Ea = nothing
		end
		setting_temperature_dependence = model[elde].system[:setting_temperature_dependence]

		c_a = 0.5 * cmax

		if isa(rate_func, Real)
			R0 = temperature_dependent(refT, rate_func; Ea, dependent = setting_temperature_dependence)
			# R0 = arrhenius(refT, rate_func, Eak)
		else
			R0 = temperature_dependent(refT, rate_func(c_a, refT); Ea, dependent = setting_temperature_dependence)
		end
		c_e            = 1000.0
		activematerial = model[elde].system

		j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial)

		# j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial, c_a, c_e)

		Rvols[i] = j0s[i] * vsa / F

	end

	j0Ref   = mean(j0s)
	RvolRef = mean(Rvols)

	if include_current_collectors(model)
		component_names = (:NegativeElectrodeCurrentCollector, :NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial, :PositiveElectrodeCurrentCollector)
		cc_mapping      = Dict(:NegativeElectrodeActiveMaterial => :NegativeElectrodeCurrentCollector, :PositiveElectrodeActiveMaterial => :PositiveElectrodeCurrentCollector)
	else
		component_names = (:NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial)
	end

	volRefs = Dict()

	for name in component_names

		rep = model[name].domain.representation
		if rep isa MinimalTpfaGrid
			volRefs[name] = mean(rep.volumes)
		else
			volRefs[name] = mean(rep[:volumes])
		end

	end

	scalings = []

	scaling = (model_label = :Electrolyte, equation_label = :charge_conservation, value = F * volRefs[:Electrolyte] * RvolRef)
	push!(scalings, scaling)

	scaling = (model_label = :Electrolyte, equation_label = :mass_conservation, value = volRefs[:Electrolyte] * RvolRef)
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
			L   = model[elde].system[:InitialThickness]
			k   = model[elde].system[:IonicConductivity]

			SEIvoltageDropRef = F * RvolRef / vsa * L / k

			scaling = (model_label = elde, equation_label = :sei_voltage_drop, value = SEIvoltageDropRef)
			push!(scalings, scaling)

			De = model[elde].system[:ElectronicDiffusionCoefficient]
			ce = model[elde].system[:InterstitialConcentration]

			scaling = (model_label = elde, equation_label = :sei_mass_cons, value = De * ce / L)
			push!(scalings, scaling)

		end

	end

	return scalings

end



function setup_timesteps(input;
	kwargs...)
	"""
		Method setting up the timesteps from a json file object. 
	"""
	cycling_protocol = input.cycling_protocol
	simulation_settings = input.simulation_settings

	protocol = cycling_protocol["Protocol"]

	if protocol == "CC"
		if cycling_protocol["TotalNumberOfCycles"] == 0

			if cycling_protocol["InitialControl"] == "discharging"
				CRate = cycling_protocol["DRate"]
			else
				CRate = cycling_protocol["CRate"]
			end

			con = Constants()
			totalTime = 1.1 * con.hour / CRate



			dt = simulation_settings["TimeStepDuration"]

			if haskey(input.model_settings, "RampUp")
				nr = simulation_settings["RampUpSteps"]
			else
				nr = 1
			end

			timesteps = compute_rampup_timesteps(totalTime, dt, nr)

		else

			ncycles = cycling_protocol["TotalNumberOfCycles"]
			DRate = cycling_protocol["DRate"]
			CRate = cycling_protocol["CRate"]

			con = Constants()

			totalTime = ncycles * 2 * (1 * con.hour / CRate + 1 * con.hour / DRate)



			dt = simulation_settings["TimeStepDuration"]
			n  = Int64(floor(totalTime / dt))

			if haskey(input.model_settings, "RampUp")
				nr = simulation_settings["RampUpSteps"]
			else
				nr = 1
			end

			timesteps = compute_rampup_timesteps(totalTime, dt, nr)
		end

	elseif protocol == "CCCV"

		ncycles = cycling_protocol["TotalNumberOfCycles"]
		DRate = cycling_protocol["DRate"]
		CRate = cycling_protocol["CRate"]

		con = Constants()

		totalTime = ncycles * 2.5 * (1 * con.hour / CRate + 1 * con.hour / DRate)

		dt = simulation_settings["TimeStepDuration"]
		n  = Int64(floor(totalTime / dt))

		if haskey(input.model_settings, "RampUp")
			nr = simulation_settings["RampUpSteps"]
		else
			nr = 1
		end

		timesteps = compute_rampup_timesteps(totalTime, dt, nr)

	elseif protocol == "Function"
		totalTime = cycling_protocol["TotalTime"]
		dt = simulation_settings["TimeStepDuration"]
		n = totalTime / dt
		timesteps = repeat([dt], Int64(floor(n)))

	elseif protocol == "Experiment"
		totalTime = cycling_protocol["TotalTime"]
		dt = simulation_settings["TimeStepDuration"]
		n = totalTime / dt
		if haskey(input.model_settings, "RampUp")
			nr = simulation_settings["RampUpSteps"]
		else
			nr = 1
		end
		timesteps = compute_rampup_timesteps(totalTime, dt, Int(nr))

	else

		error("Control policy $protocol not recognized")

	end

	return timesteps
end

function compute_rampup_timesteps(time::Real, dt::Real, n::Integer = 8)

	ind = collect(range(n, 1, step = -1))
	dt_init = [dt / 2^k for k in ind]
	cs_time = cumsum(dt_init)
	if any(cs_time .> time)
		dt_init = dt_init[cs_time .< time]
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

####################
# Current function #
####################

function get_current_value(t::Real, inputI::Real, tup::Real = 0.1; use_ramp_up = true, direction = "discharging")
	t, inputI, tup, val = promote(t, inputI, tup, 0.0)
	if use_ramp_up == false
		val = inputI
	else
		if t <= tup
			val = sineup(0.0, inputI, 0.0, tup, t)
		else
			val = inputI
		end
	end
	val_signed = adjust_current_sign(val, direction)

	return val_signed
end

function adjust_current_sign(I, direction)
	if direction == "discharging"
		val = I
	elseif direction == "charging"
		val = -I
	else
		error("The direction $direction is not recognized.")
	end

	return val
end

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
	cfg::Any
	parameters::Any
	simulator::Any


	function Simulation(
		model::M,
		cell_parameters::CellParameters,
		cycling_protocol::CyclingProtocol;
		simulation_settings::SimulationSettings = get_default_simulation_settings(model),
		hook = nothing,
		kwargs...,
	) where {M <: ModelConfigured}

		if model.is_valid
			function_to_solve = run_battery

			# Here will come a validation function
			model_settings = model.settings
			cell_parameters_is_valid = validate_parameter_set(cell_parameters, model_settings)
			cycling_protocol_is_valid = validate_parameter_set(cycling_protocol)
			simulation_settings_is_valid = validate_parameter_set(simulation_settings, model_settings)

			if cell_parameters_is_valid && cycling_protocol_is_valid && simulation_settings_is_valid
				is_valid = true

			else
				is_valid = false
			end

			# Set some default simulation settings that aren't required by the user
			set_default_solver_and_simulation_settings!(simulation_settings)

			# Combine the parameter sets and settings
			input = (model_settings = model_settings,
				cell_parameters = cell_parameters,
				cycling_protocol = cycling_protocol,
				simulation_settings = simulation_settings,
			)

			# Setup grids and couplings
			grids, couplings = setup_grids_and_couplings(model, input)

			# Setup simulation
			model, parameters = setup_model(model, input, grids, couplings)

			# setup initial state
			initial_state = setup_initial_state(input, model)

			# setup forces
			forces = setup_forces(model.multimodel)

			# setup jutul simulator
			simulator = Simulator(model.multimodel; state0 = initial_state, parameters = parameters, copy_state = true)

			# setup time steps
			time_steps = setup_timesteps(input)

			# setup simulation configuration

			cfg = setup_config(simulator,
				model.multimodel,
				parameters,
				input;
				kwargs...,
			)

			# Setup hook if given
			if !isnothing(hook)
				hook(simulator,
					model.multimodel,
					initial_state,
					forces,
					time_steps,
					cfg)
			end

			# grids = get_grids(model)


		else
			error("""
			Oops! Your Model object is not valid. 🛑

			TIP: Validation happens when instantiating the Model object. 
			Check the warnings to see exactly where things went wrong. 🔍

			""")
		end
		return new{}(is_valid, model, cell_parameters, cycling_protocol, simulation_settings, time_steps, forces, initial_state, grids, couplings, cfg, parameters, simulator)
	end
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
function solve(problem::Simulation; accept_invalid = false, info_level = 0, end_report = info_level > -1, logger = nothing)

	config_kwargs = (info_level = info_level, end_report = end_report)

	# Note: Typically function_to_solve is run_battery
	if accept_invalid == true
		output = solve_simulation(problem; config_kwargs, logger)
	else
		if problem.is_valid == true
			output = solve_simulation(problem; config_kwargs, logger)

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
- `kwargs...`: Additional keyword arguments passed to the lower-level `simulate` function.

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
plot(result.states)
```
"""
function solve_simulation(sim::Simulation; config_kwargs, logger)

	simulator = sim.simulator
	model = sim.model
	state0 = sim.initial_state
	forces = sim.forces
	timesteps = sim.time_steps
	grids = sim.grids
	cfg = sim.cfg
	couplings = sim.couplings
	parameters = sim.parameters
	simulation_settings = sim.settings
	cell_parameters = sim.cell_parameters
	cycling_protocol = sim.cycling_protocol

	cfg[:info_level] = config_kwargs.info_level
	cfg[:end_report] = config_kwargs.end_report

	if !isnothing(logger)
		cfg[:post_iteration_hook] = logger
	end

	# Perform simulation
	states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	extra = Dict(:simulator => simulator,
		:forces => forces,
		:state0 => state0,
		:parameters => parameters,
		:simulation_settings => simulation_settings,
		:cell_parameters => cell_parameters,
		:cycling_protocol => cycling_protocol,
		:model => model,
		:couplings => couplings,
		:grids => grids,
		:timesteps => timesteps,
		:cfg => cfg)
	extra[:timesteps] = timesteps

	input = Dict(
		:model_settings => model.settings,
		:simulation_settings => simulation_settings,
		:cell_parameters => cell_parameters,
		:cycling_protocol => cycling_protocol,
	)

	cellSpecifications = computeCellSpecifications(model.multimodel)

	return (states             = states,
		cellSpecifications = cellSpecifications,
		reports            = reports,
		input              = input,
		extra              = extra)

end


function set_default_solver_and_simulation_settings!(simulation_settings)
	set_default_input_params!(simulation_settings.all, ["NonLinearSolver", "MaxTimestepCuts"], 10)
	set_default_input_params!(simulation_settings.all, ["NonLinearSolver", "MaxIterations"], 20)
	set_default_input_params!(simulation_settings.all, ["NonLinearSolver", "LinearSolver"], Dict())

	set_default_input_params!(simulation_settings.all, ["UseGroups"], false)
	set_default_input_params!(simulation_settings.all, ["GeneralAD"], true)

end

######################################
# Setup solver configuration options #
######################################

"""
	setup_config(sim::JutulSimulator,
					  model::MultiModel,
					  parameters;
					  inputparams::BattMoInputFormatOld,
					  extra_timing::Bool,
					  use_model_scaling,
					  kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function setup_config(sim::JutulSimulator,
	model::MultiModel,
	parameters,
	input;
	extra_timing::Bool = false,
	use_model_scaling::Bool = true,
	kwargs...)

	cfg = simulator_config(sim; kwargs...)

	simulation_settings = input.simulation_settings
	lin_solv_dict = simulation_settings["NonLinearSolver"]["LinearSolver"]
	lin_solv_dict_any = Dict{String, Any}(lin_solv_dict)


	cfg[:linear_solver]            = battery_linsolve(lin_solv_dict_any)
	cfg[:debug_level]              = 0
	cfg[:max_timestep_cuts]        = simulation_settings["NonLinearSolver"]["MaxTimestepCuts"]
	cfg[:max_residual]             = 1e20
	cfg[:output_substates]         = true
	cfg[:min_nonlinear_iterations] = 1
	cfg[:extra_timing]             = extra_timing
	cfg[:max_nonlinear_iterations] = simulation_settings["NonLinearSolver"]["MaxIterations"]
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

						if s.state.Control.Voltage[1] >= m[:Control].system.policy.upperCutoffVoltage
							report[:stopnow] = true
						else
							report[:stopnow] = false
						end

					elseif m[:Control].system.policy.initialControl == "discharging"

						if s.state.Control.Voltage[1] <= m[:Control].system.policy.lowerCutoffVoltage
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

		c_a = 0.5 * cmax

		if isa(rate_func, Real)
			R0 = rate_func
		else
			R0 = rate_func(c_a, refT)
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

			timesteps = rampupTimesteps(totalTime, dt, nr)

		else

			ncycles = cycling_protocol["TotalNumberOfCycles"]
			DRate = cycling_protocol["DRate"]
			CRate = cycling_protocol["CRate"]

			con = Constants()

			totalTime = ncycles * 2 * (1 * con.hour / CRate + 1 * con.hour / DRate)



			dt = simulation_settings["TimeStepDuration"]
			n  = Int64(floor(totalTime / dt))

			timesteps = repeat([dt], n)
		end

	elseif protocol == "CCCV"

		ncycles = cycling_protocol["TotalNumberOfCycles"]
		DRate = cycling_protocol["DRate"]
		CRate = cycling_protocol["CRate"]

		con = Constants()

		totalTime = ncycles * 2.5 * (1 * con.hour / CRate + 1 * con.hour / DRate)

		dt = simulation_settings["TimeStepDuration"]
		n  = Int64(floor(totalTime / dt))


		timesteps = repeat([dt], n)

	elseif protocol == "Function"
		totalTime = cycling_protocol["TotalTime"]
		dt = simulation_settings["TimeStepDuration"]
		n = totalTime / dt
		timesteps = repeat([dt], Int64(floor(n)))

	else

		error("Control policy $controlPolicy not recognized")

	end

	return timesteps
end
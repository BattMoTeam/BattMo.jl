export AbstractCalibration, VoltageCalibration
export free_calibration_parameter!, freeze_calibration_parameter!, set_calibration_parameter!
export print_calibration_overview


"""
	AbstractCalibration

Abstract type for calibration objects.
"""
abstract type AbstractCalibration end


"""
	mutable struct VoltageCalibration <: AbstractCalibration

Represents a voltage calibration problem for a battery simulation.

# Fields
- `t::Any`  
  Time vector corresponding to the calibration voltage data points.

- `v::Any`  
  Voltage vector containing calibration voltage data.

- `sim::Any`  
  A deep copy of the `Simulation` object used for calibration, allowing reuse of the original simulation.

- `parameter_targets::Any`  
  Dictionary mapping parameter name vectors (keys) to tuples `(initial_value, lower_bound, upper_bound)` specifying calibration targets.

- `calibrated_cell_parameters::Any`  
  Holds the cell parameters obtained after calibration is solved.

- `history::Any`  
  Stores the optimization process history, including iteration details and convergence info.

# Constructors

- `VoltageCalibration(t, v, sim)`

  Creates a new calibration object from time vector `t`, voltage vector `v`, and a simulation `sim`.  
  Ensures time vector `t` is strictly increasing and matches length of `v`.

- `VoltageCalibration(t_and_v, sim; normalize_time = false)`

  Alternative constructor that takes a 2D array `t_and_v` where the first column is time and the second is voltage.  
  Optionally normalizes the time vector to start at zero if `normalize_time` is true.

# Example
```julia
t = [0.0, 10.0, 20.0, 30.0]
v = [3.7, 3.6, 3.5, 3.4]
sim = Simulation(...)
calib = VoltageCalibration(t, v, sim)

# or with combined data
data = [0.0 3.7; 10.0 3.6; 20.0 3.5; 30.0 3.4]
calib2 = VoltageCalibration(data, sim, normalize_time=true)
```
"""
mutable struct VoltageCalibration <: AbstractCalibration
	"Time vector for the calibration data."
	t::Any
	"Voltage vector for the calibration data."
	v::Any
	"The simulation object used for calibration. This is a copy of the original simulation object, so that the original simulation can be reused."
	sim::Any
	"A dictionary containing the calibration parameters and their targets. The keys are vectors of strings representing the parameter names, and the values are tuples with the initial value, lower bound, and upper bound."
	parameter_targets::Any
	"The calibrated cell parameters (once solved)."
	calibrated_cell_parameters::Any
	"History of the optimization process, containing information about the optimization steps."
	history::Any
	"""
		VoltageCalibration(t, v, sim)

	Set up calibration for a voltage calibration problem for given time vector
	`t` and voltage vector `v` and a `Simulation` instance `sim`
	"""
	function VoltageCalibration(t, v, sim)
		@assert length(t) == length(v)
		for i in 2:length(t)
			@assert t[i] > t[i-1]
		end
		return new(t, v, deepcopy(sim), Dict{Vector{String}, Any}(), missing, missing)
	end
end

function VoltageCalibration(t_and_v, sim; normalize_time = false)
	t = t_and_v[:, 1]
	v = t_and_v[:, 2]
	if normalize_time
		t = t .- minimum(t)  # Normalize time to start at zero
	end
	return VoltageCalibration(t, v, sim)
end

"""
	free_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String};
			initial_value = missing,
			lower_bound = missing,
			upper_bound = missing
		)

Set a calibration parameter to be free for optimization. The parameter is
specified by `parameter_name`, which is a vector of strings representing the
nested structure of the parameter in the simulation's cell parameters.

# Notes
- The `initial_value` is optional and can be set to `missing` if not provided.
- The `lower_bound` and `upper_bound` must be provided and cannot be `missing`.
"""
function free_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String};
	initial_value = missing,
	lower_bound = missing,
	upper_bound = missing,
)

	if ismissing(lower_bound) || ismissing(upper_bound)
		throw(ArgumentError("$parameter_name: Bounds must be set for free parameters (defaults not implemented)"))
	end
	if !ismissing(initial_value)
		set_calibration_parameter!(vc, parameter_name, initial_value)
	end
	initial_value = get_nested_json_value(vc.sim.cell_parameters, parameter_name)
	if initial_value < lower_bound || initial_value > upper_bound
		throw(ArgumentError("Initial value for for $parameter_name $initial_value out of bounds [$lower_bound, $upper_bound]"))
	end
	if lower_bound >= upper_bound
		throw(ArgumentError("Lower bound for $parameter_name $lower_bound must be less than upper bound $upper_bound"))
	end
	vc.parameter_targets[parameter_name] = (v0 = initial_value, vmin = lower_bound, vmax = upper_bound)
	return vc
end

"""
	freeze_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, val = missing)

Remove a calibration parameter from the optimization process, optionally setting
its value to `val`.
"""
function freeze_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, val = missing)
	if !ismissing(val)
		set_calibration_parameter!(vc, parameter_name, val)
	end
	delete!(vc.parameter_targets, parameter_name)
end

"""
	print_calibration_overview(vc::AbstractCalibration)

Print an overview of the calibration parameters and their current values. If the
calibration has been performed, the table will also include the optimized values
and the percentage change from the initial values.
"""
function print_calibration_overview(vc::AbstractCalibration)
	function print_table(subkeys, t)
		opt_cell = vc.calibrated_cell_parameters
		is_optimized = !ismissing(opt_cell)
		header = ["Name", "Initial value", "Bounds"]
		if is_optimized
			push!(header, "Optimized value")
			push!(header, "Change")
		end
		tab = Matrix{Any}(undef, length(subkeys), length(header))
		# widths = zeros(Int, size(tab, 2))
		# widths[1] = 40
		for (i, k) in enumerate(subkeys)
			v0 = pt[k].v0
			tab[i, 1] = join(k[2:end], ".")
			tab[i, 2] = v0
			tab[i, 3] = "$(pt[k].vmin) - $(pt[k].vmax)"
			if is_optimized
				v = value(get_nested_json_value(opt_cell, k))
				perc = round(100 * (v - v0) / max(v0, 1e-20), digits = 2)
				tab[i, 4] = v
				tab[i, 5] = "$perc%"
			end
		end
		# TODO: Do this properly instead of via Jutul's import...
		Jutul.PrettyTables.pretty_table(tab, header = header, title = t)
	end

	pt = vc.parameter_targets
	pkeys = keys(pt)
	outer_keys = String[]
	for k in pkeys
		push!(outer_keys, first(k))
	end
	outer_keys = unique!(outer_keys)
	for outer_key in outer_keys
		subkeys = filter(x -> x[1] == outer_key, pkeys)
		print_table(subkeys, "$outer_key: Active calibration parameters")
	end
end

"""
	set_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, value)

Set a calibration parameter to a specific value.
"""
function set_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, value)
	set_nested_json_value!(vc.sim.cell_parameters, parameter_name, value)
end

function setup_calibration_objective(vc::VoltageCalibration)
	# Set up the objective function
	V_fun = get_1d_interpolator(vc.t, vc.v, cap_endpoints = true)
	total_time = vc.t[end]
	function objective(model, state, dt, step_info, forces)
		t = state[:Control][:Controller].time
		if step_info[:step] == step_info[:Nstep]
			dt = max(dt, total_time - t)
		end
		V_obs = V_fun(t)
		V_sim = state[:Control][:ElectricPotential][1]
		return voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
	end
	return objective
end

function voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
	return dt * (V_obs - V_sim)^2 / total_time
end

function evaluate_calibration_objective(vc::VoltageCalibration, objective, case, states, dt)
	f = Jutul.evaluate_objective(objective, case.model, states, dt, case.forces)
	return f
end


"""
	solve(vc::AbstractCalibration; kwargs...) -> (calibrated_parameters, history)

Solve the calibration problem by optimizing model parameters to fit target data.

# Description
Performs parameter calibration for a model using the LBFGS optimizer (or a user-supplied optimizer). The method minimizes an objective function derived from the discrepancy between simulation output and calibration targets.

# Keyword Arguments
- `grad_tol`: Gradient norm stopping tolerance (default: `1e-6`)
- `obj_change_tol`: Objective change tolerance (default: `1e-6`)
- `opt_fun`: Optional custom optimization function
- `backend_arg`: Tuple controlling sparsity and preprocessing (default settings shown in source)
- Other keyword arguments are passed to the optimizer.

# Returns
A tuple `(calibrated_cell_parameters, optimization_history)`.

# Example
```julia
calibrated_params, history = solve(vc; grad_tol = 1e-7)
```
"""
function solve(vc::AbstractCalibration;
	solver_settings = get_default_solver_settings(vc.sim.model),
	grad_tol = 1e-6,
	obj_change_tol = 1e-6,
	opt_fun = missing,
	backend_arg = (
		use_sparsity = false,
		di_sparse = true,
		single_step_sparsity = false,
		do_prep = true,
	),
	kwarg...,
)
	sim = deepcopy(vc.sim)
	x0, x_setup = vectorize_cell_parameters_for_calibration(vc, sim)
	# Set up the objective function
	objective = setup_calibration_objective(vc)

	ub = similar(x0)
	lb = similar(x0)
	offsets = x_setup.offsets
	for (i, k) in enumerate(x_setup.names)
		(; vmin, vmax) = vc.parameter_targets[k]
		for j in offsets[i]:(offsets[i+1]-1)
			lb[j] = vmin
			ub[j] = vmax
		end
	end
	adj_cache = Dict()

	setup_battmo_case(X, step_info = missing) = setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
	solve_and_differentiate(x) = solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective, solver_settings;
		adj_cache = adj_cache,
		backend_arg,
	)
	jutul_message("Calibration", "Starting calibration of $(length(x0)) parameters.", color = :green)

	t_opt = @elapsed if ismissing(opt_fun)
		v, x, history = Jutul.LBFGS.box_bfgs(x0, solve_and_differentiate, lb, ub;
			maximize = false,
			print = 1,
			grad_tol = grad_tol,
			obj_change_tol = obj_change_tol,
			kwarg...,
		)
	else
		self_cache = Dict()
		function f!(x)
			f, g = solve_and_differentiate(x)
			self_cache[:f] = f
			self_cache[:g] = g
			self_cache[:x] = x
			return f
		end

		function g!(z, x)
			if self_cache[:x] !== x
				f!(x)  # Update the cache if the vector has changed
			end
			g = self_cache[:g]
			return z .= g
		end
		x, history = opt_fun(f!, g!, x0, lb, ub)
	end
	jutul_message("Calibration", "Calibration finished in $t_opt seconds.", color = :green)
	# Also remove AD from the internal ones and update them
	Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, x, x_setup)
	cell_prm_out = deepcopy(sim.cell_parameters)
	vc.calibrated_cell_parameters = cell_prm_out
	vc.history = history
	return (cell_prm_out, history)
end

function solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective, solver_settings;
	adj_cache = Dict(),
	backend_arg = NamedTuple(),
	gradient = true,
)
	case = setup_battmo_case(x)
	states, dt = simulate_battmo_case_for_calibration(case, solver_settings)
	# Evaluate the objective function
	f = evaluate_calibration_objective(vc, objective, case, states, dt)
	# Solve adjoints
	if gradient
		if !haskey(adj_cache, :storage)
			adj_cache[:storage] = Jutul.AdjointsDI.setup_adjoint_storage_generic(
				x, setup_battmo_case, states, dt, objective;
				backend_arg...,
				info_level = 0,
			)
		end
		S = adj_cache[:storage]
		g = similar(x)
		Jutul.AdjointsDI.solve_adjoint_generic!(
			g, x, setup_battmo_case, S, states, dt, objective,
		)
		# g = Jutul.AdjointsDI.solve_adjoint_generic(
		#     x, setup_battmo_case, states, dt, objective,
		#     use_sparsity = false,
		#     di_sparse = false,
		#     single_step_sparsity = false,
		#     do_prep = false
		# )
	else
		g = missing
	end
	return (f, g)
end


function vectorize_cell_parameters_for_calibration(vc, sim)
	pt = vc.parameter_targets
	pkeys = collect(keys(pt))
	if length(pkeys) == 0
		throw(ArgumentError("No free parameters set, unable to calibrate."))
	end
	# Set up the functions to serialize
	x0, x_setup = Jutul.AdjointsDI.vectorize_nested(sim.cell_parameters.all,
		active = pkeys,
		active_type = Real,
	)
	return (x0, x_setup)
end

function setup_battmo_case_for_calibration(X, sim, x_setup, step_info = missing; stepix = missing)
	T = eltype(X)
	Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, X, x_setup)
	input = (
		model_settings = sim.model.settings,
		cell_parameters = sim.cell_parameters,
		cycling_protocol = sim.cycling_protocol,
		simulation_settings = sim.settings)

	model = sim.model
	termination_criterion = deepcopy(sim.termination_criterion)

	grids, couplings = setup_grids_and_couplings(model, input)

	model, parameters = setup_model!(model, input, grids, couplings; T = T)
	state0 = BattMo.setup_initial_state(input, model)
	forces = setup_forces(model.multimodel)
	timesteps = BattMo.setup_timesteps(input)
	if !ismissing(stepix)
		timesteps = timesteps[stepix]
	end

	return Jutul.JutulCase(deepcopy(model.multimodel), deepcopy(timesteps), deepcopy(forces), parameters = deepcopy(parameters), state0 = deepcopy(state0), input_data = deepcopy(input), termination_criterion = termination_criterion)
end

function simulate_battmo_case_for_calibration(case, solver_settings;
	simulator = missing,
	config = missing,
)
	case = deepcopy(case)
	if ismissing(simulator)
		simulator = Simulator(case)
	end

	if ismissing(config)
		config = solver_configuration(simulator,
			case.model,
			case.parameters;
			solver_settings = solver_settings,
			info_level = -1,
		)
	end
	result = Jutul.simulate(case; config = deepcopy(config))
	# result = Jutul.simulate!(simulator,
	# 	case.dt,
	# 	state0 = case.state0,
	# 	parameters = case.parameters,
	# 	forces = case.forces,
	# 	config = config,
	# )

	# last_solves = result.reports[end][:ministeps][end]
	# if !result.reports[end][:ministeps][end][:success]
	# TODO: handle case where the solver fails.
	#    g = fill(1e20, length(x))
	#    return (1e20, g)
	#end
	states, dt, = Jutul.expand_to_ministeps(result)
	return (states, dt)
end

export GenericPolicy

abstract type AbstractControlStep end

mutable struct Termination
	quantity::String
	comparison::Union{String, Nothing}
	value::Float64
	function Termination(quantity, value; comparison = nothing)
		return new{}(quantity, comparison, value)
	end
end

mutable struct CurrentStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	time_step_size::Union{Nothing, Float64}
	current_function::Union{Missing, Any}
end

struct VoltageStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	time_step_size::Union{Nothing, Float64}
end

mutable struct RestStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	direction::Union{Nothing, String}
	termination::Termination
	time_step_size::Union{Nothing, Float64}
end

struct CycleStep <: AbstractControlStep
	number_of_cycles::Int
	termination::Union{Nothing, Termination}
	cycle_control_steps::Vector{AbstractControlStep}
end

mutable struct GenericPolicy <: AbstractPolicy
	control_policy::String
	control_steps::Vector{AbstractControlStep}
	initial_control::AbstractControlStep
	number_of_control_steps::Int
	function GenericPolicy(json::Dict)
		steps = []
		for step in json["controlsteps"]
			parsed_step = parse_control_step(step)

			if isa(parsed_step, CycleStep)
				# If the parsed step is a compound cycle, expand it
				for cycle_step in parsed_step.cycle_control_steps
					push!(steps, cycle_step)
				end
			else
				# Otherwise, it's a single step — push directly
				push!(steps, parsed_step)
			end
		end

		number_of_steps = length(steps)
		return new(json["controlPolicy"], steps, steps[1], number_of_steps)
	end
end


function parse_control_step(json::Dict)
	ctype = json["controltype"]
	if ctype == "current"
		return CurrentStep(
			json["value"],
			get(json, "direction", nothing),
			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
			get(json, "timeStepSize", nothing),
			missing)
	elseif ctype == "voltage"
		return VoltageStep(
			json["value"],
			get(json, "direction", nothing),
			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
			get(json, "timeStepSize", nothing),
		)
	elseif ctype == "rest"
		return RestStep(
			get(json, "value", nothing),
			get(json, "direction", nothing),
			Termination(json["termination"]["quantity"], json["termination"]["value"]),
			get(json, "timeStepSize", nothing),
		)
	elseif ctype == "cycle"
		nested = [parse_control_step(step) for step in json["cycleControlSteps"]]
		return CycleStep(json["numberOfCycles"], get(json, "termination", nothing), nested)
	else
		error("Unsupported controltype: $ctype")
	end
end

function getInitCurrent(policy::GenericPolicy)
	control = policy.initial_control
	if isa(control, VoltageStep)
		error("Voltage control cannot be the first control step")
	elseif isa(control, CurrentStep)
		if !ismissing(policy.current_function)
			val = policy.current_function(0.0)
		else
			if control.direction == "discharging"
				I = control.value
			elseif control.direction == "charging"
				I = -control.value
			else
				error("Initial control direction not recognized")
			end
		end
		return I

	elseif isa(control, RestStep)
		return 0.0
	else
		error("initial control not recognized")
	end

end


function setup_initial_control_policy!(policy::GenericPolicy, inputparams, parameters)
	control = policy.initial_control
	if isa(control, VoltageStep)
		error("Voltage control cannot be the first control step")
	elseif isa(control, CurrentStep)
		if ismissing(policy.current_function)
			tup = Float64(inputparams["Control"]["rampupTime"])
			cFun(time) = currentFun(time, Imax, tup)

			policy.current_function = cFun
		end
		return I

	elseif isa(control, RestStep)

	else
		error("initial control not recognized")
	end


end

mutable struct GenericController <: Controller
	policy::GenericPolicy
	stop_simulation::Bool
	current_step::AbstractControlStep
	current_step_number::Int
	time::Real
	number_of_steps::Int
	target::Real
	dIdt::Real
	dEdt::Real

	function GenericController(policy::GenericPolicy, stop_simulation::Bool, current_step::Union{Nothing, AbstractControlStep}, current_step_number::Int, time::Real, number_of_steps::Int; target::Real = 0.0, dEdt::Real = 0.0, dIdt::Real = 0.0)
		new(policy, stop_simulation, current_step, current_step_number, time, number_of_steps, target, dIdt, dEdt)
	end
end

GenericController() = GenericController(nothing, false, nothing, 0, 0.0, 0)

@inline function Jutul.numerical_type(x::GenericController)
	return typeof(x.current_step)
end

"""
Function to create (deep) copy of generic controller
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.policy = cv.policy
	cv_copy.current_step = cv.current_step
	cv_copy.current_step_number = cv.current_step_number
	cv_copy.time = cv.time
	cv_copy.number_of_steps = cv.number_of_steps
	cv_copy.target = cv.target
	cv_copy.dEdt = cv.dEdt
	cv_copy.dIdt = cv.dIdt

end

"""
Overload function to copy GenericController
"""
function Base.copy(cv::GenericController)
	# Construct using the known type parameter S
	cv_copy = GenericController(cv.policy, cv.stop_simulation, cv.current_step, cv.current_step_number, cv.time, cv.number_of_steps; target = cv.target, dIdt = cv.dIdt, dEdt = cv.dEdt)

	return cv_copy
end


function Jutul.update_values!(old::GenericController, new::GenericController)

	copyController!(old, new)

end

"""
We need to add the specific treatment of the controller variables for GenericPolicy
"""
function Jutul.reset_state_to_previous_state!(
	storage,
	model::SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{GenericPolicy}, T3, T4},
) where {T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage), SimulationModel},
		storage,
		model)

	copyController!(storage.state[:Controller], storage.state0[:Controller])
end


#######################################
# Helper functions for control switch #
#######################################

"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::P, state, controller::GenericController) where P <: AbstractControlStep

	step = policy
	termination = step.termination

	if haskey(state, :ElectricPotential)
		E = only(state.ElectricPotential)
		I = only(state.Current)
	else
		E = ForwardDiff.value(only(state.Control.ElectricPotential))
		I = ForwardDiff.value(only(state.Control.Current))
	end

	before = false
	after = false

	if termination.quantity == "voltage"

		target = termination.value
		tol = 1e-4

		if isnothing(termination.comparison) || termination.comparison == "below"
			before = E > target * (1 + tol)
			after  = E < target * (1 - tol)
		elseif termination.comparison == "above"
			before = E < target * (1 - tol)
			after  = E > target * (1 + tol)
		end

	elseif termination.quantity == "current"
		target = termination.value
		tol = 1e-4

		if isnothing(termination.comparison) || termination.comparison == "absolute value below"
			before = abs(I) > target * (1 + tol)
			after  = abs(I) < target * (1 - tol)
		elseif termination.comparison == "absolute value above"
			before = abs(I) < target * (1 - tol)
			after  = abs(I) > target * (1 + tol)
		end

	elseif termination.quantity == "time"
		t = controller.time
		target = termination.value
		tol = 0.001

		before = t < target - tol
		after  = t > target + tol


	else
		error("Unsupported termination quantity: $(termination.quantity)")
	end

	return (beforeSwitchRegion = before, afterSwitchRegion = after)

end


"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {Q <: GenericPolicy, P <: CurrentAndVoltageModel{Q}}

	entity = associated_entity(p)
	active = active_entities(model.domain, entity, for_variables = true)
	v = state[state_symbol]

	nu = length(active)
	# ImaxDischarge = model.system.policy.ImaxDischarge
	# ImaxCharge    = model.system.policy.ImaxCharge

	# Imax = max(ImaxCharge, ImaxDischarge)

	# abs_max = 0.2 * Imax
	abs_max = nothing
	rel_max = relative_increment_limit(p)
	maxval = maximum_value(p)
	minval = minimum_value(p)
	scale = variable_scale(p)
	@inbounds for i in 1:nu
		a_i = active[i]
		v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
	end

end

"""
Implementation of the generic control policy
"""
function update_control_type_in_controller!(state, state0, policy::GenericPolicy, dt)
	# --- Helpers: mapping between controller.step_number (zero-based) and control_steps (1-based) ---
	control_steps = policy.control_steps
	nsteps = length(control_steps)

	# Map controller.step_number (which in your logs is 0 for the first step)
	# to 1-based index used for control_steps array
	stepnum_to_index(stepnum::Integer) = clamp(stepnum + 1, 1, nsteps)   # stepnum 0 -> index 1
	index_to_stepnum(idx::Integer) = clamp(idx - 1, 0, nsteps - 1)      # index 1 -> stepnum 0

	# --- Extract scalars safely ---
	E_vals  = value(state[:ElectricPotential])
	I_vals  = value(state[:Current])
	E0_vals = value(state0[:ElectricPotential])
	I0_vals = value(state0[:Current])

	@assert length(E_vals) == 1 "Expected scalar ElectricPotential"
	@assert length(I_vals) == 1 "Expected scalar Current"
	@assert length(E0_vals) == 1 "Expected scalar ElectricPotential (state0)"
	@assert length(I0_vals) == 1 "Expected scalar Current (state0)"

	E  = first(E_vals)
	I  = first(I_vals)
	E0 = first(E0_vals)
	I0 = first(I0_vals)

	controller = state[:Controller]

	# --- Time and derivatives ---
	controller.time = state0.Controller.time + dt
	controller.dIdt = dt > 0 ? (I - I0) / dt : 0.0
	controller.dEdt = dt > 0 ? (E - E0) / dt : 0.0

	# @info "⏱️  Time updated" time = controller.time dt = dt dIdt = controller.dIdt dEdt = controller.dEdt

	# --- Determine previous/ current indices and types (clearly mapped) ---
	prev_stepnum = state0.Controller.current_step_number                # e.g. 0 for first step
	prev_idx = stepnum_to_index(prev_stepnum)                           # 1-based index into control_steps
	ctrlType_prev = state0.Controller.current_step

	# @info "Current control step (mapped)" stepnum = prev_stepnum idx = prev_idx ctrlType = ctrlType_prev

	# Setup default outputs
	next_stepnum = prev_stepnum
	next_ctrlType = ctrlType_prev
	stop_simulation = false

	# Compute region switch flags for previous and current states
	rsw_prev = setupRegionSwitchFlags(ctrlType_prev, state0, controller)
	# @info "Region switch flags (prev)" beforeSwitch = rsw_prev.beforeSwitchRegion afterSwitch = rsw_prev.afterSwitchRegion

	if rsw_prev.beforeSwitchRegion
		# @info "🟡 Staying in current region (beforeSwitchRegion = true)"

	else
		# Recompute with updated state
		rsw_curr = setupRegionSwitchFlags(ctrlType_prev, state, controller)
		# @info "Region switch flags (curr)" beforeSwitch = rsw_curr.beforeSwitchRegion afterSwitch = rsw_curr.afterSwitchRegion

		# If controller hasn't already changed this Newton iteration, decide
		if controller.current_step_number == state0.Controller.current_step_number
			# @info "🔍 Checking if control step should change"

			if rsw_curr.afterSwitchRegion
				# Attempt to move forward one stepnum
				proposed_stepnum = prev_stepnum + 1   # still zero-based
				proposed_idx = stepnum_to_index(proposed_stepnum)

				if proposed_idx <= nsteps && proposed_stepnum <= (nsteps - 1)
					# @info "➡️  Switching to next control step" proposed_stepnum = proposed_stepnum proposed_idx = proposed_idx
					# Copy the policy step so we can mutate termination without altering original policy
					next_ctrlType = deepcopy(control_steps[proposed_idx])
					next_stepnum = index_to_stepnum(proposed_idx)

					# Adjust time-based termination (if needed)
					if hasfield(typeof(next_ctrlType), :termination) &&
					   next_ctrlType.termination.quantity == "time" &&
					   (next_ctrlType.termination.value !== nothing) &&
					   next_ctrlType.termination.value < controller.time

						next_ctrlType.termination.value = controller.time + next_ctrlType.termination.value
					end

				else
					# @info "🛑 Last control step reached or out-of-bounds — stopping simulation"
					stop_simulation = true
					next_stepnum = prev_stepnum
					next_ctrlType = state.Controller.current_step
				end

			else
				# @info "⏸️  Remaining in current control step"
				next_stepnum = prev_stepnum
				next_ctrlType = state.Controller.current_step
			end

		else
			# controller already advanced this iteration: keep what controller has
			# @info "⚙️  Controller already changed within this iteration — honoring controller.current_step"
			# Map controller.current_step_number (which may already be advanced) to index to fetch its definition if needed
			current_stepnum_now = controller.current_step_number
			current_idx_now = stepnum_to_index(current_stepnum_now)
			# @info "Controller reports" current_stepnum_now = current_stepnum_now current_idx_now = current_idx_now
			# Use controller.current_step (it should already be set)
			next_stepnum = current_stepnum_now
			next_ctrlType = controller.current_step
		end
	end

	# --- Finalize: clamp stepnum and set controller fields ---
	# Ensure we stay within valid [0, nsteps-1] for stepnum convention
	next_stepnum = clamp(next_stepnum, 0, max(0, nsteps - 1))
	controller.current_step_number = next_stepnum
	controller.current_step = next_ctrlType
	controller.stop_simulation = stop_simulation

	# Safety log: show the concrete type assigned so you can quickly spot mismatches
	# @info "✅ Controller update complete"
	# @info "Assigned stepnum/idx/type" stepnum = controller.current_step_number idx = stepnum_to_index(controller.current_step_number) typeof = typeof(controller.current_step) stop = controller.stop_simulation

	return nothing
end




"""
Update controller target value (current or voltage) based on the active control step
"""
function update_values_in_controller!(state, policy::GenericPolicy)

	controller = state[:Controller]
	step_idx = controller.current_step_number + 1

	control_steps = policy.control_steps

	if step_idx > length(control_steps)
		step_idx = length(control_steps)
	end

	step = control_steps[step_idx]

	ctrlType = state.Controller.current_step.direction

	cf = hasproperty(step, :current_function) ? getproperty(step, :current_function) : missing

	if !ismissing(cf)

		if cf isa Real
			I_t = cf
		else
			# Function of time at the end of interval
			I_t = cf(controller.time)
		end
		if ctrlType == "discharging"

			target = I_t



		elseif ctrlType == "charging"

			# minus sign below follows from convention
			target = -I_t
		else
			error("Control type $ctrlType not recognized")
		end
	else
		if step isa CurrentStep

			tup = state.Controller.time + 100 #Float64(AbstractInput["Control"]["rampupTime"])
			cFun(time) = currentFun(time, step.value, tup)

			state.Controller.current_step.current_function = cFun
			cf = state.Controller.current_step.current_function
			if cf isa Real
				I_t = cf
			else
				# Function of time at the end of interval
				I_t = cf(controller.time)
			end
			if ctrlType == "discharging"

				target = I_t



			elseif ctrlType == "charging"

				# minus sign below follows from convention
				target = -I_t
			else
				error("Control type $ctrlType not recognized")
			end

		elseif step isa VoltageStep
			target = step.value

		elseif step isa RestStep
			# Assume voltage hold during rest
			target = 0.0

		else
			error("Unsupported step type: $(typeof(step))")
		end
	end

	controller.target = target

end

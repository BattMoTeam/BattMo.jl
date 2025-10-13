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


function setup_initial_control_policy!(policy::GenericPolicy, inputparams::AbstractInput, parameters)
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
		print("Rest step")
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

	if haskey(state, :Phi)
		E = only(state.Phi)
		I = only(state.Current)
	else
		E = ForwardDiff.value(only(state.Control.Phi))
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

	E  = only(value(state[:Phi]))
	I  = only(value(state[:Current]))
	E0 = only(value(state0[:Phi]))
	I0 = only(value(state0[:Current]))

	controller = state[:Controller]

	# Update time and rates of change
	controller.time = state0.Controller.time + dt
	controller.dIdt = (I - I0) / dt
	controller.dEdt = (E - E0) / dt

	# Get control step info
	step_idx_0 = state0.Controller.current_step_number + 1
	control_steps = policy.control_steps

	ctrlType0 = state0.Controller.current_step

	# Check if we should switch to next step based on region switch flags
	rsw00 = setupRegionSwitchFlags(ctrlType0, state0, controller)

	# Stay within bounds of control steps
	if step_idx_0 > length(control_steps)
		error("Step index $step_idx exceeds number of control steps $(length(control_steps))")
	end

	if rsw00.beforeSwitchRegion

		# Stay in current control step
		next_step_idx   = step_idx_0
		ctrlType        = ctrlType0
		stop_simulation = false

	else

		currentCtrlType = state.Controller.current_step # current control in the the Newton iteration

		rsw0 = setupRegionSwitchFlags(ctrlType0, state, controller)

		if controller.current_step_number == state0.Controller.current_step_number

			# The control has not changed from previous time step and we want to determine if we should change it. 

			if rsw0.afterSwitchRegion

				# We switch to a new control because we are no longer in the acceptable region for the current
				# control
				if step_idx_0 == length(policy.control_steps)

					ctrlType        = currentCtrlType
					stop_simulation = true

				else
					ctrlType = control_steps[step_idx_0+1]
					stop_simulation = false
					if ctrlType.termination.quantity == "time"
						if policy.control_steps[step_idx_0+1].termination.value < controller.time
							termination_value = controller.time + policy.control_steps[step_idx_0+1].termination.value
							policy.control_steps[step_idx_0+1].termination.value = termination_value

						end
					end

				end
				# next control that can occur after the previous time step control (if it changes)

				next_step_idx = step_idx_0 + 1

			elseif rsw0.beforeSwitchRegion == false && step_idx_0 == length(policy.control_steps)

				ctrlType = currentCtrlType
				stop_simulation = true
				next_step_idx = step_idx_0 + 1

			else

				next_step_idx = step_idx_0
				ctrlType = ctrlType0
				stop_simulation = false

			end

		elseif controller.current_step_number + 1 == step_idx_0 + 1
			# Avoid switching back if we already moved forward in this Newton iteration

			if step_idx_0 == length(policy.control_steps)
				stop_simulation = true
				ctrlType = currentCtrlType

			else
				ctrlType = control_steps[step_idx_0+1]
				stop_simulation = false
				if ctrlType.termination.quantity == "time"
					if policy.control_steps[step_idx_0+1].termination.value < controller.time
						termination_value = controller.time + policy.control_steps[step_idx_0+1].termination.value
						policy.control_steps[step_idx_0+1].termination.value = termination_value
					end

				end

			end
			# next control that can occur after the previous time step control (if it changes)

			next_step_idx = step_idx_0 + 1

		else
			error("Unexpected control state transition at step $step_idx_0")
		end
	end

	# Update controller with the selected step index
	controller.current_step_number = min(next_step_idx - 1, length(control_steps))  # Stay within bounds
	controller.current_step = ctrlType
	controller.stop_simulation = stop_simulation

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

export GenericPolicy

abstract type AbstractControlStep end

struct Termination
	quantity::String
	comparison::Union{String, Nothing}
	value::Float64
	function Termination(quantity, value; comparison = nothing)
		@info quantity
		@info value
		return new{}(quantity, comparison, value)
	end
end

struct CurrentStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct VoltageStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct RestStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	direction::Union{Nothing, String}
	termination::Termination
	timeStepSize::Union{Nothing, Float64}
end

struct CycleStep <: AbstractControlStep
	numberOfCycles::Int
	termination::Union{Nothing, Termination}
	cycleControlSteps::Vector{AbstractControlStep}
end

mutable struct GenericPolicy <: AbstractControl
	controlPolicy::String
	controlsteps::Vector{AbstractControlStep}
	ImaxDischarge::Float64
	ImaxCharge::Float64
	function GenericPolicy(json::Dict)
		steps = [parse_control_step(step) for step in json["controlsteps"]]
		return new(json["controlPolicy"], steps, 0.0, 0.0)  # default Imax values (set later)
	end
end


function parse_control_step(json::Dict)
	ctype = json["controltype"]
	if ctype == "current"
		return CurrentStep(
			json["value"],
			get(json, "direction", nothing),
			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
			get(json, "timeStepSize", nothing))
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

function setup_initial_control_policy!(policy::GenericPolicy, inputparams::InputParams, parameters)

	policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
	policy.ImaxCharge    = only(parameters[:Control][:ImaxCharge])

end

mutable struct GenericController
	policy::GenericPolicy
	current_step::Int
	time_in_step::Float64
	numberOfCycles::Int
end


"""
Function to create (deep) copy of GenericController
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.policy = cv.policy
	cv_copy.current_step = cv.current_step
	cv_copy.time_in_step = cv.time_in_step
	cv_copy.cycles_remaining = cv.cycles_remaining

end

"""
Overload function to copy GenericController
"""
function Base.copy(cv::GenericController)

	cv_copy = GenericController()
	copyController!(cv_copy, cv)

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

	copyController!(storage.state[:GenericController], storage.state0[:GenericController])
end


#######################################
# Helper functions for control switch #
#######################################

"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::GenericPolicy, controller::GenericController, state)
	step = policy.controlsteps[controller.current_step]
	termination = step.termination

	E = only(state.Phi)
	I = only(state.Current)

	before = false
	after = false

	if termination.quantity == "voltage"
		target = termination.value
		tol = 1e-4  # Adjust or pull from policy.tolerances if defined

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

		if isnothing(termination.comparison) || termination.comparison == "below"
			before = abs(I) > target * (1 + tol)
			after  = abs(I) < target * (1 - tol)
		elseif termination.comparison == "above"
			before = abs(I) < target * (1 - tol)
			after  = abs(I) > target * (1 + tol)
		end

	elseif termination.quantity == "time"
		t = controller.time_in_step
		target = termination.value
		tol = 1e-6

		before = t < target - tol
		after  = t > target + tol

	else
		error("Unsupported termination quantity: $(termination.quantity)")
	end

	return (beforeSwitchRegion = before, afterSwitchRegion = after)
end


"""
Implementation of the generic control policy
"""
function update_control_type_in_controller!(state, state0, policy::GenericPolicy, dt)

	E  = only(value(state[:Phi]))
	I  = only(value(state[:Current]))
	E0 = only(value(state0[:Phi]))
	I0 = only(value(state0[:Current]))

	controller = state.ControllerCV

	# Update time and rates of change
	controller.time = state0.ControllerCV.time + dt
	controller.dIdt = (I - I0) / dt
	controller.dEdt = (E - E0) / dt

	# Get control step info
	step_idx = controller.current_step
	control_steps = policy.controlsteps

	# Stay within bounds of control steps
	if step_idx > length(control_steps)
		error("Step index $step_idx exceeds number of control steps $(length(control_steps))")
	end

	step = control_steps[step_idx]

	# Check if we should switch to next step based on region switch flags
	rsw0 = setupRegionSwitchFlags(step, state0, controller)
	rsw  = setupRegionSwitchFlags(step, state, controller)

	if rsw0.beforeSwitchRegion
		# Stay in current control step
		next_step_idx = step_idx
	else
		if controller.current_step == controller.current_step0  # Control hasn't changed in current iteration
			if rsw.afterSwitchRegion
				next_step_idx = step_idx + 1
			else
				next_step_idx = step_idx
			end
		elseif controller.current_step == step_idx + 1
			# Avoid switching back if we already moved forward in this Newton iteration
			next_step_idx = step_idx + 1
		else
			error("Unexpected control state transition at step $step_idx")
		end
	end

	# Update controller with the selected step index
	controller.current_step = min(next_step_idx, length(control_steps))  # Stay within bounds

end


"""
Update controller target value (current or voltage) based on the active control step
"""
function update_values_in_controller!(state, policy::GenericPolicy)

	controller = state[:GenericController]
	step_idx = controller.current_step

	control_steps = policy.controlsteps

	if step_idx > length(control_steps)
		error("Step index $step_idx exceeds number of control steps $(length(control_steps))")
	end

	step = control_steps[step_idx]

	if step isa CurrentStep
		target = step.value
		target_is_voltage = false

	elseif step isa VoltageStep
		target = step.value
		target_is_voltage = true

	elseif step isa RestStep
		# Assume voltage hold during rest
		target = isnothing(step.value) ? only(state[:Phi]) : step.value
		target_is_voltage = true

	else
		error("Unsupported step type: $(typeof(step))")
	end

	controller.target_is_voltage = target_is_voltage
	controller.target            = target

end

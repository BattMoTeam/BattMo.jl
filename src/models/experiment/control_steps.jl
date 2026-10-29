#######################################################################################################################
# Control steps
#
# This script defines different control step types:
#	- CurrentStep: current controlled control step
#	- VoltageStep: voltage controlled control step
#	- RestStep: control step where the current is set to zero
#	- PowerStep: power controlled control step
#	- CurrentFunctionStep: the current is given by a function of time and voltage
#	- CurrentSeriesStep: the current is interpolated from a time series, with voltage limits
#
# The control steps are set up from their json description, see setup_control_step in generic_protocol.jl
#######################################################################################################################

##################################################
# Define the abstract type

abstract type AbstractControlStep end


##################################################
# Define the different control step types

"""
Constant current, given in A or, if `is_c_rate` is true, as a C-rate. A C-rate is converted to a current with the
capacity parameter of the control model, see the control equation. If `use_ramp_up` is true, the current is ramped up
at the beginning of the simulation.
"""
struct CurrentStep{R} <: AbstractControlStep
	value::R
	is_c_rate::Bool
	direction::String
	termination::AbstractTerminationCriterion
	use_ramp_up::Bool
	ramp_up_time::Float64
end

function CurrentStep(value, direction, termination; is_c_rate = false, use_ramp_up = false, ramp_up_time = 0.0)
	return CurrentStep(value, is_c_rate, direction, termination, use_ramp_up, Float64(ramp_up_time))
end

struct VoltageStep{R} <: AbstractControlStep
	value::R
	termination::AbstractTerminationCriterion
	voltage_function::Function

	function VoltageStep(value, termination, voltage_function = setup_voltage_function(value))
		return new{typeof(value)}(value, termination, voltage_function)
	end
end

mutable struct RestStep{R} <: AbstractControlStep
	value::R
	termination::AbstractTerminationCriterion
end

struct PowerStep{R} <: AbstractControlStep
	value::Union{Nothing, R}
	direction::Union{Nothing, String}
	termination::AbstractTerminationCriterion
	power_function::Function

	function PowerStep(value, direction, termination, voltage_function = setup_power_function(value))
		return new{typeof(value)}(value, direction, termination, voltage_function)
	end
end

"""
The current is given by a function `current_function(time, voltage)` where time is the time since the start of the
step. The current is positive for discharge.
"""
struct CurrentFunctionStep <: AbstractControlStep
	current_function::Function
	termination::AbstractTerminationCriterion
end

"""
The current is interpolated from a time series, where the times are relative to the start of the step. The current is
positive for discharge. When the voltage reaches the lower limit during discharge or the upper limit during charge,
the step switches to voltage control at the limit.
"""
struct CurrentSeriesStep{R} <: AbstractControlStep
	current_function::Any # interpolator, callable as current_function(time)
	lower_voltage_limit::R
	upper_voltage_limit::R
	termination::AbstractTerminationCriterion
end

function CurrentSeriesStep(times::AbstractVector, currents::AbstractVector, lower_voltage_limit, upper_voltage_limit, termination)

	@assert length(times) == length(currents) "Times and Currents must have the same length"
	@assert length(times) >= 1 "Times and Currents must be non-empty"
	@assert issorted(times, lt = <) "Times must be strictly increasing"

	R = promote_type(eltype(times), eltype(currents), typeof(lower_voltage_limit), typeof(upper_voltage_limit))
	current_function = get_1d_interpolator(convert(Vector{R}, times), convert(Vector{R}, currents), cap_endpoints = true)

	return CurrentSeriesStep{R}(current_function, R(lower_voltage_limit), R(upper_voltage_limit), termination)
end



###########################################################################
# Value of a CurrentStep at a given time (in A or as C-rate, see CurrentStep), including the ramp up and the sign

function get_current_value(step::CurrentStep, time::Real)

	time, current, ramp_up_time = promote(time, step.value, step.ramp_up_time)

	if step.use_ramp_up && time <= ramp_up_time
		value = sineup(0.0, current, 0.0, ramp_up_time, time)
	else
		value = current
	end

	return adjust_current_sign(value, step.direction)
end


###########################################################################
# Setup the voltage function that determines the voltage for a VoltageStep

function setup_voltage_function(voltage)

	voltage_function(time) = voltage

	return voltage_function

end


###########################################################################
# Setup the power function that determines the power for a PowerStep

function setup_power_function(power)

	power_function(time) = power

	return power_function

end

##################################################
# Get initial current values. The capacity (in Ah) is used for C-rates.

function get_initial_current(step::CurrentStep, capacity)
	value = get_current_value(step, 0.0)
	return step.is_c_rate ? value * capacity : value
end

# For power, voltage and function control, the current is not known before solving. Zero is used as initial guess.

get_initial_current(step::AbstractControlStep, capacity) = 0.0

function get_initial_current(step::CurrentSeriesStep, capacity)
	return step.current_function(0.0)
end


##################################################
# Maximum current of a step, used to limit the Newton updates of the current. Zero means unknown.

maximum_current(step::AbstractControlStep, capacity) = 0.0
maximum_current(step::CurrentStep, capacity) = step.is_c_rate ? abs(step.value * capacity) : abs(step.value)


##################################################
# Update the controller
#
# Given the control step, the target value of the control equation is set in the controller, together with whether
# the target is a voltage or a current.

function update_values_in_controller!(state, state0, step::PowerStep)

	power = step.value
	voltage = state.Controller.voltage

	current = power / voltage

	state.Controller.target = adjust_current_sign(current, step.direction)
	state.Controller.target_is_voltage = false

end

function update_values_in_controller!(state, state0, step::CurrentStep)

	# The ramp up is applied with respect to the simulation time, so that only a current step at the beginning of
	# the simulation is ramped up
	state.Controller.target = get_current_value(step, state.Controller.time)
	state.Controller.target_is_voltage = false
	state.Controller.target_is_c_rate = step.is_c_rate

end

function update_values_in_controller!(state, state0, step::VoltageStep)
	state.Controller.target = step.value
	state.Controller.target_is_voltage = true
end

function update_values_in_controller!(state, state0, step::RestStep)
	state.Controller.target = step.value
	state.Controller.target_is_voltage = false
end

function update_values_in_controller!(state, state0, step::CurrentFunctionStep)

	controller = state.Controller
	time = controller.time - controller.step_start_time

	controller.target = step.current_function(time, controller.voltage)
	controller.target_is_voltage = false

end

function update_values_in_controller!(state, state0, step::CurrentSeriesStep)

	# Relative tolerance for voltage hysteresis: if the voltage is within this fraction of the limit, we remain in
	# voltage control to avoid oscillating between current and voltage control during the Newton iterations.
	hysteresis_tolerance = 1.0e-4

	controller = state.Controller
	time = controller.time - controller.step_start_time
	E = controller.voltage

	current = step.current_function(time)

	# Determine which voltage limit is relevant based on the sign of the prescribed current, then check whether the
	# voltage has crossed that limit.
	if current > 0
		target_is_voltage = E <= step.lower_voltage_limit
	elseif current < 0
		target_is_voltage = E >= step.upper_voltage_limit
	else
		target_is_voltage = false
	end

	# Hysteresis: if the step was already in voltage control in the previous converged state, stay in voltage control
	# as long as the limit is still binding.
	controller0 = state0.Controller
	if controller0.step_count == controller.step_count && controller0.target_is_voltage && !target_is_voltage
		if current > 0 && E <= step.lower_voltage_limit * (1 + hysteresis_tolerance)
			target_is_voltage = true
		elseif current < 0 && E >= step.upper_voltage_limit * (1 - hysteresis_tolerance)
			target_is_voltage = true
		end
	end

	if target_is_voltage
		controller.target = current >= 0 ? step.lower_voltage_limit : step.upper_voltage_limit
	else
		controller.target = current
	end
	controller.target_is_voltage = target_is_voltage

end

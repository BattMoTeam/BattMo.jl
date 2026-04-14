#######################################################################################################################
# Control steps
#
# This script defines different control step types:
#	- CurrentStep: current controlled control step
#	- VoltageStep: voltage controlled control step
#	- RestStep: control step where the current is set to zero
#	- PowerStep: power controlled control step
#	- StateOfChargeStep: SOC controlled control step
#######################################################################################################################

##################################################
# Define the abstract type

abstract type AbstractControlStep end


##################################################
# Define the different control step types

struct CurrentStep{R} <: AbstractControlStep
	value::Union{R, AbstractString}
	direction::Union{String}
	termination::AbstractTerminationCriterion
	current_function::Function

	function CurrentStep(value, direction, termination, use_ramp_up; ramp_up_time = nothing, current_function = setup_current_function(value, ramp_up_time, use_ramp_up; direction))
		return new{typeof(value)}(value, direction, termination, current_function)
	end
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

mutable struct StateOfChargeStep{R} <: AbstractControlStep
	value::R
	termination::AbstractTerminationCriterion
end



###########################################################################
# Setup the current function that determines the current fot a CurrentStep

function setup_current_function(current, ramp_up_time, use_ramp_up; direction = "discharging")

	current_function(time) = get_current_value(time, current, ramp_up_time; use_ramp_up = use_ramp_up, direction)

	return current_function

end

function get_current_value(time::Real, current::Real, ramp_up_time::Real = 0.1; use_ramp_up = true, direction = "discharging")

	if current isa AbstractString
		time, ramp_up_time, value = promote(time, ramp_up_time, 0.0)

		func = setup_function_from_function_name(current)

		value_signed = func(time)

	elseif current isa Real
		time, current, ramp_up_time, value = promote(time, current, ramp_up_time, 0.0)
		if use_ramp_up == false
			value = current
		else
			if time <= ramp_up_time
				value = sineup(0.0, current, 0.0, ramp_up_time, time)
			else
				value = current
			end
		end
		value_signed = adjust_current_sign(value, direction)
	else
		error("Type $(typeof(current)) not handled.")
	end

	return value_signed
end


###########################################################################
# Setup the voltage function that determines the voltage for a VoltageStep

function setup_voltage_function(voltage)

	voltage_function(time) = get_voltage_value(time, voltage)

	return voltage_function

end

function get_voltage_value(time::Real, voltage::Real)
	if voltage isa AbstractString
		time, value = promote(time, 0.0)

		func = setup_function_from_function_name(voltage)

		value = func(time)

	elseif voltage isa Real
		time, voltage, value = promote(time, voltage, 0.0)

		value = voltage
	else
		error("Type $(typeof(voltage)) not handled.")
	end
	return value
end


###########################################################################
# Setup the power function that determines the power for a PowerStep

function setup_power_function(voltage)

	power_function(time) = get_power_value(time, voltage)

	return power_function

end

function get_power_value(time::Real, power::Real)
	if power isa AbstractString
		time, value = promote(time, 0.0)


		func = setup_function_from_function_name(power)

		value = func(time)

	elseif power isa Real
		time, power, value = promote(time, power, 0.0)

		value = power
	else
		error("Type $(typeof(power)) not handled.")
	end
	return value
end

##################################################
# Get initial current values

function get_initial_current(step::CurrentStep)
	return step.current_function(0.0)
end

function get_initial_current(step::PowerStep)
	error("Power control cannot be the first control step")
end

function get_initial_current(step::VoltageStep)
	error("Voltage control cannot be the first control step")
end

function get_initial_current(step::StateOfChargeStep)
	error("State of charge control cannot be the first control step")
end

function get_initial_current(step::RestStep)
	return 0.0
end


##################################################
# Update the controller

function update_values_in_controller!(state, step::PowerStep)

	power = step.value
	voltage = state.Controller.voltage

	current = power/voltage

	state.Controller.target = adjust_current_sign(current, step.direction)

end

function update_values_in_controller!(state, step::StateOfChargeStep)

	state_of_charge = step.value
	voltage = state.Controller.voltage

	state.Controller.target = voltage

end

function update_values_in_controller!(state, step::CurrentStep)


	current_function = step.current_function

	current = current_function(state.Controller.time)

	state.Controller.target = current

end

function update_values_in_controller!(state, step::VoltageStep)
	state.Controller.target = step.value

end

function update_values_in_controller!(state, step::RestStep)
	state.Controller.target = step.value

end

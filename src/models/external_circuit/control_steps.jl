abstract type AbstractControlStep end

struct CurrentStep <: AbstractControlStep
	value::Real
	direction::Union{String}
	termination::Termination
	current_function::Function

	function CurrentStep(value, direction, termination, use_ramp_up; ramp_up_time = nothing, current_function = setup_current_function(value, ramp_up_time, use_ramp_up))
		return new(value, direction, termination, current_function)
	end
end

struct VoltageStep <: AbstractControlStep
	value::Real
	termination::Termination
end

mutable struct RestStep <: AbstractControlStep
	value::Union{Nothing, Real}
	termination::Termination
end

mutable struct PowerStep <: AbstractControlStep
	value::Union{Nothing, Real}
	direction::Union{Nothing, String}
	termination::Termination
end


function setup_current_function(I, ramp_up_time, use_ramp_up)

	current_function(time) = get_current_value(time, I, ramp_up_time; use_ramp_up = use_ramp_up)

	return current_function

end


function get_initial_current(step::CurrentStep)

	if !ismissing(step.current_function)
		I = step.current_function(0.0)
	else
		if step.direction == "discharging"
			I = step.value
		elseif step.direction == "charging"
			I = -step.value
		else
			error("Initial control direction not recognized")
		end
	end
	return I
end


function get_initial_current(step::VoltageStep)
	error("Voltage control cannot be the first control step")
end

function get_initial_current(step::RestStep)
	return 0.0
end
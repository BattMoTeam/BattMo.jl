abstract type AbstractControlStep end

mutable struct CurrentStep <: AbstractControlStep
	value::Float64
	direction::Union{String, Nothing}
	termination::Termination
	current_function::Union{Missing, Any}

	function CurrentStep(value, direction, termination; current_function = setup_current_function())
		return new(value, direction, termination, current_function)
	end
end

struct VoltageStep <: AbstractControlStep
	value::Float64
	termination::Termination
end

mutable struct RestStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	termination::Termination
end

mutable struct PowerStep <: AbstractControlStep
	value::Union{Nothing, Float64}
	direction::Union{Nothing, String}
	termination::Termination
end


function setup_current_function()

	tup = Float64(input.simulation_settings["RampUpTime"])
	Imax = control.value
	cFun(time) = currentFun(time, Imax, tup)

	return c

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


export convert_experiment_to_battmo_control_input

struct Experiment <: AbstractProtocol
	all::Vector{Any}

end

function parse_experiment_step(step::String, capacity::Real, use_ramp_up::Bool; ramp_up_time = 0.1)
	increase_cycle_count = false
	number_of_repeats = nothing
	step_instance = nothing

	if containsi(step, "Rest")
		values, units = extract_numeric_values(step)

		value1, quantity1 = type_to_unit(values[1], string(units[1]))

		termination = get_termination_instance(quantity1, value1)

		step_instance = RestStep(0.0, termination)

	elseif containsi(step, "Discharge") || containsi(step, "Charge")
		direction = containsi(step, "Discharge") ? "discharging" : "charging"

		values, units = extract_numeric_values(step)
		value1, quantity1 = type_to_unit(values[1], units[1]; capacity)
		value2, quantity2 = type_to_unit(values[2], units[2])

		termination = get_termination_instance(quantity2, value2; direction = direction)

		if quantity1 == "Current"
			step_instance = CurrentStep(value1, direction, termination, use_ramp_up; ramp_up_time)
		elseif quantity1 == "Power"
			step_instance = PowerStep(value1, direction, termination)
		else
			error("Quantity $quantity1 is not recognized as control step for a charge or discharge.")
		end

	elseif containsi(step, "Hold")
		values, units = extract_numeric_values(step)
		value1, quantity1 = type_to_unit(values[1], units[1])
		value2, quantity2 = type_to_unit(values[2], units[2])

		termination = get_termination_instance(quantity2, value2)

		step_instance = VoltageStep(value1, termination)

	elseif containsi(step, "Increase cycle count")
		increase_cycle_count = true

	elseif containsi(step, "Repeat")
		number_of_repeats = Base.parse(Int, match(r"\d+", step).match)
	else
		error("Unknown control step: $step")
	end

	return step_instance, increase_cycle_count, number_of_repeats

end



function extract_numeric_values(str::AbstractString)
	# Pattern: number (decimal, scientific, or fraction) + unit + optional extra words
	pattern = r"((?:[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?|[0-9]+/[0-9]+))\s*([a-zA-Z]+(?:\s+[a-zA-Z]+)*)"
	matches = collect(eachmatch(pattern, str))

	# Parse numbers: handle fractions separately
	values = [occursin("/", m.captures[1]) ?
			  Base.parse(Float64, split(m.captures[1], "/")[1]) / Base.parse(Float64, split(m.captures[1], "/")[2]) :
			  Base.parse(Float64, m.captures[1]) for m in matches]

	# Units: keep first word for first match, full unit for others
	units = if length(matches) > 1
		[i == 1 ? split(m.captures[2])[1] : m.captures[2] for (i, m) in enumerate(matches)]
	else
		[m.captures[2] for m in matches]
	end

	return values, units
end




function type_to_unit(value::Float64, unit::AbstractString; capacity = nothing)
	if containsi(unit, "V")
		quantity = containsi(unit, "change") ? "VoltageChange" : "Voltage"
		return convert_to_V(value, unit), quantity
	elseif containsi(unit, "A")
		quantity = containsi(unit, "change") ? "CurrentChange" : "Current"
		return convert_to_A(value, unit), quantity
	elseif any(tu -> containsi(unit, tu), time_units())
		return convert_to_seconds(value, unit), "Time"
	elseif containsi(unit, "W")
		return convert_to_W(value, unit), "Power"
	elseif containsi(unit, "C")
		return convert_to_A(value, unit; capacity), "Current"
	else
		error("Unknown unit: $unit")
	end
end

function time_units()
	return ["s", "second", "seconds", "min", "minute", "minutes", "mins", "h", "hour", "hours"]
end

function convert_to_seconds(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit_lower = lowercase(unit)
	if unit_lower in ["s", "second", "seconds"]
		return value
	elseif unit_lower in ["min", "minute", "minutes", "mins"]
		return value * 60
	elseif unit_lower in ["h", "hour", "hours"]
		return value * 3600
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_V(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit_part = containsi(unit, "change") ? split(unit)[1] : unit

	if unit_part == "V"
		return value
	elseif unit_part == "mV"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_A(value::Float64, unit::AbstractString; capacity = nothing)
	@assert isa(value, Number)
	unit_part = containsi(unit, "change") ? split(unit)[1] : unit
	if unit_part == "A"
		return value
	elseif unit_part == "mA"
		return value * 1e-3
	elseif unit_part == "C"
		con = Constants()

		value = capacity * value

		return value
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_W(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	if unit == "W"
		return value
	elseif unit == "mW"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function containsi(a::AbstractString, b::AbstractString)
	return occursin(Regex(b, "i"), a)
end


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
	# Pattern: number + valid unit (letters, optional /letters)
	pattern = r"((?:[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?|[0-9]+/[0-9]+))\s*([a-zA-Z]+(?:/[a-zA-Z]+)?)"
	matches = collect(eachmatch(pattern, str))

	values = [occursin("/", m.captures[1]) ?
			  Base.parse(Float64, split(m.captures[1], "/")[1]) / Base.parse(Float64, split(m.captures[1], "/")[2]) :
			  Base.parse(Float64, m.captures[1]) for m in matches]

	units = [strip(m.captures[2]) for m in matches]

	return values, units

end




function type_to_unit(value::Float64, unit::AbstractString; capacity = nothing)
	if containsi(unit, "V")
		if containsi(unit, "V/")
			quantity = "VoltageChange"
			@info "unit", unit
			@info "quantity", quantity
			return convert_to_V_s(value, unit), quantity
		else
			quantity = "Voltage"
			return convert_to_V(value, unit), quantity
		end
	elseif containsi(unit, "A")
		if containsi(unit, "A/")
			quantity = "CurrentChange"
			return convert_to_A_s(value, unit), quantity
		else
			quantity = "Current"
			return convert_to_A(value, unit), quantity
		end
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
	unit_part = unit

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
	unit_part = unit
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


function convert_to_V_s(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit = strip(unit)

	parts = split(unit, '/')
	if length(parts) != 2
		error("Invalid unit format for voltage change: $unit")
	end

	voltage_unit = parts[1]
	time_unit = parts[2]

	# Use existing conversion functions
	voltage_in_volts = convert_to_V(1.0, voltage_unit)  # scale factor for voltage
	time_in_seconds = convert_to_seconds(1.0, time_unit) # scale factor for time

	return value * voltage_in_volts / time_in_seconds
end


function convert_to_A_s(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit = strip(unit)

	parts = split(unit, '/')
	if length(parts) != 2
		error("Invalid unit format for current change: $unit")
	end

	current_unit = parts[1]
	time_unit = parts[2]

	# Use existing conversion functions
	current_in_amperes = convert_to_A(1.0, current_unit)  # scale factor for current
	time_in_seconds = convert_to_seconds(1.0, time_unit) # scale factor for time

	return value * current_in_amperes / time_in_seconds
end


function containsi(a::AbstractString, b::AbstractString)
	return occursin(Regex(b, "i"), a)
end

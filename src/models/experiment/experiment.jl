#######################################################################################################################
# Experiment strings
#
# The experiment API lets the user describe a cycling protocol with strings such as
#
#	"Charge at 1 A until 4.0 V"
#	"Hold at 4.0 V until 1e-4 A/s"
#	"Discharge at 0.5 C until 3.0 V or until 2 hours"
#	"Rest for 30 minutes"
#	"Repeat 2 times"
#
# This script converts a list of experiment strings into the json control step structure that is described by the
# control step schema (see get_schema_control_steps). The control steps are then validated and turned into a
# GenericProtocol, in the same way as control steps given directly in json.
#
# "Repeat N times" repeats all the previous entries of the list (or of the sub-list it belongs to) N more times. It is
# converted into a "Cycle" control step.
#
#######################################################################################################################

export experiment_to_control_steps


"""
	experiment_to_control_steps(experiment_list)

Convert a list of experiment strings into a list of control steps following the control step schema. An entry of the
list can itself be a list of experiment strings, in which case a "Repeat" within that sub-list only repeats the
entries of the sub-list.
"""
function experiment_to_control_steps(experiment_list)

	if experiment_list isa AbstractString
		experiment_list = [experiment_list]
	end

	control_steps = Vector{Dict{String, Any}}()

	# The direction of the last charge or discharge step is used to choose the comparison of rest and hold terminations
	last_direction = Ref{Union{Nothing, String}}(nothing)

	add_experiment_control_steps!(control_steps, experiment_list, last_direction)

	return control_steps
end


function add_experiment_control_steps!(control_steps, experiment_list, last_direction)

	for entry in experiment_list

		if entry isa AbstractString

			if containsi(entry, "Repeat")

				number_of_repeats = Base.parse(Int, match(r"\d+", entry).match)

				if isempty(control_steps)
					error("\"$entry\" has no previous experiment steps to repeat.")
				end

				repeated_steps = copy(control_steps)
				empty!(control_steps)
				push!(control_steps, Dict{String, Any}(
					"ControlType" => "Cycle",
					"NumberOfCycles" => number_of_repeats + 1,
					"ControlSteps" => repeated_steps,
				))

			elseif containsi(entry, "Increase cycle count")

				error("\"Increase cycle count\" is not supported. Use \"Repeat N times\" instead, each repetition is counted as a cycle.")

			else
				push!(control_steps, parse_experiment_step(entry, last_direction))
			end

		elseif entry isa AbstractVector

			# A sub-list: a repeat inside the sub-list only repeats the entries of the sub-list
			sub_steps = Vector{Dict{String, Any}}()
			add_experiment_control_steps!(sub_steps, entry, last_direction)
			append!(control_steps, sub_steps)

		else
			error("Experiment step must be a String or a Vector, got $(typeof(entry)).")
		end
	end

	return control_steps
end


"""
	parse_experiment_step(step, last_direction)

Convert one experiment string into a control step dictionary.
"""
function parse_experiment_step(step::AbstractString, last_direction)

	parts = split(step)

	if containsi(parts[1], "Rest")

		termination = parse_terminations(step, parts, 2, "Rest", last_direction[])

		return Dict{String, Any}("ControlType" => "Rest", "Termination" => termination)

	elseif containsi(parts[1], "Discharge") || containsi(parts[1], "Charge")

		check_word(step, parts, 2, "at")

		direction = containsi(parts[1], "Discharge") ? "discharging" : "charging"
		value = parse_number_or_fraction(parts[3])
		unit = parts[4]

		control_step = Dict{String, Any}("Direction" => direction)

		if unit == "C"
			control_step["ControlType"] = "Current"
			control_step["CRate"] = value
		elseif unit in ["A", "mA"]
			control_step["ControlType"] = "Current"
			control_step["Value"] = convert_to_A(value, unit)
		elseif unit in ["W", "mW"]
			control_step["ControlType"] = "Power"
			control_step["Value"] = convert_to_W(value, unit)
		else
			error("Unit $unit in \"$step\" not recognized. A charge or discharge is controlled in A, mA, C, W or mW.")
		end

		control_step["Termination"] = parse_terminations(step, parts, 5, direction, last_direction[])

		last_direction[] = direction

		return control_step

	elseif containsi(parts[1], "Hold")

		check_word(step, parts, 2, "at")

		value = parse_number_or_fraction(parts[3])
		unit = parts[4]

		if unit in ["V", "mV"]
			voltage = convert_to_V(value, unit)
		elseif containsi(unit, "SOC")
			error("Holding at a state of charge (\"$step\") is not supported. Use a voltage hold instead.")
		else
			error("Unit $unit in \"$step\" not recognized. A hold is controlled in V or mV.")
		end

		termination = parse_terminations(step, parts, 5, "Hold", last_direction[])

		return Dict{String, Any}("ControlType" => "Voltage", "Value" => voltage, "Termination" => termination)

	else
		error("Unknown control step: \"$step\"")
	end

end


"""
Parse the termination part of an experiment string starting at index `start`, for instance "until 4.0 V" or
"until 4.0 V or until 1 hour". Returns a termination dictionary, or a list of them when the conditions are combined
with "or".
"""
function parse_terminations(step, parts, start, step_type, last_direction)

	terminations = Dict{String, Any}[]

	index = start
	while true

		if length(parts) < index + 2 || !(parts[index] in ["for", "until"])
			error("The termination of \"$step\" does not have the correct structure. Expected for example \"until 4.0 V\" or \"for 1 hour\".")
		end

		value = parse_number_or_fraction(parts[index + 1])
		unit = parts[index + 2]

		push!(terminations, parse_termination(value, unit, step_type, last_direction))

		index += 3

		if index > length(parts)
			break
		end

		check_word(step, parts, index, "or")
		index += 1
	end

	return length(terminations) == 1 ? terminations[1] : terminations
end


function parse_termination(value, unit, step_type, last_direction)

	quantity, value = unit_to_termination_quantity(value, unit)

	termination = Dict{String, Any}("Quantity" => quantity, "Value" => value)

	if quantity != "Time"
		termination["Comparison"] = default_comparison(quantity, step_type, last_direction)
	end

	return termination
end


"""
Default comparison for a termination of an experiment string. During a charge, the voltage and state of charge
increase. During a discharge, they decrease. During a rest the voltage relaxes in the direction opposite to the
previous charge or discharge. Currents and change rates decay in absolute value.
"""
function default_comparison(quantity, step_type, last_direction)

	if quantity in ["Current", "CRate", "VoltageChange", "CurrentChange"]
		return "absolute value below"
	end

	if step_type in ["charging", "discharging"]
		direction = step_type
	elseif step_type == "Rest" && quantity == "Voltage"
		direction = isnothing(last_direction) ? nothing : get_opposite_direction(last_direction)
	else
		direction = last_direction
	end

	return direction == "charging" ? "above" : "below"
end


function unit_to_termination_quantity(value, unit)

	if any(tu -> lowercase(unit) == lowercase(tu), time_units())
		return "Time", convert_to_seconds(value, unit)
	elseif occursin("/", unit)
		if startswith(unit, "V") || startswith(unit, "mV")
			return "VoltageChange", convert_to_V_s(value, unit)
		elseif startswith(unit, "A") || startswith(unit, "mA")
			return "CurrentChange", convert_to_A_s(value, unit)
		end
	elseif unit in ["V", "mV"]
		return "Voltage", convert_to_V(value, unit)
	elseif unit in ["A", "mA"]
		return "Current", convert_to_A(value, unit)
	elseif unit == "C"
		return "CRate", value
	elseif containsi(unit, "SOC")
		return "StateOfCharge", value
	end

	error("Unknown termination unit: $unit")
end


function check_word(step, parts, index, word)
	if length(parts) < index || parts[index] != word
		error("Expected \"$word\" at position $index in \"$step\".")
	end
end


function parse_number_or_fraction(s::AbstractString)::Float64
	s = strip(s)
	if occursin('/', s)
		a, b = split(s, '/'; limit = 2)
		return Base.parse(Float64, strip(a)) / Base.parse(Float64, strip(b))
	else
		return Base.parse(Float64, s)  # handles "0.5", "1e-3", etc.
	end
end


function time_units()
	return ["s", "second", "seconds", "min", "minute", "minutes", "mins", "h", "hour", "hours"]
end

function convert_to_seconds(value::Float64, unit::AbstractString)
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
	if unit == "V"
		return value
	elseif unit == "mV"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_A(value::Float64, unit::AbstractString)
	if unit == "A"
		return value
	elseif unit == "mA"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_W(value::Float64, unit::AbstractString)
	if unit == "W"
		return value
	elseif unit == "mW"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end


function convert_to_V_s(value::Float64, unit::AbstractString)
	parts = split(strip(unit), '/')
	if length(parts) != 2
		error("Invalid unit format for voltage change: $unit")
	end

	voltage_in_volts = convert_to_V(1.0, parts[1])  # scale factor for voltage
	time_in_seconds = convert_to_seconds(1.0, parts[2]) # scale factor for time

	return value * voltage_in_volts / time_in_seconds
end


function convert_to_A_s(value::Float64, unit::AbstractString)
	parts = split(strip(unit), '/')
	if length(parts) != 2
		error("Invalid unit format for current change: $unit")
	end

	current_in_amperes = convert_to_A(1.0, parts[1])  # scale factor for current
	time_in_seconds = convert_to_seconds(1.0, parts[2]) # scale factor for time

	return value * current_in_amperes / time_in_seconds
end


function containsi(a::AbstractString, b::AbstractString)
	return occursin(Regex(b, "i"), a)
end

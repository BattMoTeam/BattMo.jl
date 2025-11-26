
export convert_experiment_to_battmo_control_input

function convert_experiment_to_battmo_control_input(experiment)
	experiment_list = experiment
	if isa(experiment_list, String)
		experiment_list = [experiment_list]
	end

	controlsteps = []

	for step in experiment_list

		step_dict = Dict{String, Any}()



		if containsi(step, "Rest")
			values, units = extract_numeric_values(step)
			value = convert_to_seconds(values[1], units[1])
			step_dict["controltype"] = "rest"
			step_dict["termination"] = Dict("quantity" => "time", "value" => value)
			step_dict["timeStepSize"] = 600

		elseif containsi(step, "Discharge") || containsi(step, "Charge")
			direction = containsi(step, "Discharge") ? "discharging" : "charging"
			comparison = containsi(step, "Discharge") ? "below" : "above"

			values, units = extract_numeric_values(step)
			value1, quantity1 = type_to_unit(values[1], units[1])
			@assert lowercase(quantity1) == "current" "Cannot $direction with $quantity1, can only use current"

			value2, quantity2 = type_to_unit(values[2], units[2])
			step_dict["controltype"] = quantity1
			step_dict["value"] = value1
			step_dict["direction"] = direction
			step_dict["termination"] = Dict("quantity" => quantity2, "value" => value2, "comparison" => comparison)
			step_dict["timeStepSize"] = 600

		elseif containsi(step, "Hold")
			values, units = extract_numeric_values(step)
			value1 = convert_to_V(values[1], units[1])
			value2, quantity2 = type_to_unit(values[2], units[2])
			step_dict["controltype"] = "voltage"
			step_dict["value"] = value1
			step_dict["termination"] = Dict("quantity" => quantity2, "value" => value2, "comparison" => "absolute value below")
			step_dict["timeStepSize"] = 600

		else
			error("Unknown control step: $step")
		end

		push!(controlsteps, step_dict)

	end

	return Dict("Control" => Dict("controlPolicy" => "Generic", "controlsteps" => controlsteps))
end



function extract_numeric_values(str::AbstractString)
	# Pattern: number + unit + optional extra words
	pattern = r"([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\s*([a-zA-Z]+(?:\s+[a-zA-Z]+)*)"
	matches = collect(eachmatch(pattern, str))

	# Convert SubString to String before parsing
	values = [Base.parse(Float64, String(m.captures[1])) for m in matches]

	# First unit: only first word; others: full unit string
	units = [
		i == 1 ? split(String(m.captures[2]))[1] : String(m.captures[2])
		for (i, m) in enumerate(matches)
	]

	return values, units
end



function type_to_unit(value::Float64, unit::AbstractString)
	if containsi(unit, "V")
		quantity = containsi(unit, "change") ? "VoltageChange" : "Voltage"
		return convert_to_V(value, unit), quantity
	elseif containsi(unit, "A")
		quantity = containsi(unit, "change") ? "CurrentChange" : "Current"
		println("unit =", unit)
		println("val =", value)
		println("quant =", quantity)
		return convert_to_A(value, unit), quantity
	elseif any(tu -> containsi(unit, tu), time_units())
		return convert_to_seconds(value, unit), "Time"

	elseif containsi(unit, "W")
		return convert_to_W(value, unit), "Power"
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

function convert_to_A(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit_part = containsi(unit, "change") ? split(unit)[1] : unit
	if unit_part == "A"
		return value
	elseif unit_part == "mA"
		return value * 1e-3
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

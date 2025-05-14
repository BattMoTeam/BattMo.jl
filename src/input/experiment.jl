export Experiment
export convert_experiment_to_battmo_control_input

abstract type AbstractExperiment end

struct Experiment <: AbstractExperiment
	data::Vector{String}
end


function convert_experiment_to_battmo_control_input(experiment::Experiment)
	experiment_list = experiment.data
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
	pattern = r"([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\s*([a-zA-Z]*)"
	matches = collect(eachmatch(pattern, str))
	values = [parse(Float64, m.captures[1]) for m in matches]
	units = [m.captures[2] for m in matches]
	return values, units
end

function type_to_unit(value::Float64, unit::AbstractString)
	if containsi(unit, "V")
		return convert_to_V(value, unit), "voltage"
	elseif containsi(unit, "A")
		return convert_to_A(value, unit), "current"
	elseif containsi(unit, time_units()...)
		return convert_to_seconds(value, unit), "time"
	elseif containsi(unit, "W")
		return convert_to_W(value, unit), "power"
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
	if unit == "V"
		return value
	elseif unit == "mV"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_A(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	if unit == "A"
		return value
	elseif unit == "mA"
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

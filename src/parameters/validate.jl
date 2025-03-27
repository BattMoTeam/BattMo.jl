

export validate_parameter_set


# function validate_parameter_set(inputparams::CellParameters, model::Type{<:SimulationModel})

# 	# Get required fields from the model struct
# 	required_fields = fieldnames(model)

# 	# Check if all required fields are present in inputparams
# 	missing_fields = [field for field in required_fields if !haskey(inputparams, field)]

# 	if isempty(missing_fields)
# 		println("Validation successful: All required parameters are present.")
# 		return true
# 	else
# 		println("Validation failed: Missing parameters - ", missing_fields)
# 		return false
# 	end

# end

abstract type AbstractValidationReport end


"""
	struct SingleIssue
		x::Any
		path::String
		reason::String
		val::Any
	end

"""
struct ValidationReport <: AbstractValidationReport
	issues::Array{SingleIssue, 1}
end



function validate_json(schema::Schema, x)
	return _validate_json(x, schema.data, "")
end

# isvalid(schema::Schema, x) = validate_json(schema, x) === nothing

# # Fallbacks for the opposite argument.
# validate_json(x, schema::Schema) = validate_json(schema, x)
# isvalid(x, schema::Schema) = isvalid(schema, x)

function _validate_json(x, schema, path::String)
	schema = _resolve_refs(schema)
	return _validate_entry_json(x, schema, path)
end

function _validate_entry_json(x, schema::AbstractDict, path)
	issues = []
	for (k, v) in schema
		ret = _validate(x, schema, Val{Symbol(k)}(), v, path)
		if ret !== nothing
			push!(issues, ret)
		end
	end
	return ValidationReport(issues)
end

# function _validate_entry_json(x, schema::Bool, path::String)
# 	if !schema
# 		return SingleIssue(x, path, "schema", schema)
# 	end
# 	return
# end


# Extending the JSONSchema.show function
function show(io::IO, report::ValidationReport)
	if isempty(report.issues)
		println(io, "Validation successful: No issues found.")
	else
		println(io, "Validation failed with $(length(report.issues)) issues:")
		for (i, issue) in enumerate(report.issues)
			println(io, "Issue $i:")
			show(io, issue)  # Calls the existing show function for SingleIssue
			println(io)  # Separate issues with a blank line for readability
		end
	end
end

function parse_path(path::String)
	# Extract everything between the brackets, removing the brackets
	matches = eachmatch(r"\[([^\]]+)\]", path)
	return [strip(String(match.match), ['[', ']']) for match in matches]
end


function get_nested_value(dict::AbstractDict, keys::Vector{SubString{String}}, default = nothing)
	value = dict
	for key in keys
		if isa(value, AbstractDict) && haskey(value, key)
			value = value[key]  # Move deeper into the dictionary
		else
			return default  # Return default if key is missing
		end
	end
	return value  # Return the final value
end

function delete_nested!(dict::AbstractDict, keys::Vector{SubString{String}})
	if length(keys) == 1
		delete!(dict, keys[1])  # Base case: delete the final key
	else
		parent_dict = get(dict, keys[1], nothing)
		if isa(parent_dict, AbstractDict)
			delete_nested!(parent_dict, keys[2:end])  # Recursive call on sub-dictionary
		end
	end
end

function set_nested!(dict::AbstractDict, keys::Vector{SubString{String}}, value)
	if length(keys) == 1
		dict[keys[1]] = value  # Base case: Set the final key to the value
	else
		if !haskey(dict, keys[1]) || !isa(dict[keys[1]], AbstractDict)
			dict[keys[1]] = Dict()  # Ensure intermediate keys are dictionaries
		end
		set_nested!(dict[keys[1]], keys[2:end], value)  # Recursive call on sub-dictionary
	end
end

function validate_parameter_set!(parameters::CellParameters, model_settings::ModelSettings)

	schema = get_schema_cell_parameters(model_settings)
	# Convert schema Dict to JSONSchema object
	schema_obj = Schema(schema)

	parameters_dict = parameters.dict
	# Validate the JSON data
	result = validate_json(schema_obj, parameters_dict)

	@info result

	# Convert result to structured warnings/errors
	for issue in result.issues
		keys = Vector(parse_path(issue.path))  # The key causing the issue
		keyword = issue.reason  # Type of validation error

		if keyword == "required"
			# Missing required key: add default
			default_value = get_nested_value(defaults, keys, nothing)
			if default_value !== nothing
				@warn "Missing required key: '$keys'. Adding default: $default_value"
				set_nested!(parameters_dict, keys, default_value)
			else
				error("Missing required key: '$key' and no default available!")
			end

		elseif keyword == "additionalProperties"
			# Extra non-required key: remove it
			@warn "Removing unknown key: '$keys' from data_dict"
			delete_nested!(parameters_dict, keys)

		elseif keyword == "type"
			# Incorrect type: throw an error
			error("Type error for '$keys'. Expected $(issue.val), got $(issue.x))")

		elseif keyword == "minimum"
			# Out-of-bounds value: warn
			@warn "Value of '$keys' = $(issue.x) is lower than Min: $(issue.val)"

		elseif keyword == "maximum"
			# Out-of-bounds value: warn
			@warn "Value of '$keys' = $(issue.x) is higher then Max: $(issue.val)"

		else
			@warn "Unhandled validation issue: $issue"
		end
	end

	return parameters_dict

end


function get_required_model_settings()

	model_settings = [
		"ModelGeometry",
		"UseThermalModel",
		"UseCurrentCollectors",
		"UseRampUp",
	]

	return model_settings

end

function get_required_simulation_settings(model_geometry, use_thermal, use_cc, use_ramp_up)

	simulation_settings = [
		"Grid",
		"TimeStepDuration",
		"Grid",
	]


end
function get_required_protocol_parameters(protocol)

	if protocol == "GalvanostaticCycling"

		cycling_parameters = [
			"Protocol",
			"TotalNumberOfCycles",
			"CRate",
			"DRate",
			"LowerVoltageLimit",
			"UpperVoltageLimit",
			"StartWithCharge",
			"InitialStateOfCharge",
			"RestingTimeAfterCharge",
			"RestingTimeAfterDischarge",
			"AmbientCelsiusTemperature",
		]


	elseif protocol == "ConstantCurrentConstantVoltageCycling"

		cycling_parameters = [
			"Protocol",
			"TotalNumberOfCycles",
			"CRate",
			"DRate",
			"LowerVoltageLimit",
			"UpperVoltageLimit",
			"StartWithCharge",
			"InitialStateOfCharge",
			"RestingTimeAfterCharge",
			"RestingTimeAfterDischarge",
			"CurrentChangeLimit",
			"VoltageChangeLimit",
			"AmbientCelsiusTemperature",
		]

	elseif isnothing(protocol)

		error("The protocol is not defined.")

	else

		error("Protocol $protocol is not handled")

	end
end

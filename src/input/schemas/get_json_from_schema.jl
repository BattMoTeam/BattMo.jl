export get_empty_cell_parameter_set

function get_empty_cell_parameter_set(model; accept_invalid::Bool = false)
	if accept_invalid == true
		schema = get_schema_cell_parameters(model.model_settings)
		set = generate_empty_parameter_set_from_schema(schema)
		return set
	else
		if model.is_valid == true
			schema = get_schema_cell_parameters(model.model_settings)
			set = generate_empty_parameter_set_from_schema(schema)
			return set
		else
			error("""
				Oops! Your Simulation object is not valid. 🛑

				TIP: Validation happens when instantiating the Simulation object. 
				Check the warnings to see exactly where things went wrong. 🔍

				If you’re confident you know what you're doing, you can bypass the validation result 
				by setting the flag "accept_invalid = true": 

					solve(sim; accept_invalid = true)

				But proceed with caution! 😎 
				""")
		end
	end
end

function get_empty_simulation_settings(model; accept_invalid::Bool = false)
	if accept_invalid == true
		schema = get_schema_simulation_settings(model.model_settings)
		set = generate_empty_parameter_set_from_schema(schema)
		return set
	else
		if model.is_valid == true
			schema = get_schema_simulation_settings(model.model_settings)
			set = generate_empty_parameter_set_from_schema(schema)
			return set
		else
			error("""
				Oops! Your Simulation object is not valid. 🛑

				TIP: Validation happens when instantiating the Simulation object. 
				Check the warnings to see exactly where things went wrong. 🔍

				If you’re confident you know what you're doing, you can bypass the validation result 
				by setting the flag "accept_invalid = true": 

					solve(sim; accept_invalid = true)

				But proceed with caution! 😎 
				""")
		end
	end
end


function generate_empty_parameter_set_from_schema(schema::Dict)
	empty_dict = Dict()

	# Handle the "required" fields
	if haskey(schema, "required")
		required = schema["required"]
	else
		required = []  # If no "required" field, default to empty list
	end

	properties = get(schema, "properties", Dict())

	for (key, value) in properties

		# Case 1: If the value is a dictionary, check for nested "properties" or "oneOf"
		if value isa AbstractDict
			# Case A: Check if "properties" exists, recurse if necessary
			if haskey(value, "properties")
				if key in required
					empty_dict[key] = generate_empty_parameter_set_from_schema(value)
				end
				# Case B: Check if "oneOf" exists, handle multiple possible types
			elseif haskey(value, "oneOf")
				possible_types = value["oneOf"]
				for possible_value in possible_types
					if haskey(possible_value, "type")
						type_str = possible_value["type"]
						empty_dict[key] = generate_empty_value(type_str)
						break  # Pick the first type (could be adjusted if necessary)
					end
				end
			else
				# Case C: If there is no "properties" or "oneOf", extract type from "type" key
				if haskey(value, "type")
					if key in required
						type_str = value["type"]
						empty_dict[key] = generate_empty_value(type_str)

					end
				else
					if key in required
						empty_dict[key] = nothing  # If no type is found, set to nothing
					end
				end
			end
		else
			# Case 2: If the value is not a dictionary, we handle it based on its type
			if key in required
				empty_dict[key] = generate_empty_value(typeof(value).name)  # Use `.name` to get string name of type
			end
		end
	end

	return empty_dict
end

function generate_empty_value(type::String)
	# Return appropriate empty value based on the type
	if type == "string"
		return ""
	elseif type == "number" || type == "integer" || type == "float"
		return 0.0
	elseif type == "boolean"
		return false
	elseif type == "object"
		return Dict()  # An empty dictionary for objects
	elseif type == "array"
		return []  # An empty array for arrays
	else
		return nothing  # For unknown types, return nothing
	end
end

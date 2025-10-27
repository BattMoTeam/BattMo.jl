export merge_input, merge_dict

function merge_input(base::P, new::P; type = "fill", key_path = nothing) where {P <: ParameterSet}

	if typeof(base) != typeof(new)
		error("Cannot merge ParameterSets of different types: $(typeof(base)) and $(typeof(new))")
	end
	base_dict = base.all
	new_dict = new.all

	merged_dict = merge_dict(base_dict, new_dict; type = type, key_path = key_path)
	return P(merged_dict)
end

function merge_dict(base::D, new::D; type = "fill", key_path = nothing) where {D <: AbstractDict}
	merged = deepcopy(base)

	if type == "replace"
		if isnothing(key_path)
			error("The key that is wished to be replaced is not specified.")
		end

		key_path = isa(key_path, String) ? [key_path] : key_path

		current = merged
		for (i, key) in enumerate(key_path)
			if i == length(key_path)
				if haskey(new, key)
					current[key] = deepcopy(new[key])
				else
					error("Replacement key '$key' not found in new ParameterSet.")
				end
			else
				if haskey(current, key) && current[key] isa AbstractDict
					current = current[key]
				else
					error("Intermediate key '$key' not found or not a Dict in base ParameterSet.")
				end
			end
		end

	elseif type == "fill"
		for (k, v) in new
			if haskey(merged, k)
				if v isa AbstractDict && merged[k] isa AbstractDict
					merged[k] = merge_dict(merged[k], v; type = "fill")
				elseif merged[k] === 0 || merged[k] === nothing
					merged[k] = deepcopy(v)
				end
			else
				merged[k] = deepcopy(v)
			end
		end
	else
		error("Unknown merge type: $type. Use 'fill' or 'replace'.")
	end

	return merged
end


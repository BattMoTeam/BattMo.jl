#########################################################
# Extensions for Abstract type ParameterSet

"""
New method extending Base.getindex to enable Dictionary-like access to subtypes of ParameterSet.

Example use: 

parameters = ParameterSetSubtype(dict_with_params)
parameters["key"] # output: value of key
parameters["key", "subkey", "subsubkey"] # output: value of subsubkey (nested key)
"""
function Base.getindex(ps::ParameterSet, key::String)
	value = get(ps.dict, key, nothing)
	if value === nothing
		error("Parameter not found: $key")
	else
		return value  # Return the actual value
	end
end

"""
New method extending Base.keys to enable listing all keys in the ParameterSet
"""
function Base.keys(ps::ParameterSet)
	return keys(ps.dict)
end

"""
New method extending Base.haskey to check if key exists
"""
function Base.haskey(ps::ParameterSet, key::String)
	return haskey(ps.dict, key)
end

"""
New method extending Base.push! to insert a new parameter-value pair
"""
function Base.push!(ps::ParameterSet, pair::Pair{String, Any})
	push!(ps.dict, pair)
	return ps
end

"""
New method extending Base.delete! to remove a parameter-value pair
"""
function Base.delete!(ps::ParameterSet, key::String)
	delete!(ps.dict, key)
end

"""
New method extending Base.iterate to enable iteration in for loops
"""
# Extend Base.iterate() - Enable iteration (for loops)
function Base.iterate(ps::ParameterSet, state = nothing)
	return iterate(ps.dict, state)
end


#########################################################
# Extensions for the concrete types of ParameterSet



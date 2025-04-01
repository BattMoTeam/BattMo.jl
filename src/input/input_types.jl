export ParameterSet
export CellParameters, CyclingProtocol, ModelSettings, SimulationSettings, FullSimulationInput

export BattMoFormattedInput
export BattMoInput, MatlabBattMoInput

export merge_input_params, search_parameter


abstract type AbstractInputParams end

""" Abstract type for parameter sets that have an underlying dictionary structure.

For any structure of this type, it is possible to access and set the values of the object using the same syntax a
standard julia [dictionary](https://docs.julialang.org/en/v1/base/collections/#Dictionaries)
"""
abstract type DictInputParams <: AbstractInputParams end


#########################################################
# Extensions for Abstract type ParameterSet

"""
New method extending Base.getindex to enable Dictionary-like access to subtypes of ParameterSet.

Example use: 

parameters = ParameterSetSubtype(dict_with_params)
parameters["key"] # output: value of key
parameters["key", "subkey", "subsubkey"] # output: value of subsubkey (nested key)
"""
function Base.getindex(ps::DictInputParams, key::String)
	value = get(ps.dict, key, nothing)
	if value === nothing
		error("Parameter not found: $key")
	else
		return value  # Return the actual value
	end
end

"""
New method extending Base.setindex! to enable listing all keys in the ParameterSet
"""
function Base.setindex!(ps::DictInputParams, value, key)
	ps.dict[key] = value
end

"""
New method extending Base.get to enable listing all keys in the ParameterSet
"""
function Base.get(ps::DictInputParams, key, default = nothing)
	return get(ps.dict, key, default)
end

"""
New method extending Base.keys to enable listing all keys in the ParameterSet
"""
function Base.keys(ps::DictInputParams)
	return keys(ps.dict)
end

"""
New method extending Base.haskey to check if key exists
"""
function Base.haskey(ps::DictInputParams, key::String)
	return haskey(ps.dict, key)
end

"""
New method extending Base.push! to insert a new parameter-value pair
"""
function Base.push!(ps::DictInputParams, pair::Pair{String, Any})
	push!(ps.dict, pair)
	return ps
end

"""
New method extending Base.delete! to remove a parameter-value pair
"""
function Base.delete!(ps::DictInputParams, key::String)
	delete!(ps.dict, key)
end

"""
New method extending Base.iterate to enable iteration in for loops
"""
# Extend Base.iterate() - Enable iteration (for loops)
function Base.iterate(ps::DictInputParams, state = nothing)
	return iterate(ps.dict, state)
end



##################################################################
# Types for parameter sets

abstract type ParameterSet <: DictInputParams end

######################################
# Define ParameterSet custom methods.


function search_parameter(ps::ParameterSet, query::String)
	search_matches = []
	dicts_to_search = [(ps.dict, [])]  # Stack for traversal: (current_dict, current_path)

	while !isempty(dicts_to_search)
		dict, key_path = pop!(dicts_to_search) #a key_path is e.g. ["key"]["subkey"]
		for (key, value) in dict
			if occursin(lowercase(query), lowercase(key))  # Case-insensitive substring search
				formatted_key_path = "[" * join(vcat(key_path, key), "][") * "]"
				push!(search_matches, formatted_key_path)
			end
			if value isa Dict
				push!(dicts_to_search, (value, vcat(key_path, key)))  # Add nested dict to stack
			end
		end
	end

	if isempty(search_matches)
		println("No match found")
		return nothing
	else
		return search_matches
	end

end

###########################################
# Define concrete types from ParameterSet.

"Cell parameter set type that represents the cell parameters"
struct CellParameters <: ParameterSet
	dict::Dict{String, Any}

end

"Parameter set type that represents the cycling protocol related parameters"
struct CyclingProtocol <: ParameterSet
	dict::Dict{String, Any}
end

"Parameter set type that represents the model related settings"
struct ModelSettings <: ParameterSet
	dict::Dict{String, Any}
end


"Parameter set type that represents the simulation related settings"
struct SimulationSettings <: ParameterSet
	dict::Dict{String, Any}
end

"Parameter set type that includes all other parameter set types"
struct FullSimulationInput <: ParameterSet
	dict::Dict{String, Any}
end



################################################################
# BattMo formatted input types (the validated and to the backend formatted input prameters)

abstract type BattMoFormattedInput <: DictInputParams end

struct InputParams <: BattMoFormattedInput
	dict::Dict{String, Any}

end

struct MatlabInputParams <: BattMoFormattedInput
	dict::Dict{String, Any}
end


const InputGeometryParams = InputParams

function recursive_merge_dict(d1, d2; warn = false)

	if isa(d1, Dict) && isa(d2, Dict)

		combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
		return mergewith(combiner, d1, d2)

	else

		if (d1 != d2) && warn
			println("Some variables have distinct values, we use the value give by the first one")
		end

		return d1

	end
end

""" 
   merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}


# Arguments

- `inputparams1  ::T` : First input parameter structure
- `inputparams2  ::T` : Second input parameter structure
- `warn = false` : If option `warn` is true, then give a warning when two distinct values are given for the same field. The first value has other precedence.

# Returns
A `DictInputParams` structure whose field are the composition of the two input parameter structures.
"""
function merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: DictInputParams}

	dict1 = inputparams1.dict
	dict2 = inputparams2.dict

	combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
	dict = mergewith!(combiner, dict1, dict2)

	return T(dict)

end




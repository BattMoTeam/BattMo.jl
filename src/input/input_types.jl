#%%
export ParameterSet
export CellParameters, CyclingProtocol, ModelSettings, SimulationSettings, FullSimulationInput

export BattMoFormattedInput
export BattMoInput, MatlabBattMoInput

export merge_input_params, search_parameter


"""
	AbstractInput

Abstract type for all parameter sets that can be given as an input to BattMo.

For any structure of this type, it is possible to access and set the values of the object using the same syntax as a
standard Julia [dictionary](https://docs.julialang.org/en/v1/base/collections/#Dictionaries).
"""
abstract type AbstractInput end



#########################################################
# Extensions for Abstract type AbstractInput

"""
	Base.getindex(ps::AbstractInput, key::String)

Extends `Base.getindex` to enable dictionary-like access to subtypes of `AbstractInput`.

# Arguments
- `ps ::AbstractInput` : The parameter set instance.
- `key ::String` : The key to look up.

# Returns
The value associated with `key`. If the key is not found, an error is thrown.
"""
function Base.getindex(ps::AbstractInput, key::String)
	value = get(ps.dict, key, nothing)
	if value === nothing
		error("Parameter not found: $key")
	else
		return value
	end
end


"""
	Base.setindex!(ps::AbstractInput, value, key::String)

Extends `Base.setindex!` to allow setting values in the parameter set.

# Arguments
- `ps ::AbstractInput` : The parameter set instance.
- `value` : The value to assign.
- `key ::String` : The key to assign the value to.
"""
function Base.setindex!(ps::AbstractInput, value, key::String)
	ps.dict[key] = value
end

"""
	Base.get(ps::AbstractInput, key::String, default=nothing)

Extends `Base.get` to retrieve values from the parameter set with a default fallback.

# Arguments
- `ps ::AbstractInput` : The parameter set instance.
- `key ::String` : The key to look up.
- `default` : The default value to return if the key is not found.

# Returns
The value associated with `key` or `default` if the key is not found.
"""
function Base.get(ps::AbstractInput, key, default = nothing)
	return get(ps.dict, key, default)
end


"""
New method extending Base.keys to enable listing all keys in the ParameterSet
"""
function Base.keys(ps::AbstractInput)
	return keys(ps.dict)
end

"""
New method extending Base.haskey to check if key exists
"""
function Base.haskey(ps::AbstractInput, key::String)
	return haskey(ps.dict, key)
end

"""
New method extending Base.push! to insert a new parameter-value pair
"""
function Base.push!(ps::AbstractInput, pair::Pair{String, Any})
	push!(ps.dict, pair)
	return ps
end

"""
New method extending Base.delete! to remove a parameter-value pair
"""
function Base.delete!(ps::AbstractInput, key::String)
	delete!(ps.dict, key)
end

"""
New method extending Base.iterate to enable iteration in for loops
"""
# Extend Base.iterate() - Enable iteration (for loops)
function Base.iterate(ps::AbstractInput, state = nothing)
	return iterate(ps.dict, state)
end



##################################################################
# Abstract type for parameter sets

"""
Abstract type for parameter sets that are part of the user API.
"""
abstract type ParameterSet <: AbstractInput end

######################################
# Define ParameterSet custom methods.

"""
	search_parameter(ps::ParameterSet, query::String)

Searches for a parameter key in the nested dictionary structure and returns matching paths.

# Arguments
- `ps ::ParameterSet` : The parameter set instance.
- `query ::String` : The string to search for in parameter keys.

# Returns
A list of matching parameter key paths if found, otherwise `nothing`.
"""
function search_parameter(ps::ParameterSet, query::String)
	search_matches = []
	dicts_to_search = [(ps.dict, [])]

	while !isempty(dicts_to_search)

		dict, key_path = pop!(dicts_to_search)

		for (key, value) in dict

			if occursin(lowercase(query), lowercase(key))
				formatted_key_path = "[" * join(vcat(key_path, key), "][") * "]"
				if !(value isa Dict)  
                    push!(search_matches, formatted_key_path * " => " * string(value))
                end
			end
			if value isa Dict
				push!(dicts_to_search, (value, vcat(key_path, key)))
			end
		end
	end

	return isempty(search_matches) ? nothing : search_matches
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
"""
	abstract type BattMoFormattedInput <: AbstractInput

Abstract type representing input parameters formatted for BattMo.
This type is used exclusively in the backend as an input to the simulation.
Subtypes of `BattMoFormattedInput` contain parameter dictionaries structured for BattMo compatibility.
"""
abstract type BattMoFormattedInput <: AbstractInput end


"""
	struct InputParams <: BattMoFormattedInput

Represents a validated and backend-formatted set of input parameters for a BattMo simulation.

# Fields
- `dict ::Dict{String, Any}` : A dictionary storing the input parameters for BattMo.
"""
struct InputParams <: BattMoFormattedInput
	dict::Dict{String, Any}

end


"""
	struct MatlabInputParams <: BattMoFormattedInput

Represents input parameters derived from MATLAB-generated files, formatted for BattMo compatibility.

# Fields
- `dict ::Dict{String, Any}` : A dictionary storing MATLAB-extracted input parameters.
"""
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
   merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: AbstractInput}


# Arguments

- `inputparams1  ::T` : First input parameter structure
- `inputparams2  ::T` : Second input parameter structure
- `warn = false` : If option `warn` is true, then give a warning when two distinct values are given for the same field. The first value has other precedence.

# Returns
A `AbstractInput` structure whose field are the composition of the two input parameter structures.
"""
function merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: AbstractInput}

	dict1 = inputparams1.dict
	dict2 = inputparams2.dict

	combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
	dict = mergewith!(combiner, dict1, dict2)

	return T(dict)

end
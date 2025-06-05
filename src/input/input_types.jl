#%%
export ParameterSet
export CellParameters, CyclingProtocol, ModelSettings, SimulationSettings, FullSimulationInput

export BattMoFormattedInput
export InputParams, MatlabInputParams

export merge_input_params, search_parameter, set_input_params, get_input_params, set_default_input_params


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
	value = get(ps.all, key, nothing)
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
	ps.all[key] = value
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
	return get(ps.all, key, default)
end


"""
New method extending Base.keys to enable listing all keys in the ParameterSet
"""
function Base.keys(ps::AbstractInput)
	return keys(ps.all)
end

"""
New method extending Base.haskey to check if key exists
"""
function Base.haskey(ps::AbstractInput, key::String)
	return haskey(ps.all, key)
end

"""
New method extending Base.push! to insert a new parameter-value pair
"""
function Base.push!(ps::AbstractInput, pair::Pair{String, Any})
	push!(ps.all, pair)
	return ps
end

"""
New method extending Base.delete! to remove a parameter-value pair
"""
function Base.delete!(ps::AbstractInput, key::String)
	delete!(ps.all, key)
end

"""
New method extending Base.iterate to enable iteration in for loops
"""
# Extend Base.iterate() - Enable iteration (for loops)
function Base.iterate(ps::AbstractInput, state = nothing)
	return iterate(ps.all, state)
end

function Base.show(io::IO, dict::Dict)
	pretty_print_dict(io, dict, 0)
end

function pretty_print_dict(io::IO, dict::Dict, indent_level::Int)
	indent = "    "^indent_level
	println(io, indent * "{")
	for (i, (k, v)) in enumerate(dict)
		key_str = repr(k)
		print(io, indent * "    " * key_str * " => ")
		if isa(v, Dict)
			pretty_print_dict(io, v, indent_level + 1)
			println(io)  # Ensure newline after nested dict
		else
			println(io, repr(v))
		end
	end
	print(io, indent * "}")
end

function Base.show(io::IO, ob::AbstractInput)
	pretty_print_dict(io, ob.all, 0)
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
	dicts_to_search = [(ps.all, [])]

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
	all::Dict{String, Any}
	source_path::Union{String, Nothing}
	function CellParameters(all::Dict; source_path::Union{String, Nothing} = nothing)
		return new{}(all, source_path)
	end

end

"Parameter set type that represents the cycling protocol related parameters"
struct CyclingProtocol <: ParameterSet
	all::Dict{String, Any}
	source_path::Union{String, Nothing}
	function CyclingProtocol(all::Dict{String, Any}; source_path::Union{String, Nothing} = nothing)
		return new{}(all, source_path)
	end
end

"Parameter set type that represents the model related settings"
struct ModelSettings <: ParameterSet
	all::Dict{String, Any}
	source_path::Union{String, Nothing}
	function ModelSettings(all::Dict{String, Any}; source_path::Union{String, Nothing} = nothing)
		return new{}(all, source_path)
	end
end


"Parameter set type that represents the simulation related settings"
struct SimulationSettings <: ParameterSet
	all::Dict{String, Any}
	source_path::Union{String, Nothing}
	function SimulationSettings(all::Dict; source_path::Union{String, Nothing} = nothing)
		return new{}(all, source_path)
	end
end

"Parameter set type that includes all other parameter set types"
struct FullSimulationInput <: ParameterSet
	all::Dict{String, Any}
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
- `data ::Dict{String, Any}` : A dictionary storing the input parameters for BattMo.
"""
struct InputParams <: BattMoFormattedInput
	all::Dict{String, Any}

end


"""
	struct MatlabInputParams <: BattMoFormattedInput

Represents input parameters derived from MATLAB-generated files, formatted for BattMo compatibility.

# Fields
- `data ::Dict{String, Any}` : A dictionary storing MATLAB-extracted input parameters.
"""
struct MatlabInputParams <: BattMoFormattedInput
	all::Dict{String, Any}
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
   merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: BattMoFormattedInput}

# Arguments

- `inputparams1  ::T` : First input parameter structure
- `inputparams2  ::T` : Second input parameter structure
- `warn = false` : If option `warn` is true, then give a warning when two distinct values are given for the same field. The first value has other precedence.

# Returns
A `BattMoFormattedInput` structure whose field are the composition of the two input parameter structures.
"""
function merge_input_params(inputparams1::T, inputparams2::T; warn = false) where {T <: BattMoFormattedInput}

	dict1 = inputparams1.all
	dict2 = inputparams2.all

	combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
	dict = mergewith!(combiner, dict1, dict2)

	return T(dict)

end

function merge_input_params(inputparams_list::Vector{T}; warn = false) where {T <: BattMoFormattedInput}

    if length(inputparams_list) == 0
        return nothing
    end

    inputparams = inputparams_list[1]

    for i in 2:length(inputparams_list)
        inputparams = merge_input_params(inputparams, inputparams_list[i], warn = warn)
    end

    return inputparams
    
end


"""
    get_input_params(inputparams::Union{T, Dict}, fieldnamelist::Vector{String}) where {T <: BattMoFormattedInput}

Recursively retrieves the value of a field in the input parameters.
"""
function get_input_params(inputparams::Union{T, Dict}, fieldnamelist::Vector{String}) where {T <: BattMoFormattedInput}

    fieldname = fieldnamelist[1]

    if length(fieldnamelist) == 1

        if isa(inputparams, Union{T, Dict} where {T<:BattMoFormattedInput}) && haskey(inputparams, fieldname)
            return inputparams[fieldname]
        else
            return missing
        end

    else

        if isa(inputparams, Union{T, Dict} where {T<:BattMoFormattedInput}) && haskey(inputparams, fieldname) && isa(inputparams[fieldname], Union{T, Dict} where {T<:BattMoFormattedInput})
            
            return get_input_params(inputparams[fieldname], fieldnamelist[2:end])
            
        else
            
            return missing
            
        end

    end
    
end


"""
    Set the value of a field in the input parameters.

# Arguments
    - `inputparams ::BattMoFormattedInput` : The input parameters structure.
    - `fieldnamelist ::Vector{String}` : A vector of field names to set.
    - `value` : The value to assign to the specified fields.
    - `handleMismatch = :error` : How to handle mismatches in field types. Options are `:error`, `:warn`, or `:ignore`.

# Returns
    The updated input parameters structure with the specified fields set to the given value.
    """
function set_input_params(inputparams::Union{T, Dict}, fieldnamelist::Vector{String}, value; handleMismatch = :error) where {T <: BattMoFormattedInput}

    fieldname = fieldnamelist[1]
    
    if !isa(inputparams, Union{T, Dict} where {T<:BattMoFormattedInput})
        
        if handleMismatch in (:warn, :ignore)

            inputparams = Dict{String, Any}()

            if handleMismatch == :warn
                println("Warning: some field in input was not a dictionary, but new input requires it. We create a dictionary.")
            end

        else
            error("some field in input was expected but is not a dictionary.")
        end

    end
            
    if length(fieldnamelist) > 1
        
        if isa(inputparams[fieldname], Dict)
            
            inputparams[fieldname] = set_input_params(inputparams[fieldname], fieldnamelist[2:end], value; handleMismatch = handleMismatch)
            
        elseif  handleMismatch in (:warn, :ignore)

            if handleMismatch == :warn
                println("Warning: Field $fieldname was not a dictionary and we overwrite the value.")
            end

            inputparams[fieldname] = Dict{String, Any}()
            inputparams[fieldname] = set_input_params(inputparams[fieldname], fieldnamelist[2:end], value; handleMismatch = handleMismatch)
            
        else handleMismatch == :error
            
            error("Mismatch for $fieldname")
            
        end

    else

        # We set the value
        if haskey(inputparams, fieldname)
            
            if inputparams[fieldname] != value
                    
                if handleMismatch in (:warn, :ignore)
                    println("Warning: Field $fieldname was not equal to the value and we overwrite it.")
                    inputparams[fieldname] = value
                elseif handleMismatch == :error
                    error("Mismatch for $fieldname")
                end
    
            end
            
        else

            inputparams[fieldname] = value
            
        end

    end
            
    return inputparams

end

function set_default_input_params(inputparams::Union{T, Dict}, fieldnamelist::Vector{String}, value; handleMismatch = :error) where {T <: BattMoFormattedInput}

    current_value = get_input_params(inputparams, fieldnamelist)

    if ismissing(current_value)

        inputparams = set_input_params(inputparams, fieldnamelist, value; handleMismatch)

    end

    return inputparams
    
end



#########################################
# Define Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end


"""
Enable Dictionary-like access to subtypes of ParameterSet.

Example use: 

parameters = ParameterSetSubtype(dict_with_params)
parameters["key"] # output: value of key
parameters["key", "subkey", "subsubkey"] # output: value of subsubkey (nested key)
"""
function Base.getindex(ps::ParameterSet, keys::Vararg{String})
	value = ps.dict
	for key in keys
		value = value isa Dict ? get(value, key, nothing) : nothing
		if value === nothing
			error("Parameter not found: " * join(keys, " -> "))
		end
	end
	return value
end


"Cell parameter set type that represents the BattMo formatted cell parameters"
struct CellParameters <: ParameterSet
	dict::Dict{String, Any}
end


"Parameter set type that represents the cycling related parameters"
struct CyclingProtocol <: ParameterSet
	dict::Dict{String, Any}
end


"Parameter set type that represents the model related parameters"
struct ModelSettings <: ParameterSet
	dict::Dict{String, Any}
end


#########################################
# Populate Parameter sets
#########################################

function load_cell_parameters(filepath::String)
	print("Beer is life")
end

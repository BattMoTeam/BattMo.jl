# ONLY KEEP FOR DEVELOPMENT
#%%
using Pkg
Pkg.activate("./src/parameters")
Pkg.status() |> print

using Revise
#%%

using JSON


########################################################################
# Define ParameterSet abstract type and its Dict-like method extensions.
#########################################################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end


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
function Base.iterate(ps::ParameterSet, state=nothing)
    return iterate(ps.dict, state)
end

#%%

######################################
# Define ParameterSet custom methods.
######################################

function search_parameter(ps::ParameterSet, query::String)
    results = []
    stack = [(ps.dict, [])]  # Stack for traversal: (current_dict, current_path)

    while !isempty(stack)
        dict, path = pop!(stack)
        for (key, value) in dict
            if occursin(lowercase(query), lowercase(key))  # Case-insensitive substring search
                formatted_parameter_path = "[" * join(vcat(path, key), "][") * "]"
                push!(results, formatted_parameter_path)
            end
            if value isa Dict
                push!(stack, (value, vcat(path, key)))  # Add nested dict to stack
            end
        end
    end

    if isempty(results)
        println("No match found")
        return nothing
    else
        return results
    end
end

###########################################
# Define concrete types from ParameterSet.
###########################################

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

# %%

#########################################
# Populate Parameters from JSON files
#########################################


function load_cell_parameters(filepath::String)
    cell_parameters_instance = filepath |> JSON.parsefile |> Dict |> CellParameters
    return cell_parameters_instance
end


function load_cycling_protocol(filepath::String)
    cycling_protocol_instance = filepath |> JSON.parsefile |> Dict |> CyclingProtocol
    return cycling_protocol_instance
end


function load_simulation_settings(filepath::String)
    simulation_settings_instance = filepath |> JSON.parsefile |> Dict |> SimulationSettings
    return simulation_settings_instance
end



# %%
#########################################
# Testing
#########################################

cell_parameters = load_cell_parameters("./src/parameters/cell_parameter_set_chen2020.json")
cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] |> println

cycling_protocol = load_cycling_protocol("./src/parameters/cycling_protocol_cccv_chen2020.json")
cycling_protocol["Protocol"] |> println

simulation_settings = load_simulation_settings("./src/parameters/model_settings_P2D_chen2020.json")
simulation_settings["TimeStepDuration"] |> println

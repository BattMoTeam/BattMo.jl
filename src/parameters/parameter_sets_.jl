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
"""
function Base.getindex(ps::ParameterSet, key::String)
    return ps.dict[key]  
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
function Base.iterate(ps::ParameterSet, state=nothing)
    return iterate(ps.dict, state)
end

#%%

######################################
# Define ParameterSet custom methods.
######################################

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


"Parameter set type that represents the model related parameters"
struct SimulationSettings <: ParameterSet
	dict::Dict{String, Any}
end


# %%

#########################################
# Populate Parameters from JSON files
#########################################


function read_cell_parameters(filepath::String)
    cell_parameters_instance = filepath |> JSON.parsefile |> Dict |> CellParameters
    return cell_parameters_instance
end


function read_cycling_protocol(filepath::String)
    cycling_protocol_instance = filepath |> JSON.parsefile |> Dict |> CyclingProtocol
    return cycling_protocol_instance
end


function read_model_settings(filepath::String)
    simulation_settings_instance = filepath |> JSON.parsefile |> Dict |> ModelSettings
    return simulation_settings_instance
end


function read_simulation_settings(filepath::String)
    simulation_settings_instance = filepath |> JSON.parsefile |> Dict |> SimulationSettings
    return simulation_settings_instance
end



# %%
#########################################
# Cell calculations
#########################################

function compute_electrode_coating_mass(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode")
    end

    effective_density = params[electrode]["ElectrodeCoating"]["EffectiveDensity"]
    area = params[electrode]["ElectrodeCoating"]["Area"]
    thickness = params[electrode]["ElectrodeCoating"]["Thickness"]

    return effective_density*area*thickness
end

function compute_electrode_theoretical_density(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode")
    end

    component_mass_fractions = [params[electrode]["ActiveMaterial"]["MassFraction"],
                                params[electrode]["ConductiveAdditive"]["MassFraction"],
                                params[electrode]["Binder"]["MassFraction"]]
    component_densities = [params[electrode]["ActiveMaterial"]["Density"],
                          params[electrode]["ConductiveAdditive"]["Density"],
                          params[electrode]["Binder"]["Density"]]

    return 1/sum(component_mass_fractions./component_densities)
end


function compute_separator_mass(params::CellParameters)
    area = params["Cell"]["Area"]
    density = params["Separator"]["Density"]
    thickness = params["Separator"]["Thickness"]
    porosity = params["Separator"]["Porosity"]
    return thickness*area*(1-porosity)*density    
end

function compute_current_collector_mass(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode")
    end

    area = params["Cell"]["Area"]
    thickness = params[electrode]["CurrentCollector"]["Thickness"]
    density = params[electrode]["CurrentCollector"]["Density"]
    return area*thickness*density
end

function compute_electrolyte_mass(params::CellParameters)
    # TO BE CONTINUED
    density = params["Electrolyte"]["Density"]
    porosity_separator = params["Separator"]["Porosity"]
    porosity_positive_electrode
    porosity_negative_electrode

    return effective_density*area*thickness
end

function compute_cell_mass(params::CellParameters)
    m_positive_e = compute_electrode_coating_mass(params, "PositiveElectrode")
    m_negative_e = compute_electrode_coating_mass(params, "NegativeElectrode")
    m_separator = compute_separator_mass(params)
    m_positive_e_cc = compute_current_collector_mass(params, "PositiveElectrode")
    m_negative_e_cc = compute_current_collector_mass(params, "NegativeElectrode")
    m_electrolyte = compute_electrolyte_mass(params)
    return m_positive_e + m_negative_e + m_separator + m_positive_e_cc + m_negative_e_cc + m_electrolyte
end

# %%
#########################################
# Testing
#########################################

parameter_sets_directory = "./src/parameters/default_sets/"

cell_parameters = read_cell_parameters(parameter_sets_directory * "cell_parameters/cell_parameter_set_chen2020.json")
cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] |> println

cycling_protocol = read_cycling_protocol(parameter_sets_directory * "cycling_protocols/CCCV.json")
cycling_protocol["Protocol"] |> println

simulation_settings = read_simulation_settings(parameter_sets_directory * "model_settings/model_settings_P2D.json")
simulation_settings["ModelGeometry"] |> println

# ONLY KEEP FOR DEVELOPMENT
#%%
using Pkg
Pkg.activate("./src/parameters")
Pkg.status() |> print

using Revise


#%%
using JSON
using LinearAlgebra


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
    model_settings_instance = filepath |> JSON.parsefile |> Dict |> ModelSettings
    return model_settings_instance
end


function read_simulation_settings(filepath::String)
    simulation_settings_instance = filepath |> JSON.parsefile |> Dict |> SimulationSettings
    return simulation_settings_instance
end



# %%
#########################################
# Cell Mass calculations
#########################################

function compute_electrode_coating_mass(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
    end

    effective_density = params[electrode]["ElectrodeCoating"]["EffectiveDensity"]
    area = params[electrode]["ElectrodeCoating"]["Area"]
    thickness = params[electrode]["ElectrodeCoating"]["Thickness"]

    return effective_density*area*thickness
end



function compute_electrode_theoretical_density(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
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
    area = params["NegativeElectrode"]["ElectrodeCoating"]["Area"] #Assumes the electrode areas are the same.
    density = params["Separator"]["Density"]
    thickness = params["Separator"]["Thickness"]
    porosity = params["Separator"]["Porosity"]
    return thickness*area*(1-porosity)*density    
end



function compute_current_collector_mass(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
    end

    area = params[electrode]["ElectrodeCoating"]["Area"]
    thickness = params[electrode]["CurrentCollector"]["Thickness"]
    density = params[electrode]["CurrentCollector"]["Density"]
    return area*thickness*density
end


"""

"""
function compute_electrolyte_mass(params::CellParameters)
   
    electrolyte_density = params["Electrolyte"]["Density"]
    cell_area = params["NegativeElectrode"]["ElectrodeCoating"]["Area"] #Assumes the electrode areas are the same.

    #separator (sep)
    sep_porosity = params["Separator"]["Porosity"]
    sep_volume = cell_area*params["Separator"]["Thickness"]

    #positive electrode (pe)
    pe_theoretical_density = compute_electrode_theoretical_density(params, "PositiveElectrode")
    pe_effective_density = params["PositiveElectrode"]["ElectrodeCoating"]["EffectiveDensity"]
    pe_volume = cell_area*params["PositiveElectrode"]["ElectrodeCoating"]["Thickness"]
    pe_porosity = 1.0 - (pe_effective_density/pe_theoretical_density)

    #negative electrode (ne)
    ne_theoretical_density = compute_electrode_theoretical_density(params, "NegativeElectrode")    
    ne_effective_density = params["NegativeElectrode"]["ElectrodeCoating"]["EffectiveDensity"]
    ne_volume = cell_area*params["NegativeElectrode"]["ElectrodeCoating"]["Thickness"]
    ne_porosity = 1.0 - (ne_effective_density/ne_theoretical_density)

    component_volumes = [pe_volume, ne_volume, sep_volume]
    component_porosities = [pe_porosity, ne_porosity, sep_porosity]

    return electrolyte_density*dot(component_volumes, component_porosities)
end

function compute_cell_mass(params::CellParameters; print_breakdown::Bool = false)
    m_positive_e = compute_electrode_coating_mass(params, "PositiveElectrode")
    m_negative_e = compute_electrode_coating_mass(params, "NegativeElectrode")
    m_separator = compute_separator_mass(params)
    m_positive_e_cc = compute_current_collector_mass(params, "PositiveElectrode")
    m_negative_e_cc = compute_current_collector_mass(params, "NegativeElectrode")
    m_electrolyte = compute_electrolyte_mass(params)
    total_cell_mass = m_positive_e + m_negative_e + m_separator + m_positive_e_cc + m_negative_e_cc + m_electrolyte

    if print_breakdown
        print("""
        Positive Electrode                   Mass = $m_positive_e,     % = $(100*m_positive_e/total_cell_mass) \n
        Negative Electrode                   Mass = $m_negative_e,     % = $(100*m_negative_e/total_cell_mass) \n
        Positive Electrode Current Collector Mass = $m_positive_e_cc,  % = $(100*m_positive_e_cc/total_cell_mass) \n
        Negative Electrode Current Collector Mass = $m_negative_e_cc,  % = $(100*m_negative_e_cc/total_cell_mass) \n
        Electrolyte                          Mass = $m_electrolyte,    % = $(100*m_electrolyte/total_cell_mass) \n
        Separator                            Mass = $m_separator,      % = $(100*m_separator/total_cell_mass) \n
        """) 
    end
    return total_cell_mass 
end


# %%
#########################################
# Cell XXXX calculations
#########################################


function compute_electrode_volume_fraction(params::CellParameters, electrode::String)

    if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
        error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
    end

    effective_density = params[electrode]["ElectrodeCoating"]["EffectiveDensity"]
    theoretical_density = compute_electrode_theoretical_density(params, electrode)
    return effective_density/theoretical_density
end




# %%
#########################################
# Testing
#########################################

parameter_sets_directory = "./input/"

cell_parameters = read_cell_parameters(parameter_sets_directory * "cell_parameters/cell_parameter_set_chen2020.json")
cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] |> println

cycling_protocol = read_cycling_protocol(parameter_sets_directory * "cycling_protocols/CCCV.json")
cycling_protocol["Protocol"] |> println

simulation_settings = read_simulation_settings(parameter_sets_directory * "model_settings/model_settings_P2D.json")
simulation_settings["ModelGeometry"] |> println


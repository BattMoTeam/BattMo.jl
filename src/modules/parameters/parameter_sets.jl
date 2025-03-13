


#########################################
# Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

"Abstract type for all parameter sets that only contain cell parameters in BattMo"
abstract type CellParameterSet <: ParameterSet   end

"Parameter set type that represents the cycling related parameters"
struct CyclingParameterSet <: ParameterSet end

"Parameter set type that represents the model related parameters"
struct ModelParameterSet <: ParameterSet end

"Parameter set type that represents the BattMo input parameter set containing all 
three above mentioned parameter set types."
struct BattMoInputParameterSet <: ParameterSet end


#########################################
# Cell parameter set types
#########################################

"Cell parameter set type that represents the BPX formatted cell parameters"
struct BPXCellParameterSet <: CellParameterSet end

"Cell parameter set type that represents the BattMo formatted cell parameters"
struct BattMoCellParameterSet <: CellParameterSet end


#########################################
# Functions to loading parameter sets
#########################################


"""
    load_parameters(source::Union{String,Dict}, category::BattMoInputParameterSet)

Loads a set of input parameters for the BattMo model.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BattMoInputParameterSet`: The specific category of input parameters to load.

# Returns
- The loaded parameters in the format required by `BattMoInputParameterSet`.
"""
function load_parameters(source::Union{String,Dict}, category::BattMoInputParameterSet)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::BattMoCellParameterSet)

Loads cell-specific parameters for the BattMo model.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BattMoCellParameterSet`: The specific category of cell parameters to load.

# Returns
- The loaded parameters in the format required by `BattMoCellParameterSet`.
"""
function load_parameters(source::Union{String,Dict}, category::BattMoCellParameterSet)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::BPXCellParameterSet)

Loads BPX cell parameters from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BPXCellParameterSet`: The specific category of BPX cell parameters to load.

# Returns
- The loaded parameters in the format required by `BPXCellParameterSet`.
"""
function load_parameters(source::Union{String,Dict}, category::BPXCellParameterSet)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::CyclingParameterSet)

Loads cycling-related parameters from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::CyclingParameterSet`: The specific category of cycling parameters to load.

# Returns
- The loaded parameters in the format required by `CyclingParameterSet`.
"""
function load_parameters(source::Union{String,Dict}, category::CyclingParameterSet)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::ModelParameterSet)

Loads general model settings from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the settings, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::ModelParameterSet`: The specific category of model settings to load.

# Returns
- The loaded model settings in the format required by `ModelParameterSet`.
"""
function load_parameters(source::Union{String,Dict}, category::ModelParameterSet)
    source
    category
end


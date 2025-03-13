


#########################################
# Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

"Abstract type for all parameter sets that only contain cell parameters in BattMo"
abstract type CellParameters <: ParameterSet   end

"Parameter set type that represents the cycling related parameters"
struct CyclingParameters <: ParameterSet end

"Parameter set type that represents the model related parameters"
struct ModelSettings <: ParameterSet end

"Parameter set type that represents the BattMo input parameter set containing all 
three above mentioned parameter set types."
struct BattMoInputParameters <: ParameterSet end


#########################################
# Cell parameter set types
#########################################

"Cell parameter set type that represents the BPX formatted cell parameters"
struct BPXCellParameters <: CellParameters end

"Cell parameter set type that represents the BattMo formatted cell parameters"
struct BattMoCellParameters <: CellParameters end


#########################################
# Functions to loading parameter sets
#########################################


"""
    load_parameters(source::Union{String,Dict}, category::BattMoInputParameters)

Loads a set of input parameters for the BattMo model.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BattMoInputParameters`: The specific category of input parameters to load.

# Returns
- The loaded parameters in the format required by `BattMoInputParameters`.
"""
function load_parameters(source::Union{String,Dict}, category::BattMoInputParameters)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::BattMoCellParameters)

Loads cell-specific parameters for the BattMo model.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BattMoCellParameters`: The specific category of cell parameters to load.

# Returns
- The loaded parameters in the format required by `BattMoCellParameters`.
"""
function load_parameters(source::Union{String,Dict}, category::BattMoCellParameters)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::BPXCellParameters)

Loads BPX cell parameters from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::BPXCellParameters`: The specific category of BPX cell parameters to load.

# Returns
- The loaded parameters in the format required by `BPXCellParameters`.
"""
function load_parameters(source::Union{String,Dict}, category::BPXCellParameters)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::CyclingParameters)

Loads cycling-related parameters from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the parameters, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::CyclingParameters`: The specific category of cycling parameters to load.

# Returns
- The loaded parameters in the format required by `CyclingParameters`.
"""
function load_parameters(source::Union{String,Dict}, category::CyclingParameters)
    source
    category
end



"""
    load_parameters(source::Union{String,Dict}, category::ModelSettings)

Loads general model settings from a given source.

# Arguments
- `source::Union{String, Dict}`: The source of the settings, either as a filename (for BattMo default parameter sets), as a filepath, as an url, or a dictionary.
- `category::ModelSettings`: The specific category of model settings to load.

# Returns
- The loaded model settings in the format required by `ModelSettings`.
"""
function load_parameters(source::Union{String,Dict}, category::ModelSettings)
    source
    category
end


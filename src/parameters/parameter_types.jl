export
    Parameters,
    CellParameters,
    BPXCellParameters,
    CyclingParameters,
    ModelParameters,
    BattMoInputParameters,
    MatlabInputParameters


#########################################
# Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type Parameters end

"Cell parameter set type that represents the BattMo formatted cell parameters"
struct CellParameters <: Parameters
    dict::Dict{String, Any}
end

"Cell parameter set type that represents the BPX formatted cell parameters"
struct BPXCellParameters <: Parameters
    dict::Dict{String, Any}
end

"Parameter set type that represents the cycling related parameters"
struct CyclingParameters <: Parameters
    dict::Dict{String, Any}
end

"Parameter set type that represents the model related parameters"
struct ModelParameters <: Parameters
    dict::Dict{String, Any}
end

"Parameter set type that represents the BattMo input parameter set containing all 
three above mentioned parameter set types."
struct BattMoInputParameters <: Parameters 
    dict::Dict{String, Any}
end

"Parameter set type that represents a BattMo input parameter set in a MATLAB dict."
struct MatlabInputParameters <: Parameters 
    dict::Dict{String, Any}
end





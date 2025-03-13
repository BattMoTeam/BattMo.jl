


#########################################
# Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

"Cell parameter set type that represents the BattMo formatted cell parameters"
abstract type CellParameterSet <: ParameterSet   end

"Cell parameter set type that represents the BPX formatted cell parameters"
struct BPXCellParameterSet <: ParameterSet end

"Parameter set type that represents the cycling related parameters"
struct CyclingParameterSet <: ParameterSet end

"Parameter set type that represents the model related parameters"
struct ModelParameterSet <: ParameterSet end

"Parameter set type that represents the BattMo input parameter set containing all 
three above mentioned parameter set types."
struct BattMoInputParameterSet <: ParameterSet end


#########################################
# Functions to loading parameter sets
#########################################


function load_parameters(source::Union{String,Dict}, ::Type{T}) where {T <: ParameterSet}
    println("Loading parameters from: ", source)
    println("Parameter set type: ", T)
    # Here you can instantiate T or load relevant data for the type
end

load_parameters("example.json", CellParameterSet)


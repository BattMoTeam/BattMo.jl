export ParameterSet
export CellParameters, CyclingProtocol, ModelSettings, SimulationSettings, FullSimulationInput

export BattMoFormattedInput
export BattMoInput, MatlabBattMoInput

###############################################################
# Parameter set types

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

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
# BattMo formatted input types

abstract type BattMoFormattedInput end

struct BattMoInput <: BattMoFormattedInput
	Dict::Dict{String, Any}

end

struct MatlabBattMoInput <: BattMoFormattedInput
	dict::Dict{String, Any}
end

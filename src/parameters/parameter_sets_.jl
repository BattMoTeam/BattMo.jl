

#########################################
# Define Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

"Cell parameter set type that represents the BattMo formatted cell parameters"
struct CellParameters <: ParameterSet
	dict::Dict{String, Any}

	function CellParameters(file_path)
		cell_parameters = Dict(json.load(file_path))
		return new{typeof(cell_parameters)}(cell_parameters)
	end
end


"Parameter set type that represents the cycling related parameters"
struct CyclingProtocol <: ParameterSet
	dict::Dict{String, Any}

    function CyclingProtocol(file_path)
		cell_parameters = Dict(json.load(file_path))
		return new{typeof(cell_parameters)}(cell_parameters)
	end
end


"Parameter set type that represents the model related parameters"
struct SimulationSettings <: ParameterSet
	dict::Dict{String, Any}

    function SimulationSettings(file_path)
		cell_parameters = Dict(json.load(file_path))
		return new{typeof(cell_parameters)}(cell_parameters)
	end
end


#########################################
# Populate Parameter sets
#########################################
export ParameterSet
export CellParameters, CyclingProtocol, ModelSettings
export SimulationInput, MatlabSimulationInput
export load_cell_parameters, load_cell_parameters_bpx, load_cycling_protocol, load_simulation_settings
export merge_parameter_sets


#########################################
# Parameter set types
#########################################

"Abstract type for all parameter sets in BattMo"
abstract type ParameterSet end

"Cell parameter set type that represents the BattMo formatted cell parameters"
struct CellParameters <: ParameterSet
	dict::Dict{String, Any}

end

"Cell parameter set type that represents the BPX formatted cell parameters"
struct BPXCellParameters <: ParameterSet
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

"Parameter set type that represents the BattMo input parameter set containing all 
three above mentioned parameter set types."
struct SimulationInput <: ParameterSet
	dict::Dict{String, Any}
end

"Parameter set type that represents a BattMo input parameter set in a MATLAB dict."
struct MatlabSimulationInput <: ParameterSet
	dict::Dict{String, Any}
end



#########################################
# Functions to loading parameter sets
#########################################


function load_cell_parameters(source::String)

	if source isa String
		inputparams = CellParameters(Dict(JSON.parsefile(source)))
	else
		inputparams = CellParameters(source)
	end
	return inputparams
end

function load_cell_parameters_bpx(source::String)

	if source isa String

		bpx_dict = Dict(JSON.parsefile(source))
	else
		bpx_dict = source
	end

	function convert_bpx_to_battmo(bpx_dict::Dict{Symbol, Any})

	end

	battmo_formatted_dict = convert_bpx_to_battmo(bpx_dict)

	inputparams = CellParameters(battmo_formatted_dict)
	return inputparams
end

function load_cycling_protocol(source::String)

	if source isa String
		inputparams = CyclingProtocol(Dict(JSON.parsefile(source)))
	else
		inputparams = CyclingProtocol(source)
	end

	return inputparams
end

function load_simulation_settings(source::String)

	if source isa String
		inputparams = ModelSettings(Dict(JSON.parsefile(source)))
	else
		inputparams = ModelSettings(source)
	end

	return inputparams
end


#########################################
# Functions to inspect parameter sets
#########################################

function Base.getindex(input::ParameterSet, keyname)
	return input.dict[keyname]
end

function Base.setindex!(input::ParameterSet, value, keyname)
	input.dict[keyname] = value
end

function Base.haskey(input::ParameterSet, keyname)
	return haskey(input.dict, keyname)
end

function Base.keys(input::ParameterSet)
	return keys(input.dict)
end


#########################################
# Functions to combine parameter sets
#########################################


function recursive_merge_dict(d1, d2; warn = false)

	if isa(d1, Dict) && isa(d2, Dict)

		combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
		return mergewith(combiner, d1, d2)

	else

		if (d1 != d2) && warn
			println("Some variables have distinct values, we use the value give by the first one")
		end

		return d1

	end
end


function merge_parameter_sets(inputparams1::Union{CellParameters, CyclingProtocol, ModelSettings},
	inputparams2::Union{CellParameters, CyclingProtocol, ModelSettings};
	inputparams3::Union{CellParameters, CyclingProtocol, ModelSettings} = nothing,
	warn = false)

	dict1 = inputparams1.dict
	dict2 = inputparams2.dict

	if inputparams3
		dict3 = inputparams3.dict
	else
		dict3 = nothing
	end

	combiner(d1, d2) = recursive_merge_dict(d1, d2; warn = warn)
	dict = mergewith!(combiner, dict1, dict2)

	if dict3
		dict = mergewith!(combiner, dict, dict3)
	end

	return SimulationInput(dict)

end

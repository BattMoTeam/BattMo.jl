using JSON: JSON
using MAT: MAT

export read_model_settings, read_cell_parameters, read_cycling_protocol, read_simulation_settings
export read_matlab_battmo_input, read_battmo_formatted_input


function read_model_settings(filepath::String)
	model_settings_instance = filepath |> JSON.parsefile |> ModelSettings
	return model_settings_instance
end

function read_cell_parameters(filepath::String)
	cell_parameters_instance = filepath |> JSON.parsefile |> CellParameters
	return cell_parameters_instance
end


function read_cycling_protocol(filepath::String)
	cycling_protocol_instance = filepath |> JSON.parsefile |> CyclingProtocol
	return cycling_protocol_instance
end


function read_simulation_settings(filepath::String)
	simulation_settings_instance = filepath |> JSON.parsefile |> SimulationSettings
	return simulation_settings_instance
end


""" 
   read_matlab_battmo_input(inputFileName::String)

Reads the input from a matlab output file which contains a description of the model and returns an `MatlabInputParams`
that can be sent to the simulator.

# Arguments

- `inputFileName ::String` : filename of the input

# Returns
An instance of [`MatlabInputParams`](@ref) that can be sent to the simulator via [`run_battery`](@ref)
"""
function read_matlab_battmo_input(filepath::String)
	inputparams = filepath |> MAT.matread |> MatlabInputParams
	return inputparams
end

function read_battmo_formatted_input(filepath::String)
	inputparams = filepath |> JSON.parsefile |> InputParams
	return inputparams
end





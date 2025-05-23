export read_matlab_battmo_input, read_battmo_formatted_input

""" 
	read_matlab_battmo_input(inputFileName::String)

Reads the input from a MATLAB output file which contains a description of the model and returns an `MatlabInputParams`
that can be sent to the simulator.

# Arguments
- `inputFileName ::String` : Path to the MATLAB file.

# Returns
An instance of `MatlabInputParams` that can be sent to the simulator via `run_battery`.
"""
function read_matlab_battmo_input(filepath::String)
	inputparams = filepath |> matread |> MatlabInputParams
	return inputparams
end

"""
	read_battmo_formatted_input(filepath::String)

Reads and parses a JSON file into an `InputParams` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `InputParams`.
"""
function read_battmo_formatted_input(filepath::String)
	inputparams = filepath |> JSON.parsefile |> InputParams
	return inputparams
end




export read_model_settings,
    read_cell_parameters, read_cycling_protocol, read_simulation_settings
export read_matlab_battmo_input, read_battmo_formatted_input

"""
	read_model_settings(filepath::String)

Reads and parses a JSON file into a `ModelSettings` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `ModelSettings`.
"""
function read_model_settings(filepath::String)
    model_settings_instance = ModelSettings(JSON.parsefile(filepath))
    return model_settings_instance
end

"""
	read_cell_parameters(filepath::String)

Reads and parses a JSON file into a `CellParameters` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `CellParameters`.
"""
function read_cell_parameters(filepath::String)
    cell_parameters_instance = CellParameters(JSON.parsefile(filepath))
    return cell_parameters_instance
end

"""
	read_cycling_protocol(filepath::String)

Reads and parses a JSON file into a `CyclingProtocol` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `CyclingProtocol`.
"""
function read_cycling_protocol(filepath::String)
    cycling_protocol_instance = CyclingProtocol(JSON.parsefile(filepath))
    return cycling_protocol_instance
end

"""
	read_simulation_settings(filepath::String)

Reads and parses a JSON file into a `SimulationSettings` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `SimulationSettings`.
"""
function read_simulation_settings(filepath::String)
    simulation_settings_instance = SimulationSettings(JSON.parsefile(filepath))
    return simulation_settings_instance
end

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
    inputparams = MatlabInputParams(matread(filepath))
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
    inputparams = InputParams(JSON.parsefile(filepath))
    return inputparams
end

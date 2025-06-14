export load_model_settings, load_cell_parameters, load_cycling_protocol, load_simulation_settings
export load_matlab_battmo_input, load_battmo_formatted_input


"""
	load_model_settings(; from_file_path::String = nothing, from_default_set::String = nothing)

Reads and loads model settings either from a JSON file or a default set.

# Arguments
- `from_file_path ::String` : (Optional) Path to the JSON file containing model settings.
- `from_default_set ::String` : (Optional) The name of the default set to load model settings from.

# Returns
An instance of `ModelSettings`.

# Errors
Throws an `ArgumentError` if neither `from_file_path` nor `from_default_set` is provided.
"""
function load_model_settings(; from_file_path::Union{String, Nothing} = nothing, from_default_set::Union{String, Nothing} = nothing)
	if !isnothing(from_file_path)
		# Assuming JSON and ModelSettings are correctly defined
		model_settings_instance = JSON.parsefile(from_file_path)
		return ModelSettings(model_settings_instance; source_path = from_file_path)
	elseif !isnothing(from_default_set)
		# Logic to load from default set (replace this with actual code)
		file_path = parameter_file_path("model_settings", from_default_set)
		return load_model_settings(; from_file_path = file_path)
	else
		throw(ArgumentError("Either 'from_file_path' or 'from_default_set' must be provided."))
	end
end


"""
	load_cell_parameters(; from_file_path::String = nothing, from_default_set::String = nothing, from_model_template::BatteryModelSetup = nothing)

Reads and loads cell parameters either from a JSON file, a default set, or a model template.

# Arguments
- `from_file_path ::String` : (Optional) Path to the JSON file containing cell parameters.
- `from_default_set ::String` : (Optional) The name of the default set to load cell parameters from.
- `from_model_template ::BatteryModelSetup` : (Optional) A `BatteryModelSetup` instance used to load an empty set of cell parameters required for the concerning model.

# Returns
An instance of `CellParameters`.

# Errors
Throws an `ArgumentError` if none of the arguments are provided.
"""
function load_cell_parameters(; from_file_path::Union{String, Nothing} = nothing, from_default_set::Union{String, Nothing} = nothing, from_model_template::Union{BatteryModelSetup, Nothing} = nothing)
	if !isnothing(from_file_path)
		# Assuming JSON and CellParameters are correctly defined
		cell_parameters_data = JSON.parsefile(from_file_path)
		return CellParameters(cell_parameters_data; source_path = from_file_path)
	elseif !isnothing(from_default_set)
		# Logic to load from default set (replace this with actual code)
		file_path = parameter_file_path("cell_parameters", from_default_set)
		return load_cell_parameters(; from_file_path = file_path)
	elseif !isnothing(from_model_template)
		# Logic to load from model template (replace this with actual code)
		cell_parameters_data = get_empty_cell_parameter_set(from_model_template)
		return CellParameters(cell_parameters_data; source_path = nothing)
	else
		throw(ArgumentError("Either 'from_file_path', 'from_default_set', or 'from_model_template' must be provided."))
	end

end



"""
	load_cycling_protocol(; from_file_path::String = nothing, from_default_set::String = nothing)

Reads and loads cycling protocol either from a JSON file or a default set.

# Arguments
- `from_file_path ::String` : (Optional) Path to the JSON file containing cycling protocol.
- `from_default_set ::String` : (Optional) The name of the default set to load cycling protocol from.

# Returns
An instance of `CyclingProtocol`.

# Errors
Throws an `ArgumentError` if neither `from_file_path` nor `from_default_set` is provided.
"""
function load_cycling_protocol(; from_file_path::Union{String, Nothing} = nothing, from_default_set::Union{String, Nothing} = nothing)
	if !isnothing(from_file_path)
		# Assuming JSON and CyclingProtocol are correctly defined
		cycling_protocol_instance = JSON.parsefile(from_file_path)
		return CyclingProtocol(cycling_protocol_instance; source_path = from_file_path)
	elseif !isnothing(from_default_set)
		# Logic to load from default set (replace this with actual code)
		file_path = parameter_file_path("cycling_protocols", from_default_set)
		return load_cycling_protocol(; from_file_path = file_path)
	else
		throw(ArgumentError("Either 'from_file_path' or 'from_default_set' must be provided."))
	end

end

"""
	load_simulation_settings(; from_file_path::String = nothing, from_default_set::String = nothing, from_model_template::BatteryModelSetup = nothing)

Reads and loads simulation settings either from a JSON file, a default set, or a model template.

# Arguments
- `from_file_path ::String` : (Optional) Path to the JSON file containing simulation settings.
- `from_default_set ::String` : (Optional) The name of the default set to load simulation settings from.
- `from_model_template ::BatteryModelSetup` : (Optional) A `BatteryModelSetup` instance used to load an empty set of simulation settings required for the concerning model.

# Returns
An instance of `SimulationSettings`.

# Errors
Throws an `ArgumentError` if none of the arguments are provided.
"""
function load_simulation_settings(; from_file_path::Union{String, Nothing} = nothing, from_default_set::Union{String, Nothing} = nothing, from_model_template::Union{BatteryModelSetup, Nothing} = nothing)
	if !isnothing(from_file_path)
		# Assuming JSON and SimulationSettings are correctly defined
		simulation_settings_instance = JSON.parsefile(from_file_path)
		return SimulationSettings(simulation_settings_instance; source_path = from_file_path)
	elseif !isnothing(from_default_set)
		# Logic to load from default set (replace this with actual code)
		file_path = parameter_file_path("simulation_settings", from_default_set)
		return load_simulation_settings(; from_file_path = file_path)
	elseif !isnothing(from_model_template)
		# Logic to load from model template (replace this with actual code)
		simulation_settings_instance = get_empty_simulation_settings(from_model_template)
		return SimulationSettings(simulation_settings_instance; source_path = nothing)
	else
		throw(ArgumentError("Either 'from_file_path', 'from_default_set', or 'from_model_template' must be provided."))
	end
end

""" 
	load_matlab_battmo_input(inputFileName::String)

Reads the input from a MATLAB output file which contains a description of the model and returns an `MatlabInputParams`
that can be sent to the simulator.

# Arguments
- `inputFileName ::String` : Path to the MATLAB file.

# Returns
An instance of `MatlabInputParams` that can be sent to the simulator via `run_battery`.
"""
function load_matlab_battmo_input(filepath::String)
	inputparams = filepath |> matread |> MatlabInputParams
	return inputparams
end

"""
	load_battmo_formatted_input(filepath::String)

Reads and parses a JSON file into an `InputParams` instance.

# Arguments
- `filepath ::String` : Path to the JSON file.

# Returns
An instance of `InputParams`.
"""
function load_battmo_formatted_input(filepath::String)
	inputparams = filepath |> JSON.parsefile |> InputParams
	return inputparams
end




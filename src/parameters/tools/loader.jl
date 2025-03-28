export load_model_settings, load_cell_parameters, load_cycling_protocol, load_simulation_settings


#########################################
# Populate Parameters from JSON files
#########################################

function load_model_settings(filepath::String)
	model_settings_instance = filepath |> JSON.parsefile |> Dict |> ModelSettings
	return model_settings_instance
end

function load_cell_parameters(filepath::String)
	cell_parameters_instance = filepath |> JSON.parsefile |> Dict |> CellParameters
	return cell_parameters_instance
end


function load_cycling_protocol(filepath::String)
	cycling_protocol_instance = filepath |> JSON.parsefile |> Dict |> CyclingProtocol
	return cycling_protocol_instance
end


function load_simulation_settings(filepath::String)
	simulation_settings_instance = filepath |> JSON.parsefile |> Dict |> SimulationSettings
	return simulation_settings_instance
end

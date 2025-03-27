
export simulate

abstract type Output end

struct SimulationOutput <: Output
	states::Dict{String, Any}

end



# Define the run function that updates the results for the Simulate instance
function Jutul.simulate(model::BatteryModel, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol; simulation_settings::SimulationSettings)

	model_settings = model.model_settings
	validaded_cell_parameters = validate_parameter_set!(cell_parameters, model_settings)

	# inputparams = setup_battmo_input(model, cell_parameters, cycling_protocol, simulation_settings)

	# results = run_battery(inputparams)
	# output = SimulationOutput(results)
	return output

end


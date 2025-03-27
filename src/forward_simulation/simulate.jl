
export simulate

abstract type Output end

struct SimulationOutput <: Output
	states::Dict{String, Any}

end





# Define the run function that updates the results for the Simulate instance
function simulate(model::BatteryModel, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol)

	inputparams = create_battmo_simulation_input(model, cell_parameters, cycling_protocol)
	results = run_battery(inputparams)
	output = SimulationOutput(results)
	return output

end


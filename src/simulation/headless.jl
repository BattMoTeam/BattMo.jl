

"""
	run_simulation(simulation_input::FullSimulationInput; kwargs...)

Provides a headless UI for running a simulation.

# Arguments
- `simulation_input::FullSimulationInput`: A FullSimulationInput instance containing all the parameters and settings needed to run and solve a simulation.
- `kwargs...`: Additional keyword arguments passed to the lower-level solver configuration.

# Behavior
- Extracts all relevant parameter sets and settings from the FullSimulationInput instance.
- Instantiates a ModelConfigured using the provided model settings.
- Instantiates a Simulation using the ModelConfigured, and the cell parameters, cycling protocol parameters, and simulation settings from the FullSimulationInput.
- Solves the simulation by passing the Simulation instance and the solver settings from the FullSimulationInput to `BattMo.solve`.

# Returns
A NamedTuple containing the simulation results.

# Example
```julia
simulation_input = load_full_simulation_input(;from_default_set="Chen2020")
output = run_simulation(simulation_input)
plot_dashboard(output)
```
"""
function run_simulation(simulation_input::FullSimulationInput; logger = nothing, kwargs...)

	input = extract_input_sets(simulation_input)

	base_model = input.base_model
	if base_model == "LithiumIonBattery"
		model = LithiumIonBattery(; model_settings = input.model_settings)
	elseif base_model == "SodiumIonBattery"
		model = SodiumIonBattery(; model_settings = input.model_settings)
	else
		error("BaseModel $base_model is not valid. The following models are available: LithiumIonBattery, SodiumIonBattery")
	end

	sim = Simulation(model, input.cell_parameters, input.cycling_protocol; simulation_settings = input.simulation_settings)

	output = solve(sim; solver_settings = input.solver_settings, logger = logger, kwargs...)
	return output

end


function run_simulation(simulation_input::AdvancedDictInput; base_model = "LithiumIonBattery", logger = nothing, kwargs...)

	full_simulation_input = convert_to_full_simulation_input(simulation_input, base_model)
	return run_simulation(full_simulation_input)

end

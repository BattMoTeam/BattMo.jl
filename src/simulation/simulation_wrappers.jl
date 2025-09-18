export run_simulation


#####################################
# Headless UI

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
function run_simulation(simulation_input::FullSimulationInput; accept_invalid = false, logger = nothing, kwargs...)

	input = extract_input_sets(simulation_input)

	base_model = input.base_model
	model = get_model(base_model, input.model_settings)

	sim = Simulation(model, input.cell_parameters, input.cycling_protocol; simulation_settings = input.simulation_settings)

	output = solve(sim; accept_invalid, solver_settings = input.solver_settings, logger = logger, kwargs...)
	return output

end


#################################
# Advanced dict UI


function run_simulation(simulation_input::AdvancedDictInput; base_model = "LithiumIonBattery", accept_invalid = false, solver_settings = missing, logger = nothing, kwargs...)

	full_simulation_input = convert_to_full_simulation_input(simulation_input, base_model; solver_settings)
	return run_simulation(full_simulation_input; accept_invalid)

end

###################################
# Matlab UI

function run_simulation(simulation_input::MatlabInput; solver_settings::Union{SolverSettings, Missing} = missing, logger = nothing, kwargs...)

	model = LithiumIonBattery()

	sim_cfg = simulation_configuration(model, simulation_input)

	if ismissing(solver_settings)
		solver_settings = get_default_solver_settings(typeof(model))
	end

	output = solve_simulation(sim_cfg, kwargs...)

	return output

end

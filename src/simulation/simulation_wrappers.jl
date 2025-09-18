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

	model, couplings = setup_submodels(simulation_input)

	parameters = setup_battery_parameters(simulation_input, model)

	# setup the cross terms which couples the submodels.
	setup_coupling_cross_terms!(simulation_input, model, parameters, couplings)

	setup_initial_control_policy!(model[:Control].system.policy, simulation_input, parameters)

	state0 = setup_initial_state(simulation_input, model)

	forces = setup_forces(model)

	simulator = Simulator(model; state0 = state0, parameters = parameters, copy_state = true)

	timesteps = setup_timesteps(simulation_input; max_step = max_step)

	grids = get_grids(model)

	sim_cfg = (
		simulator = simulator,
		model = model,
		state0 = initial_state,
		forces = forces,
		timesteps = time_steps,
		grids = grids,
		couplings = couplings,
		parameters = parameters,
		simulation_settings = settings,
		cell_parameters = cell_parameters,
		cycling_protocol = cycling_protocol,
	)

	if ismissing(solver_settings)
		solver_settings = load_solver_settings(from_default_set = "direct")
	end

	states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	extra = Dict(:simulator => simulator,
		:forces => forces,
		:state0 => state0,
		:parameters => parameters,
		:model => model,
		:couplings => couplings,
		:grids => grids,
		:timesteps => timesteps,
		:cfg => cfg)
	extra[:timesteps] = timesteps

	return (states             = states,
		cellSpecifications = cellSpecifications,
		reports            = reports,
		input              = input,
		extra              = extra)

end

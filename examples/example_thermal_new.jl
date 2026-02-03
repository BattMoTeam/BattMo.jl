using Jutul, BattMo, GLMakie, Statistics

# ## Setup input parameters
name = "p2d_40_jl_chen2020"

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = load_advanced_dict_input(fn)

inputparams = merge_input_params(inputparams_geometry, inputparams)
inputparams = merge_input_params(inputparams, inputparams_thermal)

# Add Thermal Model
inputparams["use_thermal"] = true

# Add thermal parameters
# inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
# inputparams["ThermalModel"]["source"]                          = 1e4
# inputparams["ThermalModel"]["conductivity"]                    = 12

output = run_simulation(inputparams);

model      = output.model
multimodel = model.multimodel
states     = output.jutul_output.states
parameters = output.simulation.parameters
grids      = output.simulation.grids
maps       = output.simulation.global_maps
timesteps  = output.simulation.time_steps

input = (
	model_settings = output.simulation.model.settings,
	cell_parameters = output.simulation.cell_parameters,
	cycling_protocol = output.simulation.cycling_protocol,
	simulation_settings = output.simulation.settings,
)

thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)

forces = []
sources = []
for (i, state) in enumerate(states)
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source!(thermal_model, model, state, maps)
	push!(forces, (value = src,))
	push!(sources, stepsources)
end

nc = number_of_cells(thermal_model.domain)
T0 = 298*ones(nc)

thermal_state0 = setup_state(thermal_model, Dict(:Temperature => T0))

thermal_sim = Simulator(thermal_model;
	state0     = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)
thermal_states, = simulate(thermal_sim, timesteps; info_level = -1, forces = forces)

plot_interactive(thermal_model, thermal_states)

# Jutul.plot_interactive_impl(thermal_model.domain.representation.representation, sources)

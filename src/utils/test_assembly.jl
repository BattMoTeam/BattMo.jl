using Jutul, BattMo, GLMakie

dosetupelchem = true
if dosetupelchem

	# ## Setup input parameters
	name = "p2d_40_jl_chen2020"

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
	inputparams = load_advanced_dict_input(fn)

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
	inputparams_geometry = load_advanced_dict_input(fn)

	inputparams = merge_input_params(inputparams_geometry, inputparams)

	# ## Setup and run simulation
	output = run_simulation(inputparams);

	model      = output.jutul_output.multimodel
	maps       = output.simulation.global_maps
	states     = output.jutul_output.states
	timesteps  = output.simulation.time_steps
	parameters = output.simulation.parameters

end

doinitthermal = true
if doinitthermal

	using Jutul, BattMo, GLMakie, Statistics

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
	inputparams_geometry = load_advanced_dict_input(fn)

	fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
	inputparams_thermal = load_advanced_dict_input(fn)

	inputparams = merge_input_params(inputparams_geometry, inputparams_thermal)

	inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e1
	inputparams["ThermalModel"]["conductivity"]                    = 12

	# model, parameters = BattMo.setup_thermal_model(inputparams)
	thermal_model, thermal_parameters = BattMo.setup_thermal_model(inputparams)

end

dosetupforces = true
if dosetupforces

	forces = []
	sources = []
	for (i, state) in enumerate(states)
		state = BattMo.get_state_with_secondary_variables(model, state, parameters)
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

end

doplot = true
if doplot
	GLMakie.closeall()
	plot_interactive(thermal_model, thermal_states)
end


doplotsource = true
if doplotsource
	Jutul.plot_interactive_impl(thermal_model.domain.representation.representation, sources)
end

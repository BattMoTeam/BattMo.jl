using BattMo, Jutul, Test


@testset "thermal" begin

	@test begin

		# ## Setup input parameters
		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
		inputparams_material = load_advanced_dict_input(fn)

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
		inputparams_geometry = load_advanced_dict_input(fn)

		inputparams = merge_input_params([inputparams_material, inputparams_geometry])

		# Add control parameters
		fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
		inputparams_control = load_advanced_dict_input(fn)

		inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

		# Add thermal parameters
		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
		inputparams_thermal = load_advanced_dict_input(fn)

		inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

		# Add Thermal Model
		inputparams["use_thermal"] = true

		# Add thermal parameters
		# inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
		# inputparams["ThermalModel"]["source"]                          = 1e4
		# inputparams["ThermalModel"]["conductivity"]                    = 12

		output = run_simulation(inputparams; accept_invalid = true);

		model      = output.model
		multimodel = model.multimodel
		states     = output.jutul_output.states
		parameters = output.simulation.parameters
		grids      = output.simulation.grids
		maps       = output.simulation.global_maps
		timesteps  = output.simulation.time_steps[1:length(states)]

		t = output.time_series["Time"]
		E = output.time_series["Voltage"]
		I = output.time_series["Current"]


		input = (
			model_settings      = output.simulation.model.settings,
			cell_parameters     = output.simulation.cell_parameters,
			cycling_protocol    = output.simulation.cycling_protocol,
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

		T = [state[:Control][:Controller].time for state in states]

		@test length(thermal_states[1][:Temperature]) ≈ 556 atol = 0
		@test thermal_states[1][:Temperature][2] ≈ 298.14999996156644 atol = 1e-1
		@test thermal_states[1][:Temperature][100] ≈ 295.20098397016955 atol = 1e-1
		@test thermal_states[1][:Temperature][end] ≈ 298.1499999653794 atol = 1e-1

		@test thermal_states[40][:Temperature][2] ≈ 298.15000000713286 atol = 1e-1
		@test thermal_states[40][:Temperature][100] ≈ 288.3449387291137 atol = 1e-1
		@test thermal_states[40][:Temperature][end] ≈ 298.1500000109446 atol = 1e-1

		@test thermal_states[end][:Temperature][2] ≈ 298.150000007133 atol = 1e-1
		@test thermal_states[end][:Temperature][100] ≈ 290.68599259489594 atol = 1e-1
		@test thermal_states[end][:Temperature][end] ≈ 298.1500000109444 atol = 1e-1

		true

	end

end


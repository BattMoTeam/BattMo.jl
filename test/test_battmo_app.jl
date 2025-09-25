using BattMo, Jutul

function runP2DBatt(json_file)

	fraction_tot = 0
	dt_tot       = 0
	i            = 0

	# read input parameters from json file
	inputparams = load_advanced_dict_input(json_file)
	cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_to_parameter_sets(inputparams)

	# # setup simulation from the input parameters
	# output = get_simulation_input(inputparams)

	# simulator = output[:simulator]
	# model     = output[:model]
	# state0    = output[:state0]
	# forces    = output[:forces]
	# timesteps = output[:timesteps]
	# cfg       = output[:cfg]

	# # We modify the configuration using specific setup
	# cfg = setup_config(cfg,
	# 	model,
	# 	timesteps,
	# 	fraction_tot,
	# 	dt_tot,
	# 	i)

	# states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	model_setup = LithiumIonBattery(; model_settings)
	sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
	output = solve(sim; accept_invalid = true)

	states = output[:states]
	model = output[:extra][:model]
	multimodel = model.multimodel

	energy_efficiency = computeEnergyEfficiency(states)
	discharge_energy  = computeCellEnergy(states)

	con = BattMo.Constants()

	time_series = get_output_time_series(output)

	# Get some result values
	number_of_states                 = size(states)
	time_values                      = time_series[:Time]
	cell_voltage                     = [state[:Control][:Voltage][1] for state in states]
	cell_current                     = [state[:Control][:Current][1] for state in states]
	negative_electrode_grid_wrap     = physical_representation(multimodel[:NegativeElectrodeActiveMaterial])
	electrolyte_grid_wrap            = physical_representation(multimodel[:Electrolyte])
	positive_electrode_grid_wrap     = physical_representation(multimodel[:PositiveElectrodeActiveMaterial])
	negative_electrode_concentration = Array([[state[:NegativeElectrodeActiveMaterial][:SurfaceConcentration] for state in states] / 1000])
	electrolyte_concentration        = [state[:Electrolyte][:Concentration] for state in states] / 1000
	positive_electrode_concentration = Array([[state[:PositiveElectrodeActiveMaterial][:SurfaceConcentration] for state in states]] / 1000)
	negative_electrode_potential     = [state[:NegativeElectrodeActiveMaterial][:Voltage] for state in states]
	electrolyte_potential            = [state[:Electrolyte][:Voltage] for state in states]
	positive_electrode_potential     = [state[:PositiveElectrodeActiveMaterial][:Voltage] for state in states]

	nsteps = length(cell_voltage)
	time_values = time_values[1:nsteps]

	# Mesh cell centroids coordinates
	centroids_NeAm  = negative_electrode_grid_wrap[:cell_centroids, Cells()]
	centroids_Elyte = electrolyte_grid_wrap[:cell_centroids, Cells()]
	centroids_PeAm  = positive_electrode_grid_wrap[:cell_centroids, Cells()]

	# Boundary faces coordinates
	boundaries_NeAm  = negative_electrode_grid_wrap[:boundary_centroids, BoundaryFaces()]
	boundaries_Elyte = electrolyte_grid_wrap[:boundary_centroids, BoundaryFaces()]
	boundaries_PeAm  = positive_electrode_grid_wrap[:boundary_centroids, BoundaryFaces()]

	negative_electrode_grid          = centroids_NeAm .* 10^6
	negative_electrode_grid_bc       = boundaries_NeAm .* 10^6
	electrolyte_grid                 = centroids_Elyte .* 10^6
	electrolyte_grid_bc              = boundaries_Elyte .* 10^6
	positive_electrode_grid          = centroids_PeAm .* 10^6
	positive_electrode_grid_bc       = boundaries_PeAm .* 10^6
	negative_electrode_concentration = negative_electrode_concentration[1]
	positive_electrode_concentration = positive_electrode_concentration[1]

	return (number_of_states,
		cell_voltage,
		cell_current,
		time_values,
		negative_electrode_grid,
		negative_electrode_grid_bc,
		electrolyte_grid,
		electrolyte_grid_bc,
		positive_electrode_grid,
		positive_electrode_grid_bc,
		negative_electrode_concentration,
		electrolyte_concentration,
		positive_electrode_concentration,
		negative_electrode_potential,
		electrolyte_potential,
		positive_electrode_potential,
		discharge_energy,
		energy_efficiency)

end


function setup_config(cfg,
	model::MultiModel,
	timesteps,
	fraction_tot,
	dt_tot,
	i)

	if model[:Control].system.policy isa CyclingCVPolicy

		cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> BattMo.check_constraints(model, storage)

		function post_hook(done, report, sim, dt, forces, max_iter, cfg)

			s = Jutul.get_simulator_storage(sim)
			m = Jutul.get_simulator_model(sim)

			if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
				report[:stopnow] = true
			else
				report[:stopnow] = false
			end

			if done
				i            += 1
				total_time   = sum(timesteps)
				dt_tot       += dt
				fraction     = dt / total_time
				fraction_tot += fraction
			end

			return (done, report)

		end

		cfg[:post_ministep_hook] = post_hook

	end

	return cfg

end

json_file = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/p2d_40_jl_chen2020.json")

@testset "app test" begin
	@test begin
		runP2DBatt(json_file)
		true
	end
end

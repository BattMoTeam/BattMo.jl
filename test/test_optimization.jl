using BattMo
using Test


@testset "optimization" begin

	@test begin

		name = "Chen2020_calibrated"
		cell_parameters = load_cell_parameters(; from_default_set = name)
		cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

		model_setup = LithiumIonBattery()

		sim = Simulation(model_setup, cell_parameters, cycling_protocol)

		output_0 = solve(sim)

		states = output_0[:states]

		# # Specify an objective

		# Objective: Penalize any voltage less than target value of 4.2 (higher than initial voltage for battery)
		v_target = 4.2
		function objective(model, state, dt, step_no, forces)
			return dt * max(v_target - state[:Control][:Phi][1], 0)^2
		end

		# # Setup the optimization problem

		opt = Optimization(output_0, objective)

		# # Solve the optimization problem

		output_tuned = solve(opt)

		true
	end

end


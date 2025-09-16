using BattMo, Jutul
using Test

@testset "3d amg" begin

	@test begin

		name = "p2d_40_jl_chen2020"

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
		inputparams = load_battmo_formatted_input(fn)

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
		inputparams_geometry = load_battmo_formatted_input(fn)

		inputparams = merge_input_params(inputparams_geometry, inputparams)

		cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_old_input_format_to_parameter_sets(inputparams)

		model_setup = LithiumIonBattery(; model_settings)
		sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

		simulator = sim.simulator
		model     = sim.model
		state0    = sim.initial_state
		forces    = sim.forces
		timesteps = sim.time_steps

		solver  = :fgmres
		fac     = 1e-4       # NEEDED  
		rtol    = 1e-4 * fac # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
		atol    = 1e-5 * fac # seems important
		max_it  = 100
		verbose = 0

		varpreconds = Vector{BattMo.VariablePrecond}()
		push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Voltage, :charge_conservation, nothing))
		g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)

		params                       = Dict()
		params["method"]             = "block"
		params["post_solve_control"] = true
		params["pre_solve_control"]  = true

		prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)

		linear_solver = GenericKrylov(solver;
			verbose            = verbose,
			preconditioner     = prec,
			relative_tolerance = rtol,
			absolute_tolerance = atol,
			max_iterations     = max_it)


		output = solve(sim; accept_invalid = true,
			info_level = -1,
			failure_cuts_timestep = false,
			linear_solver = linear_solver)

		states = output.states


		Cc = map(x -> x[:Control][:Current][1], states)
		phi = map(x -> x[:Control][:Voltage][1], states)
		@test length(states) == 80
		@test Cc[1] ≈ 0.008165838495401362 atol = 1e-4
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.008165 atol = 1e-4
		end
		@test phi[1] ≈ 4.006456739146556 atol = 1e-2
		@test phi[end] ≈ 2.7485026725636326 atol = 1e-2

		true
	end
end

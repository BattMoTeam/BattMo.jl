using BattMo, Jutul
using Test

@testset "3d amg" begin

	@test begin

		name = "p2d_40_jl_chen2020"

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
		inputparams = load_advanced_dict_input(fn)

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
		inputparams_geometry = load_advanced_dict_input(fn)

		inputparams = merge_input_params(inputparams_geometry, inputparams)

		inputparams["TimeStepping"]["timeStepDuration"] = 40
		cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_to_parameter_sets(inputparams)

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
		push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :ElectricPotential, :charge_conservation, nothing))
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
			info_level = 0,
			failure_cuts_timestep = false,
			linear_solver = linear_solver)

		jutul_states = output.jutul_output.states


		Cc = map(x -> x[:Control][:Current][1], jutul_states)
		phi = map(x -> x[:Control][:ElectricPotential][1], jutul_states)
		@test length(jutul_states) == 95
		@test Cc[1] ≈ 0.0 atol = 0.0
		for i in 6:length(Cc)
			@test Cc[i] ≈ 0.009073153883779286 atol = 1e-4
		end
		@test phi[1] ≈ 4.192911496766219 atol = 1e-2
		@test phi[end] ≈ 2.5509998796470175 atol = 1e-2

		true
	end
end

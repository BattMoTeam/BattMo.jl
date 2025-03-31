using BattMo, Jutul
using Test

@testset "3d amg" begin
	@test begin
		name = "p2d_40_jl_chen2020"

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/old/", name, ".json")
		inputparams = readBattMoJsonInputFile(fn)

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/old/3d_demo_geometry.json")
		inputparams_geometry = readBattMoJsonInputFile(fn)

		inputparams = mergeInputParams(inputparams_geometry, inputparams)

		output = setup_simulation(inputparams)

		simulator = output[:simulator]
		model     = output[:model]
		state0    = output[:state0]
		forces    = output[:forces]
		timesteps = output[:timesteps]
		cfg       = output[:cfg]

		cfg[:info_level] = -1
		cfg[:failure_cuts_timestep] = false

		solver  = :fgmres
		fac     = 1e-4  #NEEDED  
		rtol    = 1e-4 * fac  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
		atol    = 1e-5 * fac # seems important
		max_it  = 100
		verbose = 0

		varpreconds = Vector{BattMo.VariablePrecond}()
		push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Phi, :charge_conservation, nothing))
		g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)

		params                       = Dict()
		params["method"]             = "block"
		params["post_solve_control"] = true
		params["pre_solve_control"]  = true

		prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)

		cfg[:linear_solver] = GenericKrylov(solver, verbose = verbose,
			preconditioner = prec,
			relative_tolerance = rtol,
			absolute_tolerance = atol,
			max_iterations = max_it)
		#cfg[:linear_solver]  = nothing

		# cfg[:extra_timing] = true

		states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)
		Cc = map(x -> x[:Control][:Current][1], states)
		phi = map(x -> x[:Control][:Phi][1], states)
		@test length(states) == 77
		@test Cc[1] ≈ 0.00058 atol = 1e-2
		for i in 3:length(Cc)
			@test Cc[i] ≈ 0.008165 atol = 1e-2
		end
		@test phi[1] ≈ 4.175 atol = 1e-1
		@test phi[end] ≈ 2.76 atol = 1e-2
		@test phi[30] ≈ 3.67 atol = 1e-2
		true
	end
end

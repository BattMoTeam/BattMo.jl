function batterylinearsolver(nosplit = true, p2d = true)

	if !p2d
		if method == "simple"
			varpreconds = Vector{BattMo.VariablePrecond}()
			push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Voltage, :charge_conservation, nothing))
			g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)
		elseif method == "split"
			prec_org_s = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_s = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org_s,
				relative_tolerance = 1e-5,
				absolute_tolerance = atol * fac_s * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			prec_org_p = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_p = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org_p,
				relative_tolerance = 1e-6,
				absolute_tolerance = atol * fac_p * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			s_prec = SolverAsPreconditionerSystem(ksolver_s)
			p_prec = SolverAsPreconditionerSystem(ksolver_p)
			s_preccond = BattMo.VariablePrecond(s_prec, :Concentration, :mass_conservation, nothing)
			p_preccond = BattMo.VariablePrecond(p_prec, :Voltage, :charge_conservation, nothing)
			varpreconds = Vector{BattMo.VariablePrecond}()
			push!(varpreconds, deepcopy(p_preccond))
			push!(varpreconds, deepcopy(s_preccond))

			g_varprecond = nothing
		elseif method == "genneral"
			prec_org = Jutul.AMGPreconditioner(:ruge_stuben)
			solver_p = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org,
				relative_tolerance = 1e-7,
				absolute_tolerance = atol * fac_p * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			varpreconds = Vector{BattMo.VariablePrecond}()
			p_prec = SolverAsPreconditionerSystem(solver_p)
			p_preccond = BattMo.VariablePrecond(p_prec, :Voltage, :charge_conservation, nothing)
			push!(varpreconds, deepcopy(p_preccond))

			solver_s = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org,
				relative_tolerance = 1e-6,
				absolute_tolerance = atol * fac_s * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			cmodels = [[:NegativeElectrodeActiveMaterial], [:PositiveElectrodeActiveMaterial], [:Electrolyte]]
			for mm in cmodels
				println(mm)
				s_prec = SolverAsPreconditionerSystem(solver_s)
				s_preccond = BattMo.VariablePrecond(s_prec, :Concentration, :mass_conservation, mm)
				push!(varpreconds, deepcopy(s_preccond))
			end

			g_varprecond = nothing

		else
			error()
		end
	else
		if method == "simple"
		elseif method == "genneral"
			prec_org = Jutul.AMGPreconditioner(:ruge_stuben)
			solver_p = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org,
				relative_tolerance = 1e-7,
				absolute_tolerance = atol * fac_p * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			varpreconds = Vector{BattMo.VariablePrecond}()
			p_prec = SolverAsPreconditionerSystem(solver_p)
			p_preccond = BattMo.VariablePrecond(p_prec, :Voltage, :charge_conservation, nothing)
			push!(varpreconds, deepcopy(p_preccond))

			solver_s = GenericKrylov(solver, verbose = 0,
				preconditioner = prec_org,
				relative_tolerance = 1e-6,
				absolute_tolerance = atol * fac_s * 1e-22,
				max_iterations = max_it,
				min_iterations = 4)
			cmodels = [[:NegativeElectrodeActiveMaterial], [:PositiveElectrodeActiveMaterial]]
			for mm in cmodels
				println(mm)
				s_prec = SolverAsPreconditionerSystem(solver_s)
				s_preccond = BattMo.VariablePrecond(s_prec, :ParticleConcentration, :mass_conservation, mm)
				push!(varpreconds, deepcopy(s_preccond))
			end

			# cmodels = [[:NegativeElectrodeActiveMaterial], [:PositiveElectrodeActiveMaterial]]
			# for mm in cmodels
			#     println(mm)
			#     s_prec = SolverAsPreconditionerSystem(solver_s)
			#     s_preccond = BattMo.VariablePrecond(s_prec,:SurfaceConcentration,:solid_diffusion_bc, mm)
			#     push!(varpreconds, deepcopy(s_preccond))
			# end

			cmodels = [[:Electrolyte]]
			for mm in cmodels
				println(mm)
				s_prec = SolverAsPreconditionerSystem(solver_s)
				s_preccond = BattMo.VariablePrecond(s_prec, :Concentration, :mass_conservation, mm)
				push!(varpreconds, deepcopy(s_preccond))
			end

			g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)
			g_varprecond = nothing
		else
			error()
		end

	end

	prec    = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)
	solver  = :fgmres
	fac     = 1e-3
	rtol    = 1e-4 * fac  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
	atol    = 1e-5 * fac # seems important
	max_it  = 100
	verbose = 1
	solver  = GenericKrylov(solver, verbose = verbose,
	preconditioner = prec,
	relative_tolerance = rtol,
	absolute_tolerance = atol,
	max_iterations = max_it)
	return solver
end

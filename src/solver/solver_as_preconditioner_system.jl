mutable struct SolverAsPreconditionerSystem <: JutulPreconditioner
	solver::Any#::LinearSolver
	sys::Any#::LinearizedSystem
	prec::Any
	function SolverAsPreconditionerSystem(solver)
		new(solver, nothing, nothing)
	end

end
# function Jutul.update_preconditioner!(solver::SolverAsPreconditionerSystem,A,b, context, executor)
#     #update_preconditioner!(solver.prec,A,b, context, executor)
#     solver.sys = Jutul.LinearizedSystem(A, nothing)
#     Jutul.update_preconditioner!(solver.prec,A,b, context, executor)
# end
function Jutul.update_preconditioner!(solver::SolverAsPreconditionerSystem, lsys, context, model, storage, recorder, executor)
	#update_preconditioner!(solver.prec,A,b, context, executor)
	solver.sys = lsys #Jutul.LinearizedSystem(A, nothing)
	#recorder = Jutul.ProgressRecorder()
	update_preconditioner!(solver.prec, lsys, context, model, storage, recorder, executor)
end

function Jutul.apply!(x, solverasprec::SolverAsPreconditionerSystem, y, args...; kwargs...)
	solver = solverasprec.solver
	sys = solverasprec.sys
	#Jutul.warm_start(solver,dx)
	x .= 0
	linear_solve!(sys, solver, args...; dx = x, r = y, kwargs...)
	#solver.sys.r = y
	#setfield!(solver.sys.r,:r, y)
	#Jutul.linear_solve!(solver.sys, solver, arg...;kwargs...)
	#Jutul.linear_solve!(solver.sys, solver, )
	#x = solverasprec.sys.dx
end



mutable struct SolverAsPreconditionerSystem <: Jutul.JutulPreconditioner
    solver#::LinearSolver
    sys#::LinearizedSystem
    prec
    function SolverAsPreconditionerSystem(solver)
        new(solver,nothing, nothing)
    end

end
# function Jutul.update_preconditioner!(solver::SolverAsPreconditionerSystem,A,b, context, executor)
#     #update_preconditioner!(solver.prec,A,b, context, executor)
#     solver.sys = Jutul.LinearizedSystem(A, nothing)
#     Jutul.update_preconditioner!(solver.prec,A,b, context, executor)
# end
function Jutul.update_preconditioner!(solver::SolverAsPreconditionerSystem,lsys, model, storage, context, executor)
     #update_preconditioner!(solver.prec,A,b, context, executor)
     solver.sys = lsys #Jutul.LinearizedSystem(A, nothing)
     recorder = Jutul.ProgressRecorder()
     Jutul.update_preconditioner!(solver.prec, lsys, model, storage, recorder, executor)
end

function Jutul.apply!(x, solverasprec::SolverAsPreconditionerSystem, y, args...;kwargs...)
    solver = solverasprec.solver
    sys = solverasprec.sys
    Jutul.linear_solve!(sys, solver, args...;dx = x, r = y, kwargs...)
    #solver.sys.r = y
    #setfield!(solver.sys.r,:r, y)
    #Jutul.linear_solve!(solver.sys, solver, arg...;kwargs...)
    #Jutul.linear_solve!(solver.sys, solver, )
    #x = solverasprec.sys.dx
end
function Jutul.operator_nrows(perc::SolverAsPreconditionerSystem)
    return size(prec.sys.jac,1);
end

function Jutul.linear_operator(precond::SolverAsPreconditionerSystem, side::Symbol, float_t, sys, model, storage, recorder)
    n = operator_nrows(precond)
    function local_mul!(res, x, α, β::T, type) where T
        if β == zero(T)
            apply!(res, precond, x, model)
            if α != one(T)
                lmul!(α, res)
            end
        else
            error("Not implemented yet.")
        end
    end

    if side == :left
        if Jutul.is_left_preconditioner(precond)
            if Jutul.is_right_preconditioner(precond)
                f! = (r, x, α, β) -> local_mul!(r, x, α, β, :left)
            else
                f! = (r, x, α, β) -> local_mul!(r, x, α, β, :both)
            end
            op = Jutul.LinearOperator(float_t, n, n, false, false, f!)
        else
            op = Jutul.opEye(n, n)
        end
    elseif side == :right
        if Jutul.is_right_preconditioner(precond)
            f! = (r, x, α, β) -> local_mul!(r, x, α, β, :right)
            op = Jutul.LinearOperator(float_t, n, n, false, false, f!)
        else
            op = Jutul.opEye(n, n)
        end
    else
        error("Side must be :left or :right, was $side")
    end

    return op
end
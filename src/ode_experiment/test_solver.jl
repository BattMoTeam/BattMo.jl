using DifferentialEquations

function f(res,du,u,p,t)
    res[1] = du[1] - 2.0 * u[1] + 1.2 * u[1]*u[2] -1
    res[2] = du[2] -3 * u[2] - u[1]*u[2] - 1
end

g=DAEFunction(f,syms=[:pop, :dop])
prob=DAEProblem(g,ones(2), zeros(2),(0,10),differential_vars=ones(2))
sol=solve(prob)
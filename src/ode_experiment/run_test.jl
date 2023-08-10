using BattMo, DifferentialEquations, Jutul, Sundials, DiffEqBase

include("state_variable_mapping.jl")

#init = BattMo.MatlabFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/model1D_50.mat")
init = JSONFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/jsonfiles/p2d_40_jl.json")
use_p2d=false
use_groups=false
extra_timing=false
max_step=nothing
linear_solver=:direct
general_ad=false
use_groups=false

#Setup simulation
sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

#Set up config and timesteps
timesteps=BattMo.setup_timesteps(init;max_step=max_step)
cfg=BattMo.setup_config(sim,model,linear_solver,extra_timing)



y0 = stateToVariable(sim.storage[:state],model)
#variableToState!(state0,y0,model)

#sim.storage[:state]=state0
r=odeFun!(y0,y0,nothing,0,model,sim,forces)

f!(dy,y,p,t) = odeFun!(dy,y,p,t,model,sim,forces)

tspan = (0.0, 5000)

#DAE
#prob=DAEProblem(f!,y0*.0,y0,tspan,differential_vars=(ones(size(y0)).!=1.0))
#solve(prob)

#ODE 
prob=ODEProblem(f,y0,tspan)
solve(prob,Rosenbrock23(autodiff=false))

#Q: Modify sim.storage[:state] directly?
#println(state0[:BPP])
#println("Storage state")
#println(sim.storage[:state][:BPP])
#st=sim.storage[:state]
#variableToState!(sim.storage[:state],y0,model)
#println("modified")
#println(st)

#println(y0)

#r = odeFun!(y0,y0,nothing,0,model,sim,forces)
#println(r)
#problem = DifferentialEquations.DAEProblem(f!,y0,timesteps)

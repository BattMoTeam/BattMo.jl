import BattMo, DifferentialEquations

init = BattMo.MatlabFile()
use_p2d=false
use_groups=false
extra_timing=false
max_step=nothing
linear_solver=:direct
general_ad=false
use_groups=false

#Setup simulation
sim, forces, state0, parameters, init, model = setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

#Set up config and timesteps
timesteps=setup_timesteps(init;max_step=max_step)
cfg=setup_config(sim,model,linear_solver,extra_timing)

#Perform simulation
f!(dy,y,p,t) = odeFun!(dy,y,p,y,model,state,forces,config)

y0 = stateToVariable(state0,model)

problem = DifferentialEquations.DAEProblem(f!,y0,timesteps)

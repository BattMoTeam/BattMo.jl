using BattMo, DifferentialEquations, Sundials, DiffEqBase, Plots
import Jutul, ForwardDiff
import LinearAlgebra

include("state_variable_mapping.jl")

#init = BattMo.MatlabFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/p2d_40.mat")
#init = BattMo.JSONFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/jsonfiles/p2d_40_jl.json")
init = BattMo.MatlabFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/src/ode_experiment/test_model_cc_04.mat",state_ref=false)
use_p2d=false
use_groups=false
extra_timing=false
max_step=nothing
linear_solver=:direct
general_ad=true

#Setup simulation
#Resize_state!(init,0.4)
#init.object["Control"]["CRate"]=1e-100
#init.object["Control"]["lowerCutoffVoltage"]=3

sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
#state0[:BPP][:Phi][1] = state0[:PP][:Phi][1]
#state0[:BPP][:Current][1] = 0.0

#Solve problem using Jutul first

#Set up config and timesteps
timesteps=BattMo.setup_timesteps(init;max_step=max_step)
cfg=BattMo.setup_config(sim,model,linear_solver,extra_timing)

eff_state0=copy(state0)
hsim=Jutul.HelperSimulator(model,Float64, state0=eff_state0, parameters=parameters,ad=true)
x0 = Jutul.vectorize_variables(model, sim.storage.state)

# @time begin
#     states, reports = Jutul.simulate(state0,sim, timesteps, forces=forces, config=cfg)    
# end

# voltage = map(state -> state[:BPP][:Phi][1], states)
# t = cumsum(timesteps)

dt=1
#Residual + jacobian
#r,jac = Jutul.model_residual(hsim,x0,missing,dt, forces = forces, time = (0.0 - dt), include_accumulation=false) 
m, m_jac = Jutul.model_accumulation(sim, x0)
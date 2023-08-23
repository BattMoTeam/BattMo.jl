using BattMo, DifferentialEquations, Sundials, DiffEqBase, Plots
import Jutul, ForwardDiff
import LinearAlgebra, SparseArrays, BandedMatrices

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
x0 = Jutul.vectorize_variables(model, state0)

# @time begin
#     states, reports = Jutul.simulate(state0,sim, timesteps, forces=forces, config=cfg)    
# end

# voltage = map(state -> state[:BPP][:Phi][1], states)
# t = cumsum(timesteps)

#Residual + jacobian
#r,jac = Jutul.model_residual(hsim,x0,missing,dt, forces = forces, time = (0.0 - dt), include_accumulation=false) 
m, m_jac = Jutul.model_accumulation(sim, x0);
r= Jutul.model_residual(sim,x0,x0,1e-8;forces=forces,time=0.0,include_accumulation=false,update_secondary=true)

ind = SparseArrays.findnz(m_jac)[1]
vars= zeros(Integer,length(x0))
vars[ind].=1

f!(res,dy,y,p,t) = odeFun!(res,dy,y,p,t,sim,forces)
f_jac!(J,dy,y,p,gamma,t) = odeFun_jac!(J,dy,y,p,gamma,t,sim,forces)

res = zeros(length(x0))
J = zeros(length(x0),length(x0))
dx0 = (-1)*(r \ m_jac)'
f!(res,dx0,x0,nothing,0.0)

#prototype = SparseArrays.spzeros(length(x0),length(x0))
#f_jac!(prototype,dx0,x0,nothing,1.0,0.0) 
prototype = SparseArrays.sparse(BandedMatrices.BandedMatrix(BandedMatrices.Zeros(length(x0),length(x0)), (20,20)))

r_approx = approx_jac(odeFun!,0.0,[1e-6,0],x0,dx0,sim,forces)
diff = sim.storage.LinearizedSystem.jac - r_approx
println(findmax(abs.(SparseArrays.findnz(diff)[3])))

dt=1e-7
f_DAE! = DAEFunction(f!; jac=f_jac!, jac_prototype=prototype)
tspan=(0.0,4000)
prob = DAEProblem(f_DAE!,dx0,x0,tspan,differential_vars=vars)
@time begin
    ret = solve(prob,IDA(linear_solver=:Dense))
end
vv= getindex.(ret.u,49)
Plots.plot(ret.t,vv)
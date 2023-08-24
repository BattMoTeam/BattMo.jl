using BattMo, DifferentialEquations, Sundials, DiffEqBase, Plots
import Jutul, ForwardDiff
import LinearAlgebra, SparseArrays, BandedMatrices

include("state_variable_mapping.jl")

#init = BattMo.MatlabFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/p2d_40.mat",state_ref=false)
#init = BattMo.JSONFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/jsonfiles/p2d_40_jl.json")
init = BattMo.MatlabFile("test_model_cc_04.mat",state_ref=false)
use_p2d=false
use_groups=false
extra_timing=false
max_step=nothing
linear_solver=:direct
general_ad=true

sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

timesteps=BattMo.setup_timesteps(init;max_step=max_step)
cfg=BattMo.setup_config(sim,model,linear_solver,extra_timing)

x0 = Jutul.vectorize_variables(model, state0)

@time begin
    states, reports = Jutul.simulate(state0,sim, timesteps, forces=forces, config=cfg)    
end

voltage = map(state -> state[:BPP][:Phi][1], states)
t = cumsum(timesteps)

#setup new sim
sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad, mode=:sensitivities)

m, m_jac = Jutul.model_accumulation(sim, x0);
r= Jutul.model_residual(sim,x0,x0,1e-8;forces=forces,time=0.0,include_accumulation=false,update_secondary=true)

#Determine differential variables
ind = SparseArrays.findnz(m_jac)[1] #We assume m to be linear in u
vars= zeros(Integer,length(x0))
vars[ind].=1

#Residual + jacobian functions
f!(res,dy,y,p,t) = odeFun!(res,dy,y,p,t,sim,forces)
f_jac!(J,dy,y,p,gamma,t) = odeFun_jac!(J,dy,y,p,gamma,t,sim,forces)

res = zeros(length(x0))
J = zeros(length(x0),length(x0))
dx0 = (-1)*(r \ m_jac)'
f!(res,dx0,x0,nothing,0.0)

#Sparsity pattern prototype
prototype = SparseArrays.spzeros(length(x0),length(x0))
f_jac!(prototype,dx0,x0,nothing,1.0,10) 
pro_ind = SparseArrays.findnz(prototype)
for i=1:length(pro_ind[1])
    prototype[pro_ind[1][i],pro_ind[2][i]]=1.0
end

#Julia DifferentialEquations interface
f_DAE! = DAEFunction(f!; jac=f_jac!, jac_prototype=prototype)
tspan=(0.0,4000)
prob = DAEProblem(f_DAE!,dx0,x0,tspan,differential_vars=vars)
@time begin
    ret = solve(prob,IDA(linear_solver=:LapackDense))
end
vv= getindex.(ret.u,length(ret.u[1])-1)
Plots.plot(ret.t,vv, label="DiffEq")
Plots.plot!(t,voltage, label="Jutul")
using BattMo, DifferentialEquations, Sundials, DiffEqBase
import Jutul
import LinearAlgebra

include("state_variable_mapping.jl")

#init = BattMo.MatlabFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/model1D_50.mat")
init = BattMo.JSONFile("/home/andreas/SINTEF/json_experiment/BattMo.jl/test/battery/data/jsonfiles/p2d_40_jl.json")
use_p2d=false
use_groups=false
extra_timing=false
max_step=nothing
linear_solver=:direct
general_ad=true
use_groups=false

#Setup simulation
Resize_state!(init,0.4)
#init.object["Control"]["CRate"]=1e-100
#init.object["Control"]["lowerCutoffVoltage"]=3

sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
#state0[:BPP][:Phi][1] = state0[:PP][:Phi][1]
#state0[:BPP][:Current][1] = 0.0
#Set up config and timesteps
#timesteps=BattMo.setup_timesteps(init;max_step=max_step)
#cfg=BattMo.setup_config(sim,model,linear_solver,extra_timing)

hsim=Jutul.HelperSimulator(model,Float64, state0=state0, parameters=parameters)
#Initial state
x0 = Jutul.vectorize_variables(model, state0)
m0 = Jutul.model_accumulation(hsim, x0)
X0 = [m0 ; x0]
#Consistent initial state for time derivative
dm0 = Jutul.model_residual(hsim, x0, x0, 1, forces = forces, time = 0.0)
alt=Jutul.model_residual(hsim, x0, x0.*0, 1, forces = forces, time = 0.0) - dm0
println(LinearAlgebra.norm(m0-alt))

dx0 = Jutul.model_accumulation(hsim, x0)
dX0 = [dm0.*(-1) ; dx0.*0]
len=length(x0)

println(approximate_jacobian(x0,1e-6,hsim))
#Future type!
param = Dict(:sim => hsim, :forces => forces, :len => len, :model => model)
X_before = copy(X0)
dX_before = copy(dX0)
param_before = deepcopy(param)
# a=odeFun_big(dX0,X0,param,0.0)
# for i=1:100
#     diff=a-odeFun_big(dX0,X0,param,0.0)
#     println(length(diff))
#     println("m0: ", LinearAlgebra.norm(diff))
#     println("pos: ", findmax(abs.(a)))
# end
tspan = (0.0, 5)

#f(dy,y,p,t)=odeFun_big(dy,y,p,t,param[:sim],param[:forces],param[:model],param[:len])
#DAE
#prob=DAEProblem(f,dX0,X0,tspan,differential_vars=[zeros(Integer,len);ones(Integer,len)])
#solve(prob)

f_jac(dy,y,p,t)=odeFun_useJac(dy,y,p,t,hsim,forces)
prob=DAEProblem(f_jac,x0.*0,x0,tspan,differential_vars=ones(Integer,len))
solve(prob)
#ODE 
#prob=ODEProblem(f!,y0,tspan)
#solve(prob,Rosenbrock23(autodiff=false)) 
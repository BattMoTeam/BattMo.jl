using BattMo, DifferentialEquations, Sundials, DiffEqBase, Plots
import Jutul
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


sim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

#Solve problem using Jutul first

#Set up config and timesteps
timesteps=BattMo.setup_timesteps(init;max_step=max_step)
cfg=BattMo.setup_config(sim,model,linear_solver,extra_timing)


#Setup to solve from DiffEq library
start_ind=1
#eff_state0 = deepcopy(states[start_ind])
function toDict(state::Jutul.JutulStorage)
    state=Dict(pairs(state))
    for (k,v) in pairs(state)
        state[k]=Dict(pairs(v))
    end
    return state
end
#eff_state0=toDict(deepcopy(sim.storage.state))
#eff_state0=deepcopy(states[1])
eff_state0=copy(state0)
hsim, forces, state0, parameters, init, model = BattMo.setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
#hsim=Jutul.HelperSimulator(model,Float64, state0=eff_state0, parameters=parameters)
dt=0.000001
#Initial state
x0 = Jutul.vectorize_variables(model, eff_state0)
m0, _ = Jutul.model_accumulation(hsim, x0)
X0 = [m0 ; x0]
#Consistent initial state for time derivative
dm0 = Jutul.model_residual(hsim, x0, x0, dt, forces = forces, time = (0.0 - dt)) 
dX0 = [dm0.*(-1) ; zeros(length(dm0))]

len=length(x0)

#Future type!
param = Dict(:sim => hsim, :forces => forces)
#tspan = (sum(timesteps[1:start_ind]), sum(timesteps))
tspan = (0.0,4000)
f!(res,dy,y,p,t)=odeFun_big!(res,dy,y,p,t,param[:sim],param[:forces])
println(f!(zeros(2*len),dX0,X0,nothing,tspan[1]))
#DAE
prob=DAEProblem(f!,dX0.*0,X0,tspan,differential_vars=[ones(Integer,len);zeros(Integer,len)])

@time begin
    ret=solve(prob, Sundials.IDA())    
end

vv= getindex.(ret.u,99)
Plots.plot(ret.t,vv)

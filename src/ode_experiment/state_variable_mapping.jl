import Jutul
import BattMo
import LinearAlgebra

# #Generate vector of primary variables from a state
# function stateToVariable(state,model::Jutul.MultiModel)
#     mapper,=Jutul.variable_mapper(model,:primary) #primary variables mappper
#     #Vectorize primary variables collected with mapper
#     variable=Jutul.vectorize_variables(model,state,mapper)
#     return variable
# end

# #Recover a state from vector of primary variables
# function variableToState!(state,variable,model::Jutul.MultiModel)
#     mapper,=Jutul.variable_mapper(model,:primary)
#     Jutul.devectorize_variables!(state,model,variable,mapper)
# end

# #Change problem size
# function Resize_state!(init::BattMo.JSONFile, mult)
#     jsondict=init.object
#     jsondict["NegativeElectrode"]["CurrentCollector"]["N"]= Integer(mult*jsondict["NegativeElectrode"]["CurrentCollector"]["N"])
#     jsondict["NegativeElectrode"]["ActiveMaterial"]["N"]= Integer(mult*jsondict["NegativeElectrode"]["ActiveMaterial"]["N"])
#     jsondict["Electrolyte"]["Separator"]["N"] = Integer(mult*jsondict["Electrolyte"]["Separator"]["N"])
#     jsondict["PositiveElectrode"]["ActiveMaterial"]["N"]= Integer(mult*jsondict["PositiveElectrode"]["ActiveMaterial"]["N"])
#     jsondict["PositiveElectrode"]["CurrentCollector"]["N"] =Integer(mult*jsondict["PositiveElectrode"]["CurrentCollector"]["N"])
#     jsondict["NegativeElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"]=Int64(mult*jsondict["NegativeElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"])
#     jsondict["PositiveElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"]=Int64(mult*jsondict["PositiveElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"])

# end

function approx_jac(func, t, Δy,y,dy,sim,forces)
    n=length(y)
    jac=SparseArrays.spzeros(n,n)
    iid= Matrix(LinearAlgebra.I,n,n)
    for i=1:n
        y1 = y + iid[:,i]*Δy[1]
        dy1 = dy + iid[:,i]*Δy[2]
        fΔy=zeros(n)
        f=zeros(n)
        func(fΔy,dy1,y1,nothing,t,deepcopy(sim),deepcopy(forces))
        func(f,dy,y,nothing,t,deepcopy(sim),deepcopy(forces))
        jac[:,i].=(fΔy - f)./LinearAlgebra.norm(Δy)
    end
    return jac
end

function odeFun_big!(res,dX,X,p,t,sim,forces)
    """
    We solve the problem defining X = [m ; u] so that f(dX,X,t) = [f₁ ; f₂] = 0:
    f₁ = ∂m/∂t + r(u) = 0
    f₂ =   m   - M(u) = 0 
    """
    len = Integer(length(X)/2)
    dt=0.000001
    r= Jutul.model_residual(sim, X[len+1:end], X[len+1:end], dt, forces = forces, time = t - dt,include_accumulation=false, update_secondary=true)
    M,_=Jutul.model_accumulation(sim,X[len+1:end])
    res[1:len]=dX[1:len] + r
    res[len+1:end] = X[1:len] - M
end

function odeFun!(res,dy,y,p,t,sim,forces)
    dt=1e-8
    r=Jutul.model_residual(sim,y,y,dt;forces=forces,time=t,include_accumulation=false,update_secondary=true)
    _,m_jac = Jutul.model_accumulation(sim,y)
    #Calculate ∂m/∂t = ∂m/∂y ∂y/∂t
    ∂m∂t = m_jac * dy
    res .= ∂m∂t + r
end

function odeFun_jac!(J,dy,y,p,gamma,t,sim,forces)
    #A little bit dangerous...
    dt=1e-8

    #Does not work!
    r=Jutul.model_residual(deepcopy(sim),y,y,dt;forces=forces,time=t,include_accumulation=false,update_secondary=true)
    _,m_jac = Jutul.model_accumulation(deepcopy(sim),y)
    J .= m_jac .* gamma + sim.storage.LinearizedSystem.jac


    #dfdup = approx_jac(odeFun!,t,[0,1e-6],y,dy,deepcopy(sim),deepcopy(forces))
    #dfdu = approx_jac(odeFun!,t,[1e-6,0],y,dy,deepcopy(sim),deepcopy(forces))
    #println("dfdup ", LinearAlgebra.norm(dfdup-m_jac))
    #println("dfdu ", LinearAlgebra.norm(dfdu-sim.storage.LinearizedSystem.jac))
    J .= dfdup .*gamma + dfdu
    nothing
end

# function empty_state(example_state)
#     ret=example_state
#     for (k,v) in pairs(example_state)
#         if typeof(ret) <: Jutul.JutulStorage
#             ret[k]=empty_state(v)
#         elseif (typeof(ret) <: NamedTuple) | (typeof(ret) <: Dict)
#             if (typeof(v) <: Vector) | (typeof(v)<: Matrix)
#                 ret=merge(ret,[k=>v.*0])
#             end 
#         end
#     end
#     return ret
# end
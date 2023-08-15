import Jutul
import BattMo
import LinearAlgebra

#Generate vector of primary variables from a state
function stateToVariable(state,model::Jutul.MultiModel)
    mapper,=Jutul.variable_mapper(model,:primary) #primary variables mappper
    #Vectorize primary variables collected with mapper
    variable=Jutul.vectorize_variables(model,state,mapper)
    return variable
end

#Recover a state from vector of primary variables
function variableToState!(state,variable,model::Jutul.MultiModel)
    mapper,=Jutul.variable_mapper(model,:primary)
    Jutul.devectorize_variables!(state,model,variable,mapper)
end

#Change problem size
function Resize_state!(init::BattMo.JSONFile, mult)
    jsondict=init.object
    jsondict["NegativeElectrode"]["CurrentCollector"]["N"]= Integer(mult*jsondict["NegativeElectrode"]["CurrentCollector"]["N"])
    jsondict["NegativeElectrode"]["ActiveMaterial"]["N"]= Integer(mult*jsondict["NegativeElectrode"]["ActiveMaterial"]["N"])
    jsondict["Electrolyte"]["Separator"]["N"] = Integer(mult*jsondict["Electrolyte"]["Separator"]["N"])
    jsondict["PositiveElectrode"]["ActiveMaterial"]["N"]= Integer(mult*jsondict["PositiveElectrode"]["ActiveMaterial"]["N"])
    jsondict["PositiveElectrode"]["CurrentCollector"]["N"] =Integer(mult*jsondict["PositiveElectrode"]["CurrentCollector"]["N"])
    jsondict["NegativeElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"]=Int64(mult*jsondict["NegativeElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"])
    jsondict["PositiveElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"]=Int64(mult*jsondict["PositiveElectrode"]["ActiveMaterial"]["SolidDiffusion"]["N"])

end

function approximate_jacobian(y,Δx,sim)
    n=length(y)
    jac=Array{Float64}(undef,n,n)
    iid= Matrix(LinearAlgebra.I,n,n)
    M = Jutul.model_accumulation(sim,y)
    for i=1:n
        MΔx = Jutul.model_accumulation(sim,y + iid[:,i].*Δx)
        jac[:,i]=(MΔx - M)./Δx
    end
    return jac
end

function odeFun_useJac(dy,y,p,t,sim,forces)
    r= Jutul.model_residual(sim,y,y,1,forces=forces, time = t,include_accumulation=false, update_secondary=true)
    M_jac=approximate_jacobian(y,1e-6,sim)
    MΔt = M_jac * dy
    return MΔt + r
end

function odeFun_big(dX,X,p,t,sim1,forces1,model1,len1)
    res=zeros(2*len1)
    sim=deepcopy(sim1)
    forces=deepcopy(forces1)
    model=deepcopy(model1)
    len = copy(len1)

    #variableToState!(sim.storage[:state], X[len+1:end],model)
    r= Jutul.model_residual(sim, X[len+1:end], X[len+1:end], 1, forces = forces, time = t,include_accumulation=false, update_secondary=true)
    #Works because Δt=1
    #M= Jutul.model_residual(sim, X[len+1:end], zeros(len), 1, forces = forces, time = t,include_accumulation=true, update_secondary=false) - r
    M=Jutul.model_accumulation(sim,X[len+1:end])
    res[1:len]=dX[1:len] + r
    res[len+1:end] = (X[1:len] - M).*0
    println(findmax(abs.(res)))
    return res
end

function odeFun!(dy,y,p,t,model,sim,forces)
    
    #Change state in storage
    variableToState!(sim.storage[:state],y,model)
    state= deepcopy(sim.storage[:state])

    dt=1 # Dummy 
    update_secondary=true

    #Source + div terms for state
    sim.storage[:state0]=deepcopy(state)
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq1 = deepcopy(sim.storage.LinearizedSystem)

    #Create an empty state
    null_state=empty_state(deepcopy(state))
    sim.storage[:state0]=null_state

    #Calculate M(state):
    sim.storage[:state]=null_state
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq2 = sim.storage.LinearizedSystem

    sim.storage[:state0]=deepcopy(state)
    accum = ((eq2.jac -eq1.jac)*dt)*dy
    println(all(@. (eq2.r -eq1.r)==0.0))
    return eq1.r + accum
end

function empty_state(example_state)
    ret=example_state
    for (k,v) in pairs(example_state)
        if typeof(ret) <: Jutul.JutulStorage
            ret[k]=empty_state(v)
        elseif (typeof(ret) <: NamedTuple) | (typeof(ret) <: Dict)
            if (typeof(v) <: Vector) | (typeof(v)<: Matrix)
                ret=merge(ret,[k=>v.*0])
            end 
        end
    end
    return ret
end
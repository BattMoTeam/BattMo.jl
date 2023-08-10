import Jutul
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

function odeFun!(dy,y,p,t,model,sim,forces)
    
    #Change state in storage
    variableToState!(sim.storage[:state],y,model)
    state0 =sim.storage[:state0]
    state= sim.storage[:state]

    dt=1 # Dummy 
    update_secondary=true

    #Source + div terms for state
    sim.storage[:state0]=state
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq1 = sim.storage.LinearizedSystem.r

    #Source + div terms for state0
    sim.storage[:state]=state0
    sim.storage[:state0]=state0
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq10 = sim.storage.LinearizedSystem.r

    #Create an empty state
    null_state=empty_state(sim.storage[:state])
    sim.storage[:state0]=null_state

    #Calculate M(state):
    sim.storage[:state]=state
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq2 = (sim.storage.LinearizedSystem.r - eq1)*dt
    #Calculate M(state0)
    #Update time somehow?    
    sim.storage[:state]=state0
    Jutul.update_state_dependents!(sim.storage, model, dt, forces, time = t, update_secondary = update_secondary)
    Jutul.update_linearized_system!(sim.storage, model, sim.executor)
    eq3 = (sim.storage.LinearizedSystem.r - eq10)*dt

    accum = (eq2-eq3)/dt
    println(eq1 +accum)
    return eq1 + accum
end

function empty_state(example_state)
    ret=example_state
    for (k,v) in pairs(example_state)
        if typeof(ret) <: Jutul.JutulStorage
            ret[k]=empty_state(v)
        elseif typeof(ret) <: NamedTuple
            if typeof(v) <: Vector 
                ret=merge(ret,[k=>v.*0])
            end 
        end
    end
    return ret
end
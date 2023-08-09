import Jutul

#Genereate vector of primary variables from a state
function stateToVariable(state,model::Jutul.MultiModel)
    mapper,=Jutul.variable_mapper(model) #primary variables mappper
    #Vectorize primary variables collected with mapper
    variable=Jutul.vectorize_variables(model,state,mapper)
    return variable
end

#Recover a state from vector of primary variables
function variableToState!(state,variable,model::Jutul.MultiModel)
    mapper,=Jutul.variable_mapper(model)
    Jutul.devectorize_variables!(state,model,variable,mapper)
end

function odeFun!(dy,y,p,t,model,storage,forces,config)
    #Change state in storage
    
    state=variableToState!(state,y,model)

    dt=1 # Dummy 
    #Update time somehow?


    #Time?
    #update_state_dependents!(storage, model, dt, forces, time = time, update_secondary = update_secondary)
    #update_linearized_system!(storage, model, executor)
    
    #Update eqations etc with perform step!
    #Q: Difference between state and storage? Conversion
    perform_step!(state,model,dt,forces,config; solve=false)

    #Now extract state.LinearizedSystem.r somehow?
    #Q: What type is storage.LinearizedSystem.r? Use some conversion... 
    
end

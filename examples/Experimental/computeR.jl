using Infiltrator, Jutul, BattMo

"""
   getStateWithSecondaryVariables(model, state, parameters)

Compute and add to the state variables all the secondary variables

# Arguments

- `model`      :
- `state`      :

# Returns

state : state with the added secondary variables

"""
function getStateWithSecondaryVariables(model, state, parameters)

    storage = Jutul.setup_storage(model;
                                  setup_linearized_system = false,
                                  setup_equations         = false,
                                  state0                  = state,
                                  parameters              = parameters,
                                  state_ad                = false)

    storage = convert_to_immutable_storage(storage)
    Jutul.update_secondary_variables!(storage, model)

    state = storage[:state]

    return state

end

model      = output[:extra][:model]
parameters = output[:extra][:parameters]

state = output[:states][1]

function computeR(state, amsymbol::Symbol, model::BattMo.BatteryModel, parameters)

    local crosstermpair
    
    for crosstermpair_ in model.cross_terms
        if crosstermpair_.source == amsymbol && crosstermpair_.target == :Elyte
            crosstermpair = crosstermpair_
            break
        end
    end

    crossterm = crosstermpair.cross_term

    amcells = crossterm.source_cells
    elcells = crossterm.target_cells
    
    state = getStateWithSecondaryVariables(model, state, parameters)
    
    R = []
    
    for (ind, (amcell, elcell)) in enumerate(zip(amcells, elcells))

        c_a   = state[:NeAm].Cs[amcell]
        R0    = state[:NeAm].ReactionRateConst[amcell]
        phi_a = state[:NeAm].Phi[amcell]
        ocp   = state[:NeAm].Ocp[amcell]
        T     = state[:NeAm].Temperature[amcell]
        c_e   = state[:Elyte].C[elcell]
        phi_e = state[:Elyte].Phi[elcell]
        phi_e = state[:Elyte].Phi[elcell]

        eta = phi_a - phi_e - ocp

        Rcell = BattMo.reaction_rate(eta,
                                     c_a,
                                     R0 ,
                                     T  ,
                                     c_e,
                                     model[:NeAm].system,
                                     model[:Elyte].system)

        push!(R, Rcell)
    end

    return R
    
end


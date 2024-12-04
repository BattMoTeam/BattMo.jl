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

for crosstermpair_ in model.cross_terms
    if crosstermpair_.source == :NeAm && crosstermpair_.target == :Elyte
        global crosstermpair = crosstermpair_
    end
end

crossterm = crosstermpair.cross_term

amcells = crossterm.source_cells
elcells = crossterm.target_cells

state = output[:states][1]

state = getStateWithSecondaryVariables(model, state, parameters)


c_a   = state[:NeAm].Cs[amcells[1]]
R0    = state[:NeAm].ReactionRateConst[amcells[1]]
phi_a = state[:NeAm].Phi[amcells[1]]
ocp   = state[:NeAm].Ocp[amcells[1]]
T     = state[:NeAm].Temperature[amcells[1]]
c_e   = state[:Elyte].C[elcells[1]]
phi_e = state[:Elyte].Phi[elcells[1]]
phi_e = state[:Elyte].Phi[elcells[1]]

eta = phi_a - phi_e - ocp

R = BattMo.reaction_rate(eta           ,
                         c_a           ,
                         R0            ,
                         T             ,
                         c_e           ,
                         model[:NeAm].system,
                         model[:Elyte].system)

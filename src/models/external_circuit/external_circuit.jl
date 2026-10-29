#######################################################################################################################
# External circuit model
#
# The external circuit model holds the cell voltage and current, the control equation that imposes the control of the
# current control step, and the controller that tracks the control steps (see controller.jl). This script defines the
# Jutul system, domain, variables and equations of the model, and all the Jutul hooks that involve the controller.
#######################################################################################################################

export
    ExternalCircuitSystem,
    ExternalCircuitDomain,
    VoltageVar,
    CurrentVar

#########################################################
# Define the variables in the external circuit model #
#########################################################

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

# The cell capacity (in Ah) is a parameter of the external circuit model. It is used for the control steps given as
# C-rates. As a parameter, its dependency on the cell parameters is kept when computing sensitivities (adjoints).

struct CellCapacity <: ScalarVariable end

# The capacity is not known for some setups (for example from Matlab input). C-rates cannot be used in that case.
Jutul.default_value(model, ::CellCapacity) = NaN

####################################################
# Define the external circuit system and domain #
####################################################

## In Jutul, a system is part of a model and contains data. The external circuit system holds the control protocol.

struct ExternalCircuitSystem{P <: ControlProtocol} <: JutulSystem

    protocol::P

end

struct ExternalCircuitDomain <: JutulDomain end

ExternalCircuitModel{P} = SimulationModel{ExternalCircuitDomain, ExternalCircuitSystem{P}}

Jutul.number_of_cells(::ExternalCircuitDomain) = 1

################################
# Select the primary variables #
################################

function Jutul.select_primary_variables!(S, system::ExternalCircuitSystem, model::SimulationModel)

    S[:ElectricPotential] = VoltageVar()
    return S[:Current] = CurrentVar()

end

########################
# Select the equations #
########################

function Jutul.select_equations!(eqs, system::ExternalCircuitSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    return eqs[:control] = ControlEquation()

end

#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(S, system::ExternalCircuitSystem, model::SimulationModel)

    return S[:Capacity] = CellCapacity()

end

"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(
        outputs,
        system::ExternalCircuitSystem{R},
        model::SimulationModel,
    ) where {R}

    return push!(outputs, :Controller)

end

#############################
# Assembly of the equations #
#############################

struct CurrentEquation <: JutulEquation end
Jutul.local_discretization(::CurrentEquation, i) = nothing

struct ControlEquation <: JutulEquation end
Jutul.local_discretization(::ControlEquation, i) = nothing

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::ControlEquation, model, dt, ldisc = local_discretization(eq, i))

    I = only(state.Current)

    phi = only(state.ElectricPotential)

    ctrl = state[:Controller]

    return if ctrl.target_is_voltage
        v[] = phi - ctrl.target
    elseif ctrl.target_is_c_rate
        # The target is a C-rate, which is converted to a current using the capacity parameter
        v[] = I - ctrl.target * only(state.Capacity)
    else
        v[] = I - ctrl.target
    end

end

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = local_discretization(eq, i))

    # Sign is strange here due to cross term?
    I = only(state.Current)
    phi = only(state.ElectricPotential)

    return v[] = I + phi * 1.0e-10


end

##################################
# Initial state and controller #
##################################

"""
Current at the start of the simulation, used to initialize the state
"""
function initial_current(model::ExternalCircuitModel)

    return initial_current(model.system.protocol)

end

"""
Function called when setting up state initially. We need to add the fields corresponding to the controller
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::ExternalCircuitModel; T = Float64)

    return state[:Controller] = initial_controller(model.system.protocol; T = T)

end

#####################################################
# Update of the controller during the simulation #
#####################################################

"""
In addition to update the values in all primary variables, we need also to update the values in the controller, see
step_switching.jl. This is called at each Newton iteration.
"""
function Jutul.update_extra_state_fields!(storage, model::SimulationModel{ExternalCircuitDomain, <:ExternalCircuitSystem}, dt, time)
    update_controller!(storage.state, storage.state0, model.system.protocol, dt)
    return storage
end

"""
Update after convergence. Here, we copy the controller to state0
"""
function Jutul.update_after_step!(storage, domain::ExternalCircuitDomain, model::ExternalCircuitModel, dt, forces; time = NaN)

    return copy_controller!(storage.state0[:Controller], storage.state[:Controller])

end

"""
When a time step is cut, the controller is reset together with the primary variables
"""
function Jutul.reset_state_to_previous_state!(storage, model::SimulationModel{ExternalCircuitDomain, <:ExternalCircuitSystem, T3, T4}) where {T3, T4}

    invoke(
        reset_state_to_previous_state!,
        Tuple{typeof(storage), SimulationModel},
        storage,
        model
    )

    return copy_controller!(storage.state[:Controller], storage.state0[:Controller])
end

"""
We limit the Newton updates of the current to a fraction of the maximum current of the protocol, to avoid
convergence problems at control switches.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::ExternalCircuitModel, dx, w)

    entity = associated_entity(p)
    active = active_entities(model.domain, entity, for_variables = true)
    v = state[state_symbol]

    maximum_current = model.system.protocol.maximum_current

    abs_max = maximum_current > 0 ? 0.2 * maximum_current : absolute_increment_limit(p)
    rel_max = relative_increment_limit(p)
    maxval = maximum_value(p)
    minval = minimum_value(p)
    scale = variable_scale(p)

    @inbounds for i in eachindex(active)
        a_i = active[i]
        v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
    end

    return v
end

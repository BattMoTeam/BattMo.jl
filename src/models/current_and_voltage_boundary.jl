export
    CurrentAndVoltageSystem,
    CurrentAndVoltageDomain,
    VoltageVar,
    CurrentVar,
    sineup

#############################################
# Define the variables in the control model #
#############################################

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

# The cell capacity (in Ah) is a parameter of the control model. It is used for the control steps given as C-rates. As a
# parameter, its dependency on the cell parameters is kept when computing sensitivities (adjoints).

struct CellCapacity <: ScalarVariable end

# The capacity is not known for some setups (for example from Matlab input). C-rates cannot be used in that case.
Jutul.default_value(model, ::CellCapacity) = NaN

##################################################
# Define the Current and voltage control systems #
##################################################

## In Jutul, a system is part of a model and contains data

## A policy is used to compute the next control from the current control and state. All cycling protocols are run by
## the GenericProtocol policy, see models/experiment/generic_protocol.jl

abstract type AbstractPolicy end

struct CurrentAndVoltageSystem{P <: AbstractPolicy} <: JutulSystem

    # Control policy
    policy::P

end

struct CurrentAndVoltageDomain <: JutulDomain end

CurrentAndVoltageModel{P} = SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{P}}

Jutul.number_of_cells(::CurrentAndVoltageDomain) = 1

################################
# Select the primary variables #
################################

function Jutul.select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    S[:ElectricPotential] = VoltageVar()
    return S[:Current] = CurrentVar()

end

########################
# Select the equations #
########################

function Jutul.select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    return eqs[:control] = ControlEquation()

end

#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    return S[:Capacity] = CellCapacity()

end

###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

## A controller provides the information to exert the current control. It is implemented as a mutable structure and
## attached to the state, see models/experiment/generic_controller.jl

abstract type Controller end

"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(
        outputs,
        system::CurrentAndVoltageSystem{R},
        model::SimulationModel,
    ) where {R}

    return push!(outputs, :Controller)

end


######################################################################################################
# Initial current given the policy, it is used at initialization of the state in the simulation #
######################################################################################################

function getInitCurrent(model::CurrentAndVoltageModel)

    return getInitCurrent(model.system.policy)

end


"""
In addition to update the values in all primary variables, we need also to update the values in the controller.
"""
function Jutul.update_extra_state_fields!(storage, model::SimulationModel{CurrentAndVoltageDomain, <:CurrentAndVoltageSystem}, dt, time)
    state = storage.state
    state0 = storage.state0
    policy = model.system.policy
    update_controller!(state, state0, policy, dt)
    return storage
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

#####################################################################
# Function to update the controller part in state after convergence #
#####################################################################

""" Update after convergence. Here, we copy the controller to state0
"""
function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)

    return copyController!(storage.state0[:Controller], storage.state[:Controller])

end

########################################################################
# Controller initialization function. Adds the controller to the state #
########################################################################

"""
Function called when setting up state initially. We need to add the fields corresponding to the controller
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel; T = Float64)

    return state[:Controller] = initial_controller(model.system.policy; T = T)

end

############################################
# Helper function to compute control value #
############################################

"""
sineup rampup function
"""
function sineup(y1, y2, x1, x2, x)
    #SINEUP Creates a sine ramp function
    #
    #   res = sineup(y1, y2, x1, x2, x) creates a sine ramp
    #   starting at value y1 at point x1 and ramping to value y2 at
    #   point x2 over the vector x.
    y1, y2, x1, x2, x = promote(y1, y2, x1, x2, x)
    T = typeof(x)

    dy = y1 - y2
    dx = abs(x1 - x2)

    res = zero(T)

    if (x >= x1) && (x <= x2)
        res = dy / 2.0 .* cos(pi .* (x - x1) ./ dx) + y1 - (dy / 2)
    end

    if (x > x2)
        res .+= y2
    end

    if (x < x1)
        res .+= y1
    end

    return res

end


function compute_state_of_charge(
        previous_state_of_charge::Real,
        dt::Real,
        rated_capacity::Real,
        current::Real;
        η_chg::Real = 1.0,
        η_dis::Real = 1.0
    )

    # Choose efficiency based on the sign convention: I>0 discharge, I<0 charge
    η = current >= 0 ? η_dis : η_chg

    # Coulomb counting update; 3600 converts Ah to As
    soc_next = previous_state_of_charge - (η * current * dt) / (3600.0 * rated_capacity)

    # Clamp to physical bounds
    return clamp(soc_next, 0.0, 1.0)
end

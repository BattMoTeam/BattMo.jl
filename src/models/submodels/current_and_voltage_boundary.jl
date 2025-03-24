export
    CurrentAndVoltageSystem,
    CurrentAndVoltageDomain,
    VoltageVar,
    CurrentVar,
    sineup,
    SimpleCVPolicy,
    CyclingCVPolicy,
    OperationalMode

################################
# Define the operational modes #
################################

@enum OperationalMode cc_discharge1 cc_discharge2 cc_charge1 cv_charge2 rest discharge charging discharging none

function getSymbol(ctrlType::OperationalMode)

    if ctrlType == cc_discharge1
        symb = :cc_discharge1
    elseif ctrlType == cc_discharge2
        symb = :cc_discharge2
    elseif ctrlType == cc_charge1
        symb = :cc_charge1
    elseif ctrlType == cv_charge2
        symb = :cv_charge2
    end

    return symb
   
end

#############################################
# Define the variables in the control model #
#############################################

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

# The following variable will be added as parameters. In this way, they can also be computed when the whole battery
# model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end

##################################################
# Define the Current and voltage control systems #
##################################################

## In Jutul, a system is part of a model and contains data

abstract type AbstractCVPolicy end

struct CurrentAndVoltageSystem{P<:AbstractCVPolicy} <: JutulSystem
    
    # Control policy
    policy::P
    
end

struct CurrentAndVoltageDomain <: JutulDomain end

CurrentAndVoltageModel{P} = SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{P}}

Jutul.number_of_cells(::CurrentAndVoltageDomain) = 1

####################################
# Types for the different policies #
####################################

## A policy is used to compute the next control from the current control and state

""" Simple constant current policy. Stops when lower cut-off value is reached
"""
mutable struct SimpleCVPolicy{R} <: AbstractCVPolicy
    current_function
    Imax::R
    voltage::R
    function SimpleCVPolicy(;current_function = missing, Imax::T = 0., voltage = missing) where T <: Real
        new{Union{Missing, T}}(current_function, Imax, voltage)
    end
end

""" No policy means that the control is kept fixed throughout the simulation
"""
struct NoPolicy <: AbstractCVPolicy end


""" Standard CC-CV policy
"""
mutable struct CyclingCVPolicy{R, I}  <: AbstractCVPolicy

    ImaxDischarge::R
    ImaxCharge::R
    lowerCutoffVoltage::R
    upperCutoffVoltage::R
    dIdtLimit::R
    dEdtLimit::R
    initialControl::OperationalMode
    numberOfCycles::I
    tolerances
    
end 

function CyclingCVPolicy(lowerCutoffVoltage,
                         upperCutoffVoltage,
                         dIdtLimit,
                         dEdtLimit,
                         initialControl::String,
                         numberOfCycles;
                         ImaxDischarge = 0*lowerCutoffVoltage,
                         ImaxCharge = 0*lowerCutoffVoltage,
                         )

    if initialControl == "charging"
        initialControl = charging
    elseif initialControl == "discharging"
        initialControl = discharging
    else
        error("initialControl not recognized")
    end

    tolerances = (cc_discharge1 = 1e-4,
                  cc_discharge2 = 0.9,
                  cc_charge1    = 1e-4,
                  cv_charge2    = 0.9)
    
    return CyclingCVPolicy(ImaxDischarge,
                           ImaxCharge,
                           lowerCutoffVoltage,
                           upperCutoffVoltage,
                           dIdtLimit,
                           dEdtLimit,
                           initialControl,
                           numberOfCycles,
                           tolerances)
end

################################
# Select the primary variables #
################################

function Jutul.select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    S[:Phi]     = VoltageVar()
    S[:Current] = CurrentVar()
    
end

########################
# Select the equations #
########################

function Jutul.select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    eqs[:control] = ControlEquation()
    
end

#########################
# Select the parameters #
#########################

function Jutul.select_parameters!(S,
                            system::CurrentAndVoltageSystem{SimpleCVPolicy{R}},
                            model::SimulationModel) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
end

function Jutul.select_parameters!(S,
                            system::CurrentAndVoltageSystem{CyclingCVPolicy{R, I}},
                            model::SimulationModel) where {R, I}
    S[:ImaxDischarge] = ImaxDischarge()
    S[:ImaxCharge]    = ImaxCharge()
end


###########################################################################################################
# Definition of the controller and some basic utility functions. The controller will be part of the state #
###########################################################################################################

## A controller provides the information to exert the current control

## The controller are implemented as mutable structures and will be attached to the state

abstract type ControllerCV end

## SimpleControllerCV

mutable struct SimpleControllerCV{R} <: ControllerCV

    target::R
    time::R
    target_is_voltage::Bool
    ctrlType::OperationalMode
    
end

SimpleControllerCV() = SimpleControllerCV(0., 0., true, none)

## CcCvControllerCV

mutable struct CcCvControllerCV{R, I<:Integer} <: ControllerCV

    maincontroller::SimpleControllerCV{R}
    numberOfCycles::I
    dEdt::Union{R, Missing}
    dIdt::Union{R, Missing}
    
end

function CcCvControllerCV()

    maincontroller = SimpleControllerCV()

    return CcCvControllerCV(maincontroller, 0, missing, missing)
    
end


## Helper for CcCvControllerCV so that the fields of SimpleControllerCV appears as inherrited.

function Base.getproperty(c::CcCvControllerCV, f::Symbol)
    if f in fieldnames(SimpleControllerCV)
        return getfield(c.maincontroller, f)
    else
        return getfield(c, f)
    end
end

function Base.setproperty!(c::CcCvControllerCV, f::Symbol, v)
    if f in fieldnames(SimpleControllerCV)
        setfield!(c.maincontroller, f, v)
    else
        setfield!(c, f, v)
    end
end


@inline function Jutul.numerical_type(x::SimpleControllerCV{R}) where {R}
    return R
end

@inline function Jutul.numerical_type(x::CcCvControllerCV{R, I}) where {R, I}
    return R
end

"""
Function to create (deep) copy of simple controller
"""
function copyController!(cv_copy::SimpleControllerCV, cv::SimpleControllerCV)

    cv_copy.target            = cv.target
    cv_copy.time              = cv.time
    cv_copy.target_is_voltage = cv.target_is_voltage
    cv_copy.ctrlType          = cv.ctrlType
    
end

"""
Function to create (deep) copy of CC-CV controller
"""
function copyController!(cv_copy::CcCvControllerCV, cv::CcCvControllerCV)

    copyController!(cv_copy.maincontroller, cv.maincontroller)
    cv_copy.numberOfCycles = cv.numberOfCycles
    
end

"""
Overload function to copy simple controller
"""
function Base.copy(cv::SimpleControllerCV)

    cv_copy = SimpleControllerCV()
    copyController!(cv_copy, cv)
    
    return cv_copy

end

"""
Overload function to copy CC-CV controller
"""
function Base.copy(cv::CcCvControllerCV)

    cv_copy = CcCvControllerCV()
    copyController!(cv_copy, cv)

    return cv_copy
    
end

"""
We add the controller in the output
"""
function Jutul.select_minimum_output_variables!(outputs,
                                          system::CurrentAndVoltageSystem{R},
                                          model::SimulationModel
                                          ) where {R}

    push!(outputs, :ControllerCV)
    
end


###################################################################################################################
# Functions to compute initial current given the policy, it used at initialization of the state in the simulation #
###################################################################################################################

function getInitCurrent(policy::SimpleCVPolicy)
    if !ismissing(policy.current_function)
        val = policy.current_function(0.)
    else
        val = policy.Imax
    end
    return val
end


function getInitCurrent(policy::CyclingCVPolicy)
    
    if policy.initialControl == charging
        return -policy.ImaxCharge
    elseif policy.initialControl == discharging
        return policy.ImaxDischarge
    else
        error("initial control not recognized")
    end
    
end

function getInitCurrent(model::CurrentAndVoltageModel)

    return getInitCurrent(model.system.policy)

end



######################################################
# Setup the initial policy from the input parameters #
######################################################

function setup_initial_control_policy!(policy::SimpleCVPolicy, inputparams::ParameterSet, parameters)

    Imax = only(parameters[:Control][:ImaxDischarge])

    tup = Float64(inputparams["Control"]["rampupTime"])
    
    cFun(time) = currentFun(time, Imax, tup)

    policy.current_function = cFun
    policy.Imax             = Imax
    policy.voltage          = inputparams["Control"]["lowerCutoffVoltage"]
    
end

 
function setup_initial_control_policy!(policy::CyclingCVPolicy, inputparams::ParameterSet, parameters)

    policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
    policy.ImaxCharge    = only(parameters[:Control][:ImaxCharge])

end

###################################
# Special primary variable update #
###################################

"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {R, I, Q <: CyclingCVPolicy{R, I}, P <: CurrentAndVoltageModel{Q}}

    entity = associated_entity(p)
    active = active_entities(model.domain, entity, for_variables = true)
    v = state[state_symbol]

    nu = length(active)
    ImaxDischarge = model.system.policy.ImaxDischarge
    ImaxCharge    = model.system.policy.ImaxCharge

    Imax = max(ImaxCharge, ImaxDischarge)

    abs_max = 0.2*Imax
    rel_max = relative_increment_limit(p)
    maxval = maximum_value(p)
    minval = minimum_value(p)
    scale = Jutul.variable_scale(p)
    @inbounds for i in 1:nu
        a_i = active[i]
        v[a_i] = Jutul.update_value(v[a_i], w*dx[i], abs_max, rel_max, minval, maxval, scale)
    end
    
end

#######################################
# Helper functions for control switch #
#######################################

"""
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::CyclingCVPolicy, state, ctrlType)

    Emin    = policy.lowerCutoffVoltage
    Emax    = policy.upperCutoffVoltage
    dIdtMin = policy.dIdtLimit
    dEdtMin = policy.dEdtLimit
    tols    = policy.tolerances
            
    E = only(state.Phi)
    I = only(state.Current)

    tol = tols[getSymbol(ctrlType)]
    
    if ctrlType ==  cc_discharge1

        before = E > Emin*(1 + tol)
        after  = E < Emin*(1 - tol)
        
    elseif ctrlType == cc_discharge2

        dEdt = state.ControllerCV.dEdt
        if !ismissing(dEdt)
            before = abs(dEdt) > dEdtMin*(1 + tol)
            after  = abs(dEdt) < dEdtMin*(1 - tol)
        else
            before = false
            after  = false
        end
        
    elseif ctrlType == cc_charge1
        
        before = E < Emax*(1 - tol)
        after  = E > Emax*(1 + tol)

    elseif ctrlType == cv_charge2

        dIdt = state.ControllerCV.dIdt
        if !ismissing(dIdt)
            before = abs(dIdt) > dIdtMin*(1 + tol)
            after  = abs(dIdt) < dIdtMin*(1 - tol)
        else
            before = false
            after  = false
        end
        
    else

        error("control type not recognized")

    end

    return (beforeSwitchRegion = before, afterSwitchRegion = after)

end

"""
When a step has been computed for a given control up to the convergence requirement, it may happen that the state that is obtained do not fulfill the requirement of the control, meaning that a control switch should have been triggered. The function check_constraints checks that and return false in this case and update the control. The step is then not completed and carries on with the new control
"""
function check_constraints(model, storage)

    policy = model[:Control].system.policy
    
    state  = storage.state[:Control]
    state0 = storage.state0[:Control]

    controller = state[:ControllerCV]
    ctrlType   = state[:ControllerCV].ctrlType
    ctrlType0  = state0[:ControllerCV].ctrlType
    
    nextCtrlType = getNextCtrlType(ctrlType0)

    arefulfilled = true
    
    rsw  = setupRegionSwitchFlags(policy, state, ctrlType)
    rswN = setupRegionSwitchFlags(policy, state, nextCtrlType)
    
    if (ctrlType == ctrlType0 && rsw.afterSwitchRegion) || (ctrlType == nextCtrlType && !rswN.beforeSwitchRegion)

        arefulfilled = false
        
    end

    return arefulfilled
    
end

################################################
# Functions to update values in the controller #
################################################

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)

    copyController!(old, new)
    
end

function Jutul.update_values!(old::CcCvControllerCV, new::CcCvControllerCV)

    copyController!(old, new)
    
end

"""
In addition to update the values in all primary variables, we need also to update the values in the controller. We do that by specializing the method perform_step_solve_impl!
"""
function Jutul.perform_step_solve_impl!(report, storage, model::MultiModel{:Battery,T}, config, dt, iteration, rec, relaxation, executor) where {T}

    invoke(Jutul.perform_step_solve_impl!,
           Tuple{typeof(report),
                 typeof(storage),
                 MultiModel,
                 typeof(config),
                 typeof(dt),
                 typeof(iteration),
                 typeof(rec),
                 typeof(relaxation),
                 typeof(executor)},
           report, storage, model, config, dt, iteration, rec, relaxation, executor)

    state  = storage.state[:Control]
    state0 = storage.state0[:Control]
    policy = model[:Control].system.policy

    update_controller!(state, state0, policy, dt)

end

"""
We need to add the specific treatment of the controller variables
"""
function Jutul.reset_state_to_previous_state!(storage, model::Jutul.SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{CyclingCVPolicy{T1, T2}}, T3, T4}) where {T1, T2, T3, T4}

    invoke(Jutul.reset_state_to_previous_state!,
           Tuple{typeof(storage),
                 Jutul.SimulationModel},
           storage,
           model)
    copyController!(storage.state[:ControllerCV], storage.state0[:ControllerCV])
end


function update_controller!(state, state0, policy::AbstractCVPolicy, dt)
    
    update_control_type_in_controller!(state, state0, policy, dt)
    update_values_in_controller!(state, policy)
    
end


##################################
# Implementation of the policies #
##################################

# Given a policy, a current control and state, we compute the next control

"""
Implementation of the simple CV policy
"""
function update_control_type_in_controller!(state, state0, policy::SimpleCVPolicy, dt)

    phi_p = policy.voltage
    
    controller = state.ControllerCV
    
    phi = only(state.Phi)
    
    target_is_voltage = (phi <= phi_p)

    controller.target_is_voltage = target_is_voltage
    controller.ctrlType          = discharge # for the moment only discharge in a simple controller
    controller.time              = state0.ControllerCV.time + dt
    
end

"""
Implementation of the cycling CC-CV policy
"""
function update_control_type_in_controller!(state, state0, policy::CyclingCVPolicy, dt)

    E  = only(value(state[:Phi]))
    I  = only(value(state[:Current]))
    E0 = only(value(state0[:Phi]))
    I0 = only(value(state0[:Current]))

    controller = state.ControllerCV

    controller.time = state0.ControllerCV.time + dt
    controller.dIdt = (I - I0)/dt
    controller.dEdt = (E - E0)/dt

    ctrlType0 = state0.ControllerCV.ctrlType
    
    nextCtrlType = getNextCtrlType(ctrlType0)

    rsw00 = setupRegionSwitchFlags(policy, state0, ctrlType0)

    if rsw00.beforeSwitchRegion

        # We have not entered the switching region in the time step. We are not going to change control
        # in this step.
        ctrlType = ctrlType0

    else
        
        # We entered the switch region in the previous time step. We consider switching control
                
        currentCtrlType = state.ControllerCV.ctrlType # current control in the the Newton iteration
        nextCtrlType0   = getNextCtrlType(ctrlType0) # next control that can occur after the previous time step control (if it changes)

        rsw0 = setupRegionSwitchFlags(policy, state, ctrlType0)
                
        if currentCtrlType == ctrlType0

            # The control has not changed from previous time step and we want to determine if we should change it. 

            if rsw0.afterSwitchRegion

                # We switch to a new control because we are no longer in the acceptable region for the current
                # control
                ctrlType = nextCtrlType0
                
            else

                ctrlType = ctrlType0

            end

        elseif currentCtrlType == nextCtrlType0

            # We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
            # control so that we keep the control as it is.

            ctrlType = nextCtrlType0

        else

            error("control type not recognized")

        end

    end
    
    controller.ctrlType = ctrlType
    
end

#############################################################
# Functions to update the values in the controller in state #
#############################################################

# Once the controller has been assigned the given control, we adjust the target value which is used in the equation
# assembly

function update_values_in_controller!(state, policy::SimpleCVPolicy)
    
    controller = state.ControllerCV
    
    if controller.target_is_voltage
        
        phi_p = policy.voltage
        
        controller.target = phi_p
        
    else
        
        cf = policy.current_function
        
        if cf isa Real
            I_p = cf
        else
            # Function of time at the end of interval
            I_p = cf(controller.time)
        end
        
        controller.target = I_p
        
    end

end

function update_values_in_controller!(state,  policy::CyclingCVPolicy)

    controller  = state[:ControllerCV]
    
    ctrlType = controller.ctrlType
    
    if ctrlType == cc_discharge1

        I_t = policy.ImaxDischarge
        target_is_voltage = false
        
    elseif ctrlType == cc_discharge2
        
        I_t = 0.
        target_is_voltage = false
        
    elseif ctrlType == cc_charge1

        # minus sign below follows from convention
        I_t = -policy.ImaxCharge
        target_is_voltage = false
        
    elseif ctrlType == cv_charge2
        
        V_t = policy.upperCutoffVoltage
        target_is_voltage = true
        
    else
        
        error("ctrlType $ctrlType not recognized")
        
    end
    
    if target_is_voltage
        target = V_t
    else
        target = I_t
    end

    controller.target_is_voltage = target_is_voltage
    controller.target            = target
    
end

#############################
# Assembly of the equations #
#############################

struct CurrentEquation <: JutulEquation end
Jutul.local_discretization(::CurrentEquation, i) = nothing

struct ControlEquation <: JutulEquation end
Jutul.local_discretization(::ControlEquation, i) = nothing

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::ControlEquation, model, dt, ldisc = Jutul.local_discretization(eq, i))
    
    I    = only(state.Current)
    phi  = only(state.Phi)
    
    ctrl = state[:ControllerCV]
    
    if ctrl.target_is_voltage
        v[] = phi - ctrl.target
    else
        v[] = I - ctrl.target
    end
    
end

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = Jutul.local_discretization(eq, i))

    # Sign is strange here due to cross term?
    I   = only(state.Current)
    phi = only(state.Phi)
    
    v[] = I + phi*1e-10
    
end

#####################################################################
# Function to update the controller part in state after convergence #
#####################################################################

""" Update after convergence. Here, we copy the controller to state0 and count the total number of cycles in case of CyclingCVPolicy
"""
function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)
    
    ctrl  = storage.state[:ControllerCV]
    
    policy = model.system.policy

    if policy isa CyclingCVPolicy

        initctrl = policy.initialControl

        ctrlType = ctrl.ctrlType
        
        ctrlType0 = storage.state0[:ControllerCV].ctrlType
        ncycles   = storage.state0[:ControllerCV].numberOfCycles
        
        copyController!(storage.state0[:ControllerCV], ctrl)
        
        if initctrl == charging
            
            if (ctrlType0 == cc_discharge1 || ctrlType0 == cc_discharge2) && (ctrlType == cc_charge1 || ctrlType == cv_charge2)
                ncycles = ncycles + 1
            end
            
        elseif initctrl == discharging
            
            if (ctrlType0 == cc_charge1 || ctrlType0 == cv_charge2) && (ctrlType == cc_discharge1 || ctrlType == cc_discharge2) 
                ncycles = ncycles + 1
            end
            
        end

        ctrl.numberOfCycles = ncycles
        
    elseif policy isa SimpleCVPolicy
        
        copyController!(storage.state0[:ControllerCV], ctrl)

    else

        error("policy not recognized")
        
    end

    
end

########################################################################
# Controller initialization function. Adds the controller to the state #
########################################################################

"""
Function called when setting up state initially. We need to add the fields corresponding to the controller
"""
function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel)

    policy = model.system.policy

    if policy isa SimpleCVPolicy

        time = 0.0
        Imax = policy.Imax
        if !ismissing(policy.current_function)
            target = policy.current_function(time)
        else
            target = Imax
        end
        target_is_voltage = false
        ctrlType          = discharging
        state[:ControllerCV] = SimpleControllerCV(target, time, target_is_voltage, ctrlType)
        
    elseif policy isa CyclingCVPolicy
        
        state[:ControllerCV] = CcCvControllerCV()
        
        if policy.initialControl == discharging
            
            state[:ControllerCV].ctrlType = cc_discharge1

        elseif policy.initialControl == charging
            
            state[:ControllerCV].ctrlType = cc_charge1
            
        else
            error("initialControl not recognized")
        end

        update_values_in_controller!(state, policy)
        
    end
    
end

#######################################
# Utility functions for CC-CV control #
#######################################

function getNextCtrlType(ctrlType::OperationalMode)

    if ctrlType == cc_discharge1

        nextCtrlType = cc_discharge2;
        
    elseif ctrlType == cc_discharge2
        
        nextCtrlType = cc_charge1;

    elseif ctrlType == cc_charge1
        
        nextCtrlType = cv_charge2;

    elseif ctrlType == cv_charge2
        
        nextCtrlType = cc_discharge1;

    else

        error("ctrlType not recognized.")
        
    end

    return nextCtrlType

end

############################################
# Helper function to compute control value #
############################################

"""
sineup rampup function
"""
function sineup(y1::T, y2::T, x1::T, x2::T, x::T) where {T<:Any}
    #SINEUP Creates a sine ramp function
    #
    #   res = sineup(y1, y2, x1, x2, x) creates a sine ramp
    #   starting at value y1 at point x1 and ramping to value y2 at
    #   point x2 over the vector x.
    
    dy = y1 - y2; 
    dx = abs(x1 - x2);
    
    res::T = 0.0
    
    if  (x >= x1) && (x <= x2)
        res = dy/2.0.*cos(pi.*(x - x1)./dx) + y1 - (dy/2) 
    end
    
    if (x > x2)
        res .+= y2
    end

    if (x < x1)
        res .+= y1
    end
    
    return res
    
end

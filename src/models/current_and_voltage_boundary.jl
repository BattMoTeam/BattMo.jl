export
    CurrentAndVoltageSystem,
    CurrentAndVoltageDomain,
    VoltageVar,
    CurrentVar,
    sineup,
    SimpleCVPolicy,
    CyclingCVPolicy,
    getInitCurrent

@enum OperationalMode cc_discharge1 cc_discharge2 cc_charge1 cv_charge2 rest discharge charging discharging none

struct VoltageVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

abstract type AbstractCVPolicy end

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

struct CurrentAndVoltageSystem{P<:AbstractCVPolicy} <: JutulSystem
    
    # Control policy
    policy::P
    
end

struct CurrentAndVoltageDomain <: JutulDomain end

CurrentAndVoltageModel{P} = SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{P}}

number_of_cells(::CurrentAndVoltageDomain) = 1


## Definition of the policy types

mutable struct SimpleCVPolicy{R} <: AbstractCVPolicy
    current_function
    Imax::R
    voltage::R
    function SimpleCVPolicy(;current_function = missing, Imax = 1.0, voltage::T = 2.5) where T<:Real
        new{T}(current_function, Imax, voltage)
    end
end


struct NoPolicy <: AbstractCVPolicy end

mutable struct CyclingCVPolicy{R,I}  <: AbstractCVPolicy

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

    tolerances = (cc_discharge1 = 1e-3,
                  cc_discharge2 = 0.9,
                  cc_charge1    = 1e-3,
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


function getInitCurrent(policy::SimpleCVPolicy)
    return policy.Imax
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

## We add as parameters those that can only by computed when the whole battery model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end

function select_minimum_output_variables!(outputs,
                                          system::CurrentAndVoltageSystem{R},
                                          model::SimulationModel
                                          ) where {R}

    push!(outputs, :ControllerCV)
    
end


function select_parameters!(S,
                            system::CurrentAndVoltageSystem{SimpleCVPolicy{R}},
                            model::SimulationModel) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
end

function select_parameters!(S,
                            system::CurrentAndVoltageSystem{CyclingCVPolicy{R, I}},
                            model::SimulationModel) where {R, I}
    S[:ImaxDischarge] = ImaxDischarge()
    S[:ImaxCharge]    = ImaxCharge()
end


## Setup policy

function setup_policy!(policy::SimpleCVPolicy, init::JSONFile, parameters)

    Imax = only(parameters[:Control][:ImaxDischarge])

    tup = Float64(init.object["Control"]["rampupTime"])
    
    cFun(time) = currentFun(time, Imax, tup)

    policy.current_function = cFun
    policy.Imax = Imax
    
end

 
function setup_policy!(policy::CyclingCVPolicy, init::JSONFile, parameters)

    policy.ImaxDischarge = only(parameters[:Control][:ImaxDischarge])
    policy.ImaxCharge    = only(parameters[:Control][:ImaxCharge])

end


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

        before = (E - Emin)/Emin > tol
        after  = (E - Emin)/Emin < -tol
        
    elseif ctrlType == cc_discharge2

        dEdt = state.ControllerCV.dEdt
        if !ismissing(dEdt)
            before = (abs(dEdt) - dEdtMin)/dEdtMin > tol
            after  = (abs(dEdt) - dEdtMin)/dEdtMin < -tol
        else
            before = false
            after  = false
        end
        
    elseif ctrlType == cc_charge1
        
        before = (E - Emax)/Emax < -tol
        after  = (E - Emax)/Emax > tol

    elseif ctrlType == cv_charge2

        dIdt = state.ControllerCV.dIdt
        if !ismissing(dIdt)
            before = (abs(dIdt) - dIdtMin)/dIdtMin > tol
            after  = (abs(dIdt) - dIdtMin)/dIdtMin < -tol
        else
            before = false
            after  = false
        end
        
    else

        error("control type not recognized")

    end

    return (beforeSwitchRegion = before, afterSwitchRegion = after)

end



## Definition of the controller which are attached to the state. They contain the variables necessary to compute the
## control from the policy for a given state

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


# helper for CcCvControllerCV so that the fields of SimpleControllerCV appears as inherrited.

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


function Base.copy(cv::SimpleControllerCV)

    cv_copy = SimpleControllerCV()
    copyController!(cv_copy, cv)
    
    return cv_copy

end

function Base.copy(cv::CcCvControllerCV)

    cv_copy = CcCvControllerCV()
    copyController!(cv_copy, cv)

    return cv_copy
    
end


function copyController!(cv_copy::SimpleControllerCV, cv::SimpleControllerCV)

    cv_copy.target            = cv.target
    cv_copy.time              = cv.time
    cv_copy.target_is_voltage = cv.target_is_voltage
    cv_copy.ctrlType          = cv.ctrlType
    
end

function copyController!(cv_copy::CcCvControllerCV, cv::CcCvControllerCV)

    copyController!(cv_copy.maincontroller, cv.maincontroller)
    cv_copy.numberOfCycles = cv.numberOfCycles
    
end


function check_constraints(model, storage)

    policy = model[:Control].system.policy
    
    state  = storage.state[:Control]
    state0 = storage.state0[:Control]

    controller = state[:ControllerCV]
    ctrlType   = state[:ControllerCV].ctrlType;
    ctrlType0  = state0[:ControllerCV].ctrlType;
    
    nextCtrlType = getNextCtrlType(ctrlType0);

    arefulfilled = true;
    
    rsw = setupRegionSwitchFlags(policy, state, ctrlType);

    if ctrlType == ctrlType0 && rsw.afterSwitchRegion
        
        arefulfilled = false;
        controller.ctrlType = nextCtrlType;
        update_values_in_controller!(state, policy)
        
    end

    return arefulfilled
    
end

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)

    copyController!(old, new)
    
end

function Jutul.update_values!(old::CcCvControllerCV, new::CcCvControllerCV)

    copyController!(old, new)
    
end


function Jutul.perform_step_solve_impl!(report, storage, model::MultiModel{T, :Battery}, config, dt, iteration, rec, relaxation, executor) where {T}

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
    model  = model[:Control]
    policy = model.system.policy

    update_controller!(state, state0, policy, dt)

end


function update_controller!(state, state0, policy::AbstractCVPolicy, dt)
    
    update_control_type_in_controller!(state, state0, policy, dt)
    update_values_in_controller!(state, policy)
    
end


function update_control_type_in_controller!(state, state0, policy::SimpleCVPolicy, dt)

    phi_p = policy.voltage
    
    controller = state.ControllerCV
    
    phi = only(state.Phi)
    
    target_is_voltage = (phi <= phi_p)

    controller.target_is_voltage = target_is_voltage
    controller.ctrlType          = discharge # for the moment only discharge in a simple controller
    controller.time              = state0.ControllerCV.time + dt
    
end

function update_values_in_controller!(state, policy::SimpleCVPolicy)
    
    controller  = state.ControllerCV
    
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



function update_control_type_in_controller!(state, state0, policy::CyclingCVPolicy, dt)

    E  = only(value(state[:Phi]))
    I  = only(value(state[:Current]))
    E0 = only(value(state0[:Phi]))
    I0 = only(value(state0[:Current]))

    controller = state.ControllerCV

    controller.time = state0.ControllerCV.time + dt
    controller.dIdt = (I - I0)/dt
    controller.dEdt = (E - E0)/dt

    ctrlType  = state.ControllerCV.ctrlType
    ctrlType0 = state0.ControllerCV.ctrlType
    
    nextCtrlType = getNextCtrlType(ctrlType0)

    rsw  = setupRegionSwitchFlags(policy, state, ctrlType0);
    rsw0 = setupRegionSwitchFlags(policy, state0, ctrlType0);
            
    if ctrlType == ctrlType && rsw.afterSwitchRegion && !rsw0.beforeSwitchRegion
                
        controller.ctrlType = nextCtrlType;

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



## Equations

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

function select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    eqs[:control] = ControlEquation()
    
end

function select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    S[:Phi]     = VoltageVar()
    S[:Current] = CurrentVar()
    
end

function Jutul.reset_state_to_previous_state!(storage, model::Jutul.SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{CyclingCVPolicy{T1, T2}}, T3, T4}) where {T1, T2, T3, T4}

    invoke(Jutul.reset_state_to_previous_state!,
           Tuple{typeof(storage),
                 Jutul.SimulationModel},
           storage,
           model)
    copyController!(storage.state[:ControllerCV], storage.state0[:ControllerCV])
end



function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)
    
    ctrl  = storage.state[:ControllerCV]
    
    policy = model.system.policy

    if policy isa CyclingCVPolicy

        initctrl = policy.initialControl

        ctrlType = ctrl.ctrlType
        
        ctrlType0   = storage.state0[:ControllerCV].ctrlType
        ncycles = storage.state0[:ControllerCV].numberOfCycles
        
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

function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel)

    policy = model.system.policy

    if policy isa SimpleCVPolicy

        
        target            = model.system.policy.Imax
        time              = 0.0
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

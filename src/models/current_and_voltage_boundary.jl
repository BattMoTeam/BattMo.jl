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

    return CyclingCVPolicy(ImaxDischarge,
                           ImaxCharge,
                           lowerCutoffVoltage,
                           upperCutoffVoltage,
                           dIdtLimit,
                           dEdtLimit,
                           initialControl,
                           numberOfCycles)
end


function getInitCurrent(policy::SimpleCVPolicy)
    return policy.Imax
end

function getInitCurrent(policy::CyclingCVPolicy)
    
    if policy.initialControl == charging
        return policy.ImaxCharge
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


## Policy to control functions

function policy_to_control(p::SimpleCVPolicy, state, state0, model)
    
    cf = p.current_function
    ctrl = state.ControllerCV

    if cf isa Real
        I_p = cf
    else
        # Function of time at the end of interval
        I_p = cf(ctrl.time)
    end
    
    phi_p = p.voltage
    phi   = only(state.Phi)
    
    is_voltage_ctrl = (phi <= phi_p)
    
    if is_voltage_ctrl
        target = phi_p
    else
        target = I_p
    end
    
    return (target, is_voltage_ctrl, discharge)
    
end

function policy_to_control(::NoPolicy, state, state0, model)
    
    return (2.0, true, rest)
    
end

function policy_to_control(policy::CyclingCVPolicy, state, state0, model)

    dEdtMin  = policy.dEdtLimit
    dIdtMin  = policy.dIdtLimit
    
    E = only(state.Phi)
    I = only(state.Current)

    dt   = state.ControllerCV.time - state0.ControllerCV.time
    dEdt = only((state[:Phi] - state0[:Phi])/dt)
    dIdt = only((state[:Current] - state0[:Current])/dt)
    
    mode  = state.ControllerCV.mode
    
    if mode == cc_discharge1
        
        if E < policy.lowerCutoffVoltage
            mode = cc_discharge2
        end

    elseif mode == cc_discharge2

        if (abs(dEdt) <= dEdtMin)
            mode = cc_charge1
        end
        

    elseif mode == cc_charge1
        
        if E > policy.upperCutoffVoltage
            mode = cv_charge2
        end
        
    elseif mode == cv_charge2
        
        if (abs(dIdt) < dIdtMin)
            mode = cc_discharge1
        end
                
    end
    
    if mode == cc_discharge1

        I_t = policy.ImaxDischarge
        is_voltage_ctrl = false
        
    elseif mode == cc_discharge2
        
        I_t = 0.
        is_voltage_ctrl = false
        
    elseif mode == cc_charge1

        # minus sign below follows from convention
        I_t = -policy.ImaxCharge
        is_voltage_ctrl = false
        
    elseif mode == cv_charge2
        
        V_t = policy.upperCutoffVoltage
        is_voltage_ctrl = true
        
    else
        
        error("mode $mode not recognized")
        
    end
    
    if is_voltage_ctrl
        target = V_t
    else
        target = I_t
    end
    
    return (target, is_voltage_ctrl, mode)
    
end

## Definition of the controller which are attached to the state. They contain the variables necessary to compute the
## control from the policy for a given state

abstract type ControllerCV end

## SimpleControllerCV

mutable struct SimpleControllerCV{R} <: ControllerCV

    target::R
    time::R
    target_is_voltage::Bool
    mode::OperationalMode
    
end

SimpleControllerCV() = SimpleControllerCV(0., 0., true, none)

## CcCvControllerCV

mutable struct CcCvControllerCV{R, I<:Integer} <: ControllerCV

    maincontroller::SimpleControllerCV{R}
    numberOfCycles::I
    
end

function CcCvControllerCV()

    maincontroller = SimpleControllerCV()

    return CcCvControllerCV(maincontroller, 0)
    
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
    cv_copy.mode              = cv.mode
    
end

function copyController!(cv_copy::CcCvControllerCV, cv::CcCvControllerCV)

    copyController!(cv_copy.maincontroller, cv.maincontroller)
    cv_copy.numberOfCycles = cv.numberOfCycles
    
end


function check_constraints(model, storage)

    converged = true
    
    policy = model[:Control].system.policy

    state = storage.state
    
    E    = only(state[:Control][:Phi])
    I    = only(state[:Control][:Current])
    ctrl = state[:Control][:ControllerCV]
    
    Emin     = policy.lowerCutoffVoltage
    Emax     = policy.upperCutoffVoltage
    dEdtMin  = policy.dEdtLimit
    dIdtMin  = policy.dIdtLimit
    
    mode = ctrl.mode
    
    # Check if the constraints are fullfilled for the given mode
    arefulfilled = true

    if mode == cc_discharge1
        if E <= Emin
            arefulfilled = false
            mode = cc_discharge2
        end
    elseif mode == cc_discharge2
        # do not check anything in this case
    elseif mode == cc_charge1
        if E > Emax
            arefulfilled = false;
            mode = cv_charge2
        end
    elseif mode == cv_charge2
        if I < -policy.ImaxCharge
            arefulfilled = false;
            mode = cc_charge1
        end
    else
        error("mode $mode not recognized")
    end            

    if !arefulfilled
        converged = false
        ctrl.mode = mode
    end

    return converged
end

function Jutul.update_values!(old::SimpleControllerCV, new::SimpleControllerCV)
    
    old.target            = new.target
    old.time              = new.time
    old.target_is_voltage = new.target_is_voltage
    old.mode              = new.mode
    
end

function Jutul.update_values!(old::CcCvControllerCV, new::CcCvControllerCV)

    Jutul.update_values!(old.maincontroller, new.maincontroller)

    old.numberOfCycles = new.numberOfCycles
    
end

function select_control_cv!(state, state0, model, dt)

    policy = model.system.policy

    target, target_is_voltage, mode = policy_to_control(policy, state, state0, model)

    cv = state.ControllerCV
    
    cv.target            = target
    cv.target_is_voltage = target_is_voltage
    cv.mode              = mode
    cv.time              = state0.ControllerCV.time + dt

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

        mode = ctrl.mode
        
        mode0   = storage.state0[:ControllerCV].mode
        ncycles = storage.state0[:ControllerCV].numberOfCycles
        
        copyController!(storage.state0[:ControllerCV], ctrl)
        
        if initctrl == charging
            if (mode0 == cc_discharge1 || mode0 == cc_discharge2) && (mode == cc_charge1 || mode == cv_charge2)
                ncycles = ncycles + 1
            end
        elseif initctrl == discharging
            if (mode0 == cc_charge1 || mode0 == cv_charge2) && (mode == cc_discharge1 || mode == cc_discharge2) 
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

        state[:ControllerCV] = SimpleControllerCV()
        
    elseif policy isa CyclingCVPolicy
        
        state[:ControllerCV] = CcCvControllerCV()
        
        if policy.initialControl == discharging
            state[:ControllerCV].mode = cc_discharge1
        elseif policy.initialControl == charging
            state[:ControllerCV].mode = cc_charge1
        else
            error("initialControl not recognized")
        end
        
    end
end

function Jutul.prepare_equation_in_entity!(i, eq::ControlEquation, eq_s, state, state0, model::CurrentAndVoltageModel, dt)
    
    select_control_cv!(state, state0, model, dt)
    
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

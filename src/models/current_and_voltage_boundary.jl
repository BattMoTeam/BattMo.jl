export CurrentAndVoltageSystem, CurrentAndVoltageDomain, CurrentForce, VoltageForce
export VoltageVar, CurrentVar, sineup
export SimpleCVPolicy, CyclingCVPolicy

@enum OperationalMode cc_discharge1 cc_discharge2 cc_charge1 cv_charge2 rest discharge charging discharging none

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
    voltage::R
    function SimpleCVPolicy(current, voltage::T = 2.5) where T<:Real
        new{T}(current, voltage)
    end
end

struct NoPolicy <: AbstractCVPolicy end

mutable struct CyclingCVPolicy{R}  <: AbstractCVPolicy

    ImaxDischarge::R
    ImaxCharge::R
    lowerCutoffVoltage::R
    upperCutoffVoltage::R
    dIdtLimit::R
    dEdtLimit::R
    initialControl::OperationalMode
    
end 

function CyclingCVPolicy(lowerCutoffVoltage,
                         upperCutoffVoltage,
                         dIdtLimit,
                         dEdtLimit,
                         initialControl::String;
                         ImaxDischarge = 0*lowerCutoffVoltage,
                         ImaxCharge = 0*lowerCutoffVoltage
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
                           initialControl)
end

## We add as parameters those that can only by computed when the whole battery model is setup

struct ImaxDischarge <: ScalarVariable end
struct ImaxCharge <: ScalarVariable end


function select_parameters!(S,
                            system::CurrentAndVoltageSystem{SimpleCVPolicy{R}},
                            model::SimulationModel) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
end

function select_parameters!(S,
                            system::CurrentAndVoltageSystem{CyclingCVPolicy{R}},
                            model::SimulationModel) where {R}
    S[:ImaxDischarge] = ImaxDischarge()
    S[:ImaxCharge]    = ImaxCharge()
end


## Setup policy

function setup_policy!(policy::SimpleCVPolicy, init::JSONFile, parameters)

    inputI = only(parameters[:BPP][:ImaxDischarge])

    tup = Float64(init.object["Control"]["rampupTime"])
    
    cFun(time) = currentFun(time, inputI, tup)

    policy.current_function = cFun
    
end

function setup_policy!(policy::CyclingCVPolicy, init::JSONFile, parameters)

    policy.ImaxDischarge = only(parameters[:BPP][:ImaxDischarge])
    policy.ImaxCharge    = only(parameters[:BPP][:ImaxCharge])
    
end


    

## Policy to control functions

function policy_to_control(p::SimpleCVPolicy, is_charging, state, state0, model)
    
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

function policy_to_control(::NoPolicy, is_charging, state, state0, model)
    
    return (2.0, true, rest)
    
end

function policy_to_control(p::CyclingCVPolicy, mode, state, state0, model)
    
    phi = only(state.Phi)
    I   = only(state.Current)

    if mode == cc_discharge1
        # Keep charging if voltage is above limit
        if phi < p.lowerCutoffVoltage
            # @info "Switching to discharge"
            mode = cc_discharge2
        end
        
    elseif mode == cc_charge1
        
        if phi > p.upperCutoffVoltage
            # @info "Switching to charge"
            mode = cv_charge2
        end
    end
    
    if mode == cc_discharge1

        I_t = p.ImaxDischarge
        is_voltage_ctrl = false
        
    elseif mode == cc_discharge2
        
        I_t = 0.
        is_voltage_ctrl = false
        
    elseif mode == cc_charge1

        # minus sign below follows from convention
        I_t = -p.ImaxCharge
        is_voltage_ctrl = false
        
    elseif mode == cv_charge2
        
        V_t = p.upperCutoffVoltage
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

    maincontroler::SimpleControllerCV{R}
    numberOfCycles::I
    
end

function CcCvControllerCV()

    maincontroler = SimpleControllerCV()

    return CcCvControllerCV(maincontroler, 0)
    
end


# helper for CcCvControllerCV so that the fields of SimpleControllerCV appears as inherrited.

function Base.getproperty(c::CcCvControllerCV, f::Symbol)
    if f in fieldnames(SimpleControllerCV)
        return getfield(c.maincontroler, f)
    else
        return getfield(c, f)
    end
end

function Base.setproperty!(c::CcCvControllerCV, f::Symbol, v)
    if f in fieldnames(SimpleControllerCV)
        setfield!(c.maincontroler, f, v)
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


function check_constraints(model, storage)

    converged = true
    
    policy = model[:BPP].system.policy

    state = storage.state
    
    E    = only(state[:BPP][:Phi])
    I    = only(state[:BPP][:Current])
    ctrl = state[:BPP][:ControllerCV]
    
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
        # do not check anything in this case
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
    old.target_is_voltage = new.target_is_voltage
    old.mode              = new.mode
    
end

function Jutul.update_values!(old::CcCvControllerCV, new::CcCvControllerCV)

    Jutul.update_values!(old.maincontroler, new.maincontroler)
    
    old.numberOfCycles = new.numberOfCycles
    
end

function select_control_cv!(cv::ControllerCV, state, state0, model)

    policy = model.system.policy

    mode   = cv.mode

    target, target_is_voltage, mode = policy_to_control(policy, mode, state, state0, model)
    
    cv.target            = target
    cv.target_is_voltage = target_is_voltage
    cv.mode              = mode
    
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

struct VoltageVar <: ScalarVariable end
# relative_increment_limit(::VoltVar) = 0.2

struct CurrentVar <: ScalarVariable end
# absolute_increment_limit(::CurrentVar) = 5.0

function select_equations!(eqs, system::CurrentAndVoltageSystem, model::SimulationModel)

    eqs[:charge_conservation] = CurrentEquation()
    eqs[:control] = ControlEquation()
    
end

function select_primary_variables!(S, system::CurrentAndVoltageSystem, model::SimulationModel)

    S[:Phi]     = VoltageVar()
    S[:Current] = CurrentVar()
    
end

function Jutul.update_before_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel{P}, dt, forces; time = NaN, kwarg...) where {P}

    ctrl = storage.state[:ControllerCV]
    ctrl.time = time
    
end

function Jutul.update_primary_variables!(state, dx, model::CurrentAndVoltageModel{P}; kwarg...) where {P}

    invoke(Jutul.update_primary_variables!,
           Tuple{typeof(state),
                 typeof(dx),
                 JutulModel},
           state,
           dx,
           model; kwarg...)
    
end


function Jutul.update_after_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)
    
    ctrl = storage.state[:ControllerCV]

    policy = model.system.policy

    if policy isa CyclingCVPolicy
        
        Emin     = policy.lowerCutoffVoltage
        Emax     = policy.upperCutoffVoltage
        dEdtMin  = policy.dEdtLimit
        dIdtMin  = policy.dIdtLimit
        initctrl = policy.initialControl

        state  = storage.state
        state0 = storage.state0
        
        mode    = ctrl.mode
        ncycles = ctrl.numberOfCycles

        E = only(state[:Phi])
        I = only(state[:Current])

        dEdt = only((state[:Phi] - state0[:Phi])/dt)
        dIdt = only((state[:Current] - state0[:Current])/dt)

        if mode == cc_discharge1
            
            nextmode = cc_discharge1;
            if (E <= Emin) 
                nextmode = cc_discharge2;
            end
            
        elseif mode == cc_discharge2
            
            nextmode = cc_discharge2

            if (abs(dEdt) <= dEdtMin)
                nextmode = cc_charge1
                if initctrl == charging
                    ncycles = ncycles + 1
                end
            end
            
        elseif mode == cc_charge1

            nextmode = cc_charge1
            if (E >= Emax) 
                nextmode = cv_charge2
            end 
            
        elseif mode == cv_charge2

            nextmode = cv_charge2
            if (abs(dIdt) < dIdtMin)
                nextmode = cc_discharge1
                if initctrl == discharging
                    ncycles = ncycles + 1
                end
            end                  
            
        else
            
            error("mode not recognized")
            
        end

        ctrl.mode = nextmode
        
    else
        
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
    
    select_control_cv!(state.ControllerCV, state, state0, model)
    
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
        
        if     (x > x2)
            res .+= y2
        end

        if  (x < x1)
            res .+= y1
        end
        return res
    
end

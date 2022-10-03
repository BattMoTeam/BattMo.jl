export CurrentAndVoltageSystem, CurrentAndVoltageDomain, CurrentForce, VoltageForce
export VoltageVar, CurrentVar, sineup

struct CurrentAndVoltageSystem <: JutulSystem end

struct CurrentAndVoltageDomain <: JutulDomain end

const CurrentAndVoltageModel  = SimulationModel{CurrentAndVoltageDomain,CurrentAndVoltageSystem}
number_of_cells(::CurrentAndVoltageDomain) = 1

export SimpleCVPolicy, CyclingCVPolicy

abstract type AbstractCVPolicy end

struct SimpleCVPolicy{R} <: AbstractCVPolicy
    current_function
    voltage::R
    function SimpleCVPolicy(current, voltage::T = 2.5) where T<:Real
        new{T}(current, voltage)
    end
end

function policy_to_control(p::SimpleCVPolicy, state, model, dt, time0)
    cf = p.current_function
    if cf isa Real
        I_p = cf
    else
        # Function of time at the end of interval
        I_p = cf(dt + time0)
    end
    phi_p = p.voltage
    phi = only(state.Phi)
    is_voltage_ctrl = phi <= phi_p
    if is_voltage_ctrl
        target = phi_p
    else
        target = I_p
    end
    return (target, is_voltage_ctrl)
end

struct NoPolicy <: AbstractCVPolicy end

function policy_to_control(::NoPolicy, state, model, dt, time0)
    return (2.0, true)
end

struct CyclingCVPolicy{R} <: AbstractCVPolicy
    current_charge::R
    current_discharge::R
    voltage_charge::R
    voltage_discharge::R
    function SimpleCVPolicy(; current_discharge, current_charge = -current_charge, voltage_discharge::T = 2.5, voltage_charge=2*voltage_charge) where T<:Real
        new{T}(current_charge, current_discharge, voltage_charge, voltage_discharge)
    end
end

mutable struct ControllerCV
    policy::AbstractCVPolicy
    time::Real
    target::Real
    target_is_voltage::Bool
end

function Jutul.update_values!(old::ControllerCV, new::ControllerCV)
    old.policy = new.policy
    old.time = new.time
    old.target = new.target
    old.target_is_voltage = new.target_is_voltage
end

function select_control_cv!(cv::ControllerCV, state, model, dt)
    cv.target, cv.target_is_voltage = policy_to_control(cv.policy, state, model, dt, cv.time)
end

# Driving force for the test equation
struct CurrentForce
    current
end

# Driving force for the test equation
struct VoltageForce
    current
end
#abstract type DiagonalEquation <: JutulEquation end
# Equations
struct CurrentEquation <: JutulEquation end
Jutul.local_discretization(::CurrentEquation, i) = nothing

struct ControlEquation <: JutulEquation end
Jutul.local_discretization(::ControlEquation, i) = nothing

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::ControlEquation, model, dt, ldisc = Jutul.local_discretization(eq, i))
    I = only(state.Current)
    phi = only(state.Phi)
    ctrl = state[:ControllerCV]
    if ctrl.target_is_voltage
        v[] = phi - ctrl.target
    else
        v[] = I - ctrl.target
    end
end

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = Jutul.local_discretization(eq, i))
    # Sign is strange here due to cross term?
    I = -only(state.Current)
    phi = only(state.Phi)
    v[] = I + phi*1e-10
end


struct VoltVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

function select_equations!(eqs, system::CurrentAndVoltageSystem, model)
    eqs[:charge_conservation] = CurrentEquation()
    eqs[:control] = ControlEquation()
end

function Jutul.setup_forces(model::SimulationModel{G, S}; policy = NoPolicy()) where {G<:CurrentAndVoltageDomain, S<:CurrentAndVoltageSystem}
    return (policy = policy,)
end

function select_primary_variables!(S, system::CurrentAndVoltageSystem, model)
    S[:Phi] = VoltVar()
    S[:Current] = CurrentVar()
end

function Jutul.update_before_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces; time = NaN)
    ctrl = storage.state[:ControllerCV]
    ctrl.policy = forces.policy
    ctrl.time = time
end

function Jutul.initialize_extra_state_fields!(state, ::Any, model::CurrentAndVoltageModel)
    state[:ControllerCV] = ControllerCV(NoPolicy(), 0.0, 2.0, true)
end

function Jutul.prepare_equation_in_entity!(i, eq::ControlEquation, eq_s, state, state0, model::CurrentAndVoltageModel, dt)
    select_control_cv!(state.ControllerCV, state, model, dt)
end

#function select_secondary_variables_system!(S, domain, system::CurrentAndVoltageSystem, formulation)
#end
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
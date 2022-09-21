export CurrentAndVoltageSystem, CurrentAndVoltageDomain, CurrentForce, VoltageForce
export VoltageVAr, CurrentVar, sineup

struct CurrentAndVoltageSystem <: JutulSystem end

struct CurrentAndVoltageDomain <: JutulDomain end
active_entities(d::CurrentAndVoltageDomain, ::Any) = [1]

const CurrentAndVoltageModel  = SimulationModel{CurrentAndVoltageDomain,CurrentAndVoltageSystem}
number_of_cells(::CurrentAndVoltageDomain) = 1

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
    voltage_control = true
    if voltage_control
        v[] = -I
    else
        v[] = phi
    end
end

function Jutul.update_equation_in_entity!(v, i, state, state0, eq::CurrentEquation, model, dt, ldisc = Jutul.local_discretization(eq, i))
    I = only(state.Current)
    phi = only(state.Phi)
    v[] = I + phi*1e-10
end


struct VoltVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

function select_equations!(eqs, system::CurrentAndVoltageSystem, model)
    eqs[:charge_conservation] = CurrentEquation()
    eqs[:control] = ControlEquation()
end

function Jutul.setup_forces(model::SimulationModel{G, S}; current = nothing) where {G<:CurrentAndVoltageDomain, S<:CurrentAndVoltageSystem}
    return (current = current,)
end

function apply_forces_to_equation!(diag, storage, model, eq::ControlEquation, eq_s, currentFun, time)
    @. diag -= currentFun(time)
end

function select_primary_variables!(S, system::CurrentAndVoltageSystem, model)
    S[:Phi] = VoltVar()
    S[:Current] = CurrentVar()
end

function Jutul.update_before_step!(storage, domain::CurrentAndVoltageDomain, model::CurrentAndVoltageModel, dt, forces)
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
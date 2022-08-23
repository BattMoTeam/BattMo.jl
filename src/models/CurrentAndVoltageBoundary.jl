export CurrentAndVoltageSystem, CurrentAndVoltageDomain, CurrentForce, VoltageForce
export VoltageVAr, CurrentVar, sineup

struct CurrentAndVoltageSystem <: JutulSystem end

struct CurrentAndVoltageDomain <: JutulDomain end
active_entities(d::CurrentAndVoltageDomain, ::Any) = [1]

const CurrentAndVoltageModel  = SimulationModel{CurrentAndVoltageDomain,CurrentAndVoltageSystem}
function number_of_cells(::CurrentAndVoltageDomain) 1 end

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
struct CurrentEquation <: DiagonalEquation end

function setup_equation_storage(model, e::CurrentEquation, storage; kwarg...)
    Ω = model.domain
    nc = number_of_cells(Ω)
    @assert nc == 1 # We use nc for clarity of the interface - but it should always be one!
    ne = 1 # Single, scalar equation
    npartials = number_of_equations_per_entity(model, e)
    e = CompactAutoDiffCache(ne, nc, npartials, context = model.context; kwarg...)
    return e
end

function declare_pattern(model, e::CurrentEquation, eq_storage::CompactAutoDiffCache, unit)
    @assert unit == Cells()
    return ([1], [1])
end

struct VoltVar <: ScalarVariable end
struct CurrentVar <: ScalarVariable end

function select_equations!(eqs, system::CurrentAndVoltageSystem, model)
    eqs[:charge_conservation] = CurrentEquation()
end

function update_equation!(eq_s::CompactAutoDiffCache, eq::CurrentEquation, storage, model, dt)
    phi = storage.state.Phi
    equation = get_entries(eq)
    @. equation = phi*1e-10
end

function build_forces(model::SimulationModel{G, S}; sources = nothing) where {G<:CurrentAndVoltageDomain, S<:CurrentAndVoltageSystem}
    return (sources = sources,)
end

function apply_forces_to_equation!(storage, model, eq::CurrentEquation, currentFun, time)
    #current = storage.state.Current
    equation = get_entries(eq)
    @. equation -= currentFun(time)
    #equation[:control_equations] = current-currentVal(time)
end

function select_primary_variables!(S, system::CurrentAndVoltageSystem, model)
    S[:Phi] = VoltVar()
    #S[:Current] = CurrentVar()
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
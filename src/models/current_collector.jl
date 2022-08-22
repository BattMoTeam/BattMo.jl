export CurrentCollector

struct CurrentCollector <: ElectroChemicalComponent end

function minimum_output_variables(
    system::CurrentCollector, primary_variables
    )
    [:TPkGrad_Phi, :Charge]
end

function select_primary_variables!(
    S, system::CurrentCollector, model
    )
    S[:Phi] = Phi()
end

function select_secondary_variables!(
    S, system::CurrentCollector, model
    )
    S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:Charge] = Charge()
    S[:Conductivity] = Conductivity()
end

function select_equations!(
    eqs, system::CurrentCollector, model)
    #charge_cons = (arg...; kwarg...) -> Conservation(Charge(), arg...; kwarg...)
    disc = model.domain.discretizations.charge_flow
    T = typeof(disc)

    eqs[:charge_conservation] = Conservation{Charge, T}(Charge())#(charge_cons, 1)
end

function apply_forces_to_equation!(storage, 
    model::SimulationModel{<:Any, <:CurrentCollector, <:Any, <:Any},
    law::Conservation{Charge}, force, time)
    cell = force.cell
    rate = force.src
    tup = 0.1
    #inputI = 9.4575
    inputI = rate
    #equation = get_entries(eq)
    acc = get_entries(law.accumulation)
    #t = time
    #if ( t<= tup)
    #    val = sineup(0, inputI, 0, tup, t) 
    #else
        val = inputI;
    #end
    #val = (t <= tup) .* sineup(0, inputI, 0, tup, t) + (t > tup) .* inputI;
    acc[cell] -= val
    #for cell in cells
    #    equation[cell] += rate
    #end
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::Conductivity, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryPotential{Phi}, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryPotential{T}, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Charge}, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Mass}, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Energy}, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::Diffusivity, model, param
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::T, model, param
    )
end
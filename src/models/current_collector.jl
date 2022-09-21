export CurrentCollector

struct CurrentCollector <: ElectroChemicalComponent end

function select_minimum_output_variables!(out,
    system::CurrentCollector, model
    )
    push!(out, :Charge)
end

function select_primary_variables!(
    S, system::CurrentCollector, model
    )
    S[:Phi] = Phi()
end

function select_secondary_variables!(
    S, system::CurrentCollector, model
    )
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:Charge] = Charge()
    S[:Conductivity] = Conductivity()
end

function select_equations!(
    eqs, system::CurrentCollector, model)
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
end

function apply_forces_to_equation!(acc, storage,
    model::SimulationModel{<:Any, <:CurrentCollector, <:Any, <:Any},
    law::ConservationLaw{:Charge}, eq_s, force, time)
    cell = force.cell
    rate = force.src
    tup = 0.1
    #inputI = 9.4575
    inputI = rate
    #equation = get_entries(eq)
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
    kGrad, sv::Conductivity, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryPotential{Phi}, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryPotential{T}, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Charge}, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Mass}, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::BoundaryCurrent{Energy}, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::Diffusivity, model
    )
end

@jutul_secondary function update_as_secondary!(
    kGrad, sv::T, model
    )
end
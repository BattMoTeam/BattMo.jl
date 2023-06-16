using Infiltrator
export CurrentCollector

struct CurrentCollector <: ElectroChemicalComponent
    params
end

function CurrentCollector()
    CurrentCollector(Dict())
end

function select_minimum_output_variables!(out,
    system::CurrentCollector, model::SimulationModel
    )
    push!(out, :Charge)
end

function select_primary_variables!(
    S, system::CurrentCollector, model::SimulationModel
    )
    S[:Phi] = Phi()
end

function select_secondary_variables!(
    S, system::CurrentCollector, model::SimulationModel
    )
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:Charge] = Charge()
    
end

function select_parameters!(S,
                            system::CurrentCollector,
                            model::SimulationModel)

    S[:Conductivity] = Conductivity()
    if count_entities(model.data_domain, BoundaryControlFaces()) > 0
        S[:BoundaryPhi]  = BoundaryPotential(:Phi)
        S[:BoundaryC]    = BoundaryPotential(:C)
    end
    
end

function select_equations!(eqs,
                           system::CurrentCollector,
                           model::SimulationModel)
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    
end

function apply_forces_to_equation!(acc,
                                   storage,
                                   model::SimulationModel{<:Any, <:CurrentCollector, <:Any, <:Any},
                                   law::ConservationLaw{:Charge},
                                   eq_s,
                                   force,
                                   time)
    
    cell   = force.cell
    inputI = force.src
    
    acc[cell] -= inputI
    
end

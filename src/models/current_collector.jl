export CurrentCollector

const CurrentCollectorParameters = JutulStorage

struct CurrentCollector{T} <: ElectroChemicalComponent where {T<:CurrentCollectorParameters}
    params::T
    # At the moment the following keys are include
    # - density::Real
end

function CurrentCollector(params::CurrentCollectorParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return CurrentCollector{typeof(params)}(params)
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
    if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
        if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
            S[:BoundaryPhi]  = BoundaryPotential(:Phi)
        end
    end
    
end

function select_equations!(eqs,
                           system::CurrentCollector,
                           model::SimulationModel)
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    
end


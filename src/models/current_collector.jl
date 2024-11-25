export CurrentCollector

const CurrentCollectorParameters = JutulStorage

struct CurrentCollector{T, D} <: BattMoSystem where {T<:CurrentCollectorParameters, D <: AbstractDict}
    params::T
    # At the moment the following keys are include
    # - density::Real
    scalings::D
end

function CurrentCollector(params::CurrentCollectorParameters, scalings = Dict())
    params = Jutul.convert_to_immutable_storage(params)
    return CurrentCollector{typeof(params), typeof(scalings)}(params, scalings)
end

function CurrentCollector()
    CurrentCollector(Dict())
end

const CurrentCollectorModel = SimulationModel{O, S} where {O<:JutulDomain, S<:CurrentCollector}

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
    disc = model.domain.discretizations.flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    
end


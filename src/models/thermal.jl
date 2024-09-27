export Thermal

const ThermalParameters = JutulStorage

struct Thermal{T} <: ElectroChemicalComponent where {T<:ThermalParameters}
    params::T
    # At the moment the following keys are include
    # - density::Real
end

function Thermal(params::ThermalParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return Thermal{typeof(params)}(params)
end


function Thermal()
    Thermal(Dict())
end

function select_minimum_output_variables!(out,
    system::Thermal, model::SimulationModel
    )
    push!(out, :Temperature)
end

function select_primary_variables!(
    S, system::Thermal, model::SimulationModel
    )
    S[:Temperature] = Temperature()
end

function select_secondary_variables!(
    S, system::Thermal, model::SimulationModel
    )
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:Energy] = Energy()
    
end

function select_parameters!(S,
                            system::Thermal,
                            model::SimulationModel)

    S[:Conductivity] = Conductivity()
    if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
        if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
            S[:BoundaryTemperature]  = BoundaryTemperature(:Temperature)
        end
    end
    
end

function select_equations!(eqs,
                           system::Thermal,
                           model::SimulationModel)
    disc = model.domain.discretizations.charge_flow

    eqs[:energy_conservation] = ConservationLaw(disc, :Temperature)
    
end
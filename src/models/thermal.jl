export Thermal

const ThermalParameters = JutulStorage

struct ThermalSystem{T} <: ElectroChemicalComponent where {T<:ThermalParameters}
    params::T
    # At the moment the following keys are include
    # - density::Real
end

function ThermalSystem(params::ThermalParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return ThermalSystem{typeof(params)}(params)
end


function ThermalSystem()
    ThermalSystem(Dict())
end

const ThermalModel = SimulationModel{<:Any, <:ThermalSystem, <:Any, <:Any}

function select_minimum_output_variables!(out,
    system::ThermalSystem, model::SimulationModel
    )
    push!(out, :Temperature)
end

function select_primary_variables!(
    S, system::ThermalSystem, model::SimulationModel
    )
    S[:Temperature] = Temperature()
end

function select_secondary_variables!(
    S, system::ThermalSystem, model::SimulationModel
    )
    S[:Energy] = Energy()
end

@jutul_secondary function update_energy!(acc        ,
                                         tv::Energy ,
                                         model      ,
                                         Temperature,
                                         Volume,
                                         Capacity,
                                         ix)
    for i in ix
        @inbounds acc[i] = Volume[i]*Capacity[i]*Temperature[i]
    end
    
end

function select_parameters!(S,
                            system::ThermalSystem,
                            model::SimulationModel)

    S[:Conductivity] = Conductivity()
    S[:Capacity]     = Capacity()
    if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
        if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
            S[:BoundaryTemperature]  = BoundaryTemperature(:Temperature)
        end
    end
    
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Temperature, <:Any}, state, model::ThermalModel, dt, flow_disc) where T
    
    @inbounds trans = state.ECTransmissibilities[face]
    j = - half_face_two_point_kgrad(c, other, trans, state.Temperature, state.Conductivity)

    return T(j)
    
end


function select_equations!(eqs,
                           system::ThermalSystem,
                           model::SimulationModel)

    disc = model.domain.discretizations.heat_flow
    eqs[:energy_conservation] = ConservationLaw(disc, :Energy)
    
end

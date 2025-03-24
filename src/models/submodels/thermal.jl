###################################################################
# In this module we define methods to handle the Thermal model
# 
# File structure:
# - Initiate a Jutul.JutulStorage
# - Create a subclass of Jutul.JutulSystem
# - Initiate a Jutul.SimulationModel
# - Extend functions called by Jutul.SimulationModel
# - Define methods for calculating secondary variables
# - Define methods for calculating face fluxes
#
###################################################################


export Thermal

##################################
# Initiate a Jutul.JutulStorage
##################################

const ThermalParameters = JutulStorage


###########################################
# Create a subclass of Jutul.JutulSystem
###########################################


struct Thermal{T} <: ElectroChemicalComponent where {T<:ThermalParameters}
    params::T
end

function Thermal(params::ThermalParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return Thermal{typeof(params)}(params)
end


function Thermal()
    Thermal(Dict())
end

###########################################
# Initiate a Jutul.SimulationModel
###########################################

const ThermalModel = SimulationModel{<:Any, <:Thermal, <:Any, <:Any}


#################################################
# Extend functions called by Jutul.SimulationModel
#################################################

function Jutul.select_minimum_output_variables!(out,
                                                system::Thermal, 
                                                model::SimulationModel
                                                )
    push!(out, :Temperature)
end

function Jutul.select_primary_variables!(
    S, system::Thermal, model::SimulationModel
    )
    S[:Temperature] = Temperature()
end

function Jutul.select_secondary_variables!(
    S, system::Thermal, model::SimulationModel
    )
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:Energy] = Energy()
    
end

function Jutul.select_parameters!(S,
    system::Thermal,
    model::SimulationModel)

    S[:Conductivity] = Conductivity()

    if hasentity(model.data_domain, BoundaryDirichletFaces())
        if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
            S[:BoundaryTemperature]  = BoundaryTemperature(:Temperature)
        end
    end

end

function Jutul.select_equations!(eqs,
   system::Thermal,
   model::SimulationModel)

    disc = model.domain.discretizations.heat_flow
    eqs[:energy_conservation] = ConservationLaw(disc, :Energy)

end

#####################################################
# Define methods for calculating secondary variables
#####################################################

@jutul_secondary function update_as_secondary!(acc        ,
                                               tv::Energy ,
                                               model      ,
                                               Temperature,
                                               ix)
    for i in ix
        @inbounds acc[i] = Temperature[i]
    end
    
end



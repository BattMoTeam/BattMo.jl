###################################################################################
# In this module we define methods to handle the ActiveMaterial model. This model 
# can be used as a basemodel for setting up specific ActiveMaterial models.
#
# File structure:
# - Initiate a Jutul.JutulStorage
# - Create a subclass of Jutul.JutulSystem
# - Initiate a Jutul.SimulationModel
# - Extend functions called by Jutul.SimulationModel
# - Define methods for calculating secondary variables
# - Define methods for calculating face fluxes
#
####################################################################################


export ActiveMaterial, ActiveMaterialModel
export SolidMassConservation

##################################
# Initiate a Jutul.JutulStorage
##################################

const ActiveMaterialParameters = JutulStorage

###########################################
# Create a subclass of Jutul.JutulSystem
###########################################

abstract type AbstractActiveMaterial{label} <: ElectroChemicalComponent end

activematerial_label(::AbstractActiveMaterial{label}) where label = label

abstract type SolidDiffusionDiscretization end

struct ActiveMaterial{label, D, T, Di} <: AbstractActiveMaterial{label} where {D<:SolidDiffusionDiscretization, T<:ActiveMaterialParameters, Di <: AbstractDict}
    params::T
    discretization::D
    scalings::Di  
end 


###########################################
# Initiate a Jutul.SimulationModel
###########################################

const ActiveMaterialModel = SimulationModel{O, S} where {O<:JutulDomain, S<:ActiveMaterial}

###########################
# Define general functions 
###########################


function discretisation_type(model::ActiveMaterialModel)
    discretisation_type(model.system)
end


function maximum_concentration(system::ActiveMaterial)
    # used in convergence criteria
    return system.params[:maximum_concentration]
end





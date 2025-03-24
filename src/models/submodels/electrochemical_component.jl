#################################################################################
# In this module we define methods to handle the ElectroChemicalComponent model.
# This is a basemodel for the submodels that describe electrochemical process. 
# These submodels are:
# - ActiveMaterialModel
# - ElectrolyteModel
# - ThermalModel
# - CurrentCollectorModel
# 
# File structure:
# - Initiate a Jutul.JutulStorage
# - Create a subclass of Jutul.JutulSystem
# - Initiate a Jutul.SimulationModel
# - Extend functions called by Jutul.SimulationModel
# - Define methods for calculating secondary variables
# - Define methods for calculating face fluxes
#
#################################################################################

export ElectroChemicalComponent

###########################################
# Create a subclass of Jutul.JutulSystem
###########################################

abstract type ElectroChemicalComponent <: JutulSystem end


###########################################
# Initiate a Jutul.SimulationModel
###########################################

const ElectroChemicalComponentModel = SimulationModel{<:Any, <:ElectroChemicalComponent, <:Any, <:Any}


###########################################
# Extend utility functions
###########################################

function Base.getindex(system::ElectroChemicalComponent, key::Symbol)
    return system.params[key]
end


#####################################################
# Define methods for updating the conservation laws
#####################################################

@jutul_secondary function update_ion_mass!(acc           ,
    tv::Mass      ,
    model::ElectroChemicalComponentModel         ,
    C             ,
    Volume        ,
    VolumeFraction,
    ix)
for i in ix
@inbounds acc[i] = C[i] * Volume[i] * VolumeFraction[i]
end
end

@jutul_secondary function update_as_secondary!(acc       ,
        tv::Charge,
        model     ,
        Phi       ,
        ix)
for i in ix
@inbounds acc[i] = 0.0
end
end

@inline function Jutul.face_flux!(q_i, face, eq::ConservationLaw, state, model::ElectroChemicalComponentModel, dt, flow_disc::PotentialFlow, ldisc)

    # Inner version, for generic flux
    kgrad, upw = ldisc.face_disc(face)
    (; left, right, face_sign) = kgrad
    
    return face_flux!(q_i, left, right, face, face_sign, eq, state, model, dt, flow_disc)
    
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    
    return T(q)
end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)

    return T(q)
    
end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.Temperature, state.Conductivity)

    return T(q)
    
end

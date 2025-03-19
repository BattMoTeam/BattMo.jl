###################################################################
# In this module we define methods to handle the Electrolyte model
# 
# File structure:
# - Initiate a Jutul.JutulStorage
# - Create a subclass of Jutul.JutulSystem
# - Initiate a Jutul.SimulationModel
# - Define methods called by Jutul.SimulationModel
# - Define methods for calculating secondary variables
# - Define methods for calculating face fluxes
###################################################################

export Electrolyte, ElectrolyteModel

##################################
# Initiate a Jutul.JutulStorage
##################################

const ElectrolyteParameters = JutulStorage

###########################################
# Create a subclass of Jutul.JutulSystem
###########################################

struct Electrolyte{D} <: ElectroChemicalComponent where {D <: AbstractDict}
    params::ElectrolyteParameters

    scalings::D

    
end

function Electrolyte(params, scalings = Dict())
    
    return Electrolyte{typeof(scalings)}(params, scalings)
    
end


###########################################
# Initiate a Jutul.SimulationModel
###########################################

const ElectrolyteModel = SimulationModel{<:Any, <:Electrolyte, <:Any, <:Any}




#################################################
# Define methods called by Jutul.SimulationModel
#################################################

function Jutul.select_primary_variables!(S                  ,
                                   system::Electrolyte,
                                   model::SimulationModel)

    S[:Phi] = Phi()
    S[:C]   = C()
    
end
        
function Jutul.select_parameters!(S                  ,
                            system::Electrolyte,
                            model::SimulationModel
                            )
    
    S[:Temperature]    = Temperature()
    S[:VolumeFraction] = VolumeFraction()
    
end

function Jutul.select_equations!(eqs                ,
                           system::Electrolyte,
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)
    
end

function Jutul.select_secondary_variables!(S,
                                     system::Electrolyte,
                                     model::SimulationModel)
    
    S[:Conductivity] = Conductivity()
    S[:Diffusivity]  = Diffusivity()
    S[:DmuDc]        = DmuDc()
    S[:ChemCoef]     = ChemCoef()

    S[:Charge] = Charge()
    S[:Mass]   = Mass()

end

function Jutul.select_minimum_output_variables!(out,
                                          system::Electrolyte,
                                          model::SimulationModel)
    
    for k in [:Charge, :Mass, :Conductivity, :Diffusivity]
        push!(out, k)
    end
    
end


#####################################################
# Define methods for calculating secondary variables
#####################################################

@inline function transference(system::Electrolyte)
    return system[:transference]
end

@jutul_secondary(
function update_dmudc!(dmudc, dmudc_def::DmuDc, model, Temperature, C, ix)
    R = GAS_CONSTANT
    @tullio dmudc[i] = R * (Temperature[i] / C[i])
end
)

@jutul_secondary(
function update_conductivity!(kappa, kappa_def::Conductivity, model::ElectrolyteModel, Temperature, C, VolumeFraction, ix)
    """ Register conductivity function
    """
    
    # We use Bruggeman coefficient
    for i in ix
        
        if haskey(model.system.params, :conductivity_data)

            @inbounds kappa[i] = model.system[:conductivity_func](C[i]) * VolumeFraction[i]^1.5

        else
            @inbounds kappa[i] = model.system[:conductivity_func](C[i], Temperature[i]) * VolumeFraction[i]^1.5
        end
    end
end
)

@jutul_secondary function update_diffusivity!(D, D_def::Diffusivity, model::ElectrolyteModel, C, Temperature, VolumeFraction, ix)
    """ Register diffusivity function
    """
    
    for i in ix

        if haskey(model.system.params, :diffusivity_data)

            @inbounds D[i] = model.system[:diffusivity_func](C[i])*VolumeFraction[i]^1.5

        else
            
            @inbounds D[i] = model.system[:diffusivity_func](C[i], Temperature[i])*VolumeFraction[i]^1.5
        end
        
    end
    
end

@jutul_secondary function update_chem_coef!(chemCoef, tv::ChemCoef, model::ElectrolyteModel, Conductivity, DmuDc, ix)
    """Register constant for chemical flux
    """
    sys = model.system
    t = transference(sys)
    F = FARADAY_CONSTANT
    for i in ix
        @inbounds chemCoef[i] = 1.0/F*(1.0 - t)*Conductivity[i]*2.0*DmuDc[i]
    end
end


#####################################################
# Define methods for calculating face fluxes
#####################################################


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T
    
    @inbounds trans = state.ECTransmissibilities[face]
    j     = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity) # electrical current density
    jchem = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef) # chemical current density
    
    j = j - jchem*(1.0) 

    return T(j)
    
end


function Jutul.face_flux!(q::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T

    t = transference(model.system)
    z = 1.0
    F = FARADAY_CONSTANT
    
    @inbounds trans = state.ECTransmissibilities[face]

    diffFlux = - half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity) # diffusion flux
    j        = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    jchem    = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef)
    
    j = j - jchem*(1.0)
    
    massFlux = diffFlux + t/(z*F)*j
    return setindex(q, massFlux, 1)::T
end

# Model for a electrolyte

using Polynomials
export Electrolyte, DmuDc, ChemCoef
export p1, p2, p3, diffusivity
export ElectrolyteModel

const ElectrolyteParameters = JutulStorage

struct Electrolyte <: ElectroChemicalComponent 
    params::ElectrolyteParameters
    #  
    # - bruggeman          
    # - charge             
    # - conductivity_data  
    # - conductivity_func  
    # - diffusivity_data   
    # - diffusivity_func   
    # - separator_porosity 
    # - transference
    # - electrolyte_density
    # - separator_density
    
end

# Alias for convenience
const ElectrolyteModel = SimulationModel{<:Any, <:Electrolyte, <:Any, <:Any}

# Is it necesessary with a new struct for all of these?
struct DmuDc <: ScalarVariable end
struct ChemCoef <: ScalarVariable end

maximum_concentration(::Electrolyte) = 1000.0

function select_primary_variables!(S                  ,
                                   system::Electrolyte,
                                   model::SimulationModel)

    S[:Phi] = Phi()
    S[:C]   = C()
    
end
        
function select_parameters!(S                  ,
                            system::Electrolyte,
                            model::SimulationModel
                            )
    
    S[:Temperature]    = Temperature()
    S[:VolumeFraction] = VolumeFraction()
    
end

function select_equations!(eqs                ,
                           system::Electrolyte,
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)
    
end

function select_secondary_variables!(S,
                                     system::Electrolyte,
                                     model::SimulationModel)
    
    S[:Conductivity] = Conductivity()
    S[:Diffusivity]  = Diffusivity()
    S[:DmuDc]        = DmuDc()
    S[:ChemCoef]     = ChemCoef()

    S[:Charge] = Charge()
    S[:Mass]   = Mass()

end

function select_minimum_output_variables!(out,
                                          system::Electrolyte,
                                          model::SimulationModel)
    
    for k in [:Charge, :Mass, :Conductivity, :Diffusivity]
        push!(out, k)
    end
    
end


#######################
# Secondary Variables #
#######################

const poly_param = [
    -10.5       0.074       -6.96e-5    ;
    0.668e-3    -1.78e-5    2.80e-8     ;
    0.494e-6    -8.86e-10   0           ;
]
const p1 = Polynomial(poly_param[1:end, 1])
const p2 = Polynomial(poly_param[1:end, 2])
const p3 = Polynomial(poly_param[1:end, 3])

@inline function computeElectrolyteConductivity_default(c::Real, T::Real)
    """ Compute the electrolyte conductivity as a function of temperature and concentration
    """
    fact = 1e-4
    return fact*c*(p1(c) + p2(c)*T + p3(c)*T^2)^2
end

@inline function computeElectrolyteConductivity_Chen2020(c::Real, T::Real)
    """ Compute the electrolyte conductivity as a function of concentration
    """
    c = c/1000
    return 0.1297*c^3 - 2.51*c^(1.5) + 3.329*c
end

const diff_params = [
    -4.43   -54 ;
    -0.22   0.0 ;
]
const Tgi = [229 5.0]

@inline function computeDiffusionCoefficient_default(c::Real, T::Real)
    """ Compute the diffusion coefficient as a function of temperature and concentration
    """
    return (
        1e-4 * 10 ^ ( 
            diff_params[1,1] + 
            diff_params[1,2]/(T - Tgi[1] - Tgi[2]*c* 1e-3) + 
            diff_params[2,1]*c*1e-3
            )
        )
end

@inline function computeDiffusionCoefficient_Chen2020(c::Real, T::Real)
    """ Compute the diffusion coefficient as a function of concentration
    """
    c = c/1000
    return 8.794*10^(-11)*c^2 - 3.972*10^(-10)*c + 4.862*10^(-10)
end

@inline function transference(system::Electrolyte)
    return system[:transference]
end

@jutul_secondary(
function update_as_secondary!(dmudc, dmudc_def::DmuDc, model, Temperature, C, ix)
    R = GAS_CONSTANT
    @tullio dmudc[i] = R * (Temperature[i] / C[i])
end
)

# ? Does this maybe look better ?
@jutul_secondary(
function update_conductivity!(kappa, kappa_def::Conductivity, model::ElectrolyteModel, Temperature, C, VolumeFraction, ix)
    """ Register conductivity function
    """
    
    # We use Bruggeman coefficient
    for i in ix
        
        if Jutul.haskey(model.system.params, :conductivity_data)

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

        if Jutul.haskey(model.system.params, :diffusivity_data)

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
    F = FARADAY_CONST
    for i in ix
        @inbounds chemCoef[i] = 1.0/F*(1.0 - t)*Conductivity[i]*2.0*DmuDc[i]
    end
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T
    
    @inbounds trans = state.ECTransmissibilities[face]
    j     = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    jchem = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef)
    
    j = j - jchem*(1.0)

    return T(j)
    
end


function Jutul.face_flux!(q::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T

    t = transference(model.system)
    z = 1.0
    F = FARADAY_CONST
    
    @inbounds trans = state.ECTransmissibilities[face]

    diffFlux = - half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    j        = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    jchem    = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef)
    
    j = j - jchem*(1.0)
    
    massFlux = diffFlux + t/(z*F)*j
    return setindex(q, massFlux, 1)::T
end

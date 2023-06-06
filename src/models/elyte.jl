# Model for a electrolyte

using Polynomials
export Electrolyte, TestElyte, DmuDc, ChemCoef
export p1, p2, p3, diffusivity
export ElectrolyteModel

abstract type Electrolyte <: ElectroChemicalComponent end
struct TestElyte <: Electrolyte
    setup_parameters <: JutulStorage
end

function Base.getindex(system::TestElyte, key::Symbol)
    return system.setup_parameters[key]
end

function setupElectrolyte!(system::TestElyte)
    system.setup_parameters[:transference] = 0.601
end


# Alias for convinience
const ElectrolyteModel = SimulationModel{<:Any, <:Electrolyte, <:Any, <:Any}
const TestElyteModel = SimulationModel{<:Any, <:TestElyte, <:Any, <:Any}

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
    S[:Temperature]  = Temperature()
    
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

@inline function conductivity(T::Real, C::Real, ::Electrolyte)
    """ Compute the electrolyte conductivity as a function of temperature and concentration
    """
    fact = 1e-4
    return fact * C * (p1(C) + p2(C) * T + p3(C) * T^2)^2
end

const diff_params = [
    -4.43   -54 ;
    -0.22   0.0 ;
]
const Tgi = [229 5.0]

@inline function diffusivity(T::Real, C::Real, ::Electrolyte)
    """ Compute the diffusion coefficient as a function of temperature and concentration
    """
    return (
        1e-4 * 10 ^ ( 
            diff_params[1,1] + 
            diff_params[1,2] / ( T - Tgi[1] - Tgi[2] * C * 1e-3) + 
            diff_params[2,1] * C * 1e-3
            )
        )
end

@inline function transference(system::TestElyte)
    return system[:transference]
    # return 0.601
end

@jutul_secondary(
function update_as_secondary!(dmudc, dmudc_def::DmuDc, model, Temperature, C, ix)
    R = GAS_CONSTANT
    @tullio dmudc[i] = R * (Temperature[i] / C[i])
end
)

# ? Does this maybe look better ?
@jutul_secondary(
function update_conductivity!(kappa, kappa_def::Conductivity, model::ElectrolyteModel, Temperature, C, ix)
    """ Register conductivity function
    """
    s = model.system
    # We use Bruggeman coefficient
    vf = model.domain.representation.vol_frac
    for i in ix
        @inbounds kappa[i] = conductivity(Temperature[i], C[i], s) * vf[i]^1.5
    end
end
)

@jutul_secondary function update_diffusivity!(D, D_def::Diffusivity, model::ElectrolyteModel, C, Temperature, ix)
    """ Register diffusivity function
    """
    s = model.system
    vf = model.domain.representation.vol_frac
    for i in ix
        @inbounds D[i] = diffusivity(Temperature[i], C[i], s)  * vf[i]^1.5
    end
end

@jutul_secondary function update_chem_coef!(chemCoef, tv::ChemCoef, model::ElectrolyteModel, Conductivity, DmuDc, ix)
    """Register constant for chemical flux
    """
    sys = model.system
    t = transference(sys)
    F = FARADAY_CONST
    for i in ix
        @inbounds chemCoef[i] = 1/F*(1 - t)*Conductivity[i]*2*DmuDc[i]
    end
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T
    
    @inbounds trans = state.ECTransmissibilities[face]
    j     = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    jchem = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef)
    
    j = j - jchem*(1.0)

    return T(j)
    
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T

    t = transference(model.system)
    z = 1
    F = FARADAY_CONST
    
    @inbounds trans = state.ECTransmissibilities[face]

    diffFlux = - half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    j        = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    jchem    = - half_face_two_point_kgrad(c, other, trans, state.C, state.ChemCoef)
    
    j = j - jchem*(1.0)
    
    massFlux = diffFlux + t/(z*F)*j
    
    return T(massFlux)
    
end

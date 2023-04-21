export ActiveMaterial, ActiveMaterialModel, SolidMassCons, NoParticleDiffusion

## The parameter for the active material are stored in a dictionnary
const ActiveMaterialParameters = Dict{Symbol, Any}
abstract type SolidDiffusionDiscretization end

struct P2Ddiscretization <: SolidDiffusionDiscretization
    data::Dict{Symbol, Any}
    # At the moment the following keys are included :
    # N::Integer                   # Discretization size for solid diffusion
    # R::Real                      # Particle radius
    # A::Vector{Float64}           # vector of coefficients for harmonic average (half-transmissibility for spherical coordinate)
    # v::Vector{Float64}           # vector of volumes (volume of spherical layer)
    # div::Vector{Vector{Float64}} # Helping structure to compute divergence operator for particle diffusion
end

struct NoParticleDiffusion <: SolidDiffusionDiscretization end

struct ActiveMaterial{D} <: ElectroChemicalComponent where {D<:SolidDiffusionDiscretization}
    params::ActiveMaterialParameters
    # At the moment the following keys are include
    # - ocp_func::F where {F <: Function}
    # - n_charge_carriers
    # - reaction_rate_constant_func::F where {F <: Function}
    # - diffusion_coef_func::F where {F <: Function}
    # - maximum_concentration::Real
    # - volumetric_surface_area::Real
    discretization::D
end 

struct Ocp               <: ScalarVariable  end
struct DiffusionCoef     <: ScalarVariable  end
struct ReactionRateConst <: ScalarVariable  end
struct Cp                <: VectorVariables end # particle concentrations in p2d model
struct Cs                <: ScalarVariable  end # surface variable in p2d model
struct SolidDiffFlux     <: VectorVariables end # flux in P2D model

struct SolidMassCons <: JutulEquation end
Jutul.local_discretization(::SolidMassCons, i) = nothing

const ActiveMaterialModel = SimulationModel{O, S} where {O<:JutulDomain, S<:ActiveMaterial}

## Create ActiveMaterial with full p2d solid diffusion
function ActiveMaterial{P2Ddiscretization}(params::ActiveMaterialParameters, R, N) 
    data = setupSolidDiffusionDiscretization(R, N)
    discretization = P2Ddiscretization(data)
    return ActiveMaterial{P2Ddiscretization}(params, discretization)
end

## Create ActiveMaterial with no solid diffusion
function ActiveMaterial{NoParticleDiffusion}(param::ActiveMaterialParameters) 
    discretization = NoParticleDiffusion()
    return ActiveMaterial{NoParticleDiffusion}(param, discretization)
end

####
# Setup functions for P2D
####

function Base.getindex(disc::P2Ddiscretization, key::Symbol)
    return disc.data[key]
end

function discretisation_type(system::ActiveMaterial{P2Ddiscretization})
    return :P2Ddiscretization
end

function discretisation_type(system::ActiveMaterial{NoParticleDiffusion})
    return :NoParticleDiffusion
end

function discretisation_type(model::ActiveMaterialModel)
    discretisation_type(model.system)
end

function solid_diffusion_discretization_number(system::ActiveMaterial{P2Ddiscretization})
    return system.discretization[:N]
end

function maximum_concentration(system::ActiveMaterial)
    # used in convergence criteria
    return system.params[:maximum_concentration]
end

function setupSolidDiffusionDiscretization(R, N)

    N = Int64(N)
    R = Float64(R)
    
    A    = zeros(Float64, N)
    vols = zeros(Float64, N)

    dr   = R/N
    rc   = [dr*(i - 1/2) for i  = 1 : N]
    rf   = [dr*i for i  = 0 : (N + 1)]
    for i = 1 : N
        vols[i] = 4*pi/3*(rf[i + 1]^3 - rf[i]^3)
        A[i]    = 4*pi*rc[i]^2/(dr/2)
    end

    div = Vector{Tuple{Int64, Int64, Float64}}(undef, 2*(N - 1))

    k = 1
    for j = 1 : N - 1
        div[k] = (j, j, 1)
        k += 1
        div[k] = (j + 1, j, -1)
        k += 1
    end
        
    data = Dict(:N => N      ,
                :R => R      ,
                :A => A      ,
                :vols => vols,
                :div => div  ,
                )
    
    return data
        
end

#####################################################
## Setup common for both diffusion models (full p2d and no diffusion)
####################################################

function select_minimum_output_variables!(out                   ,
                                          system::ActiveMaterial,
                                          model::SimulationModel
                                          )
    push!(out, :Charge)
    push!(out, :Mass)
    push!(out, :Ocp)
    push!(out, :Temperature)
    
end

function Jutul.select_parameters!(S                     ,
                                  system::ActiveMaterial,
                                  model::SimulationModel
                                  )
    
    S[:Temperature]  = Temperature()
    S[:Conductivity] = Conductivity()
    S[:Diffusivity]  = Diffusivity()
    
end


#####################################################
## We setup the case with full P2d discretization
####################################################

function select_primary_variables!(S,
                                   system::ActiveMaterial{P2Ddiscretization},
                                   model::SimulationModel
                                   )
    S[:Phi] = Phi()
    S[:Cp]  = Cp()
    
end


function degrees_of_freedom_per_entity(model::ActiveMaterialModel,
                                       ::Cp)
    return solid_diffusion_discretization_number(model.system)
end

function degrees_of_freedom_per_entity(model::ActiveMaterialModel,
                                       ::SolidDiffFlux)
    return  solid_diffusion_discretization_number(model.system) - 1
end


function select_secondary_variables!(S,
                                     system::ActiveMaterial{P2Ddiscretization},
                                     model::SimulationModel
                                     )
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    S[:Cs]                = Cs()
    S[:DiffusionCoef]     = DiffusionCoef()
    S[:SolidDiffFlux]     = SolidDiffFlux()
    
end


function select_equations!(eqs,
                           system::ActiveMaterial{P2Ddiscretization},
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = SolidMassCons()
    
end


function Jutul.number_of_equations_per_entity(model::ActiveMaterialModel, ::SolidMassCons)

    return solid_diffusion_discretization_number(model.system)
    
end

@jutul_secondary(
    function update_vocp!(Ocp,
                          tv::Ocp,
                          model:: SimulationModel{<:Any, ActiveMaterial{P2Ddiscretization}, <:Any, <:Any},
                          Cs,
                          ix
                          )
        ocp_func = model.system.params[:ocp_func]
        cmax     = model.system.params[:maximum_concentration]
        refT = 298.15
        for cell in ix
            @inbounds Ocp[cell] = ocp_func(refT, Cs[cell], cmax)
        end
    end
)

@jutul_secondary(
    function update_cSurface!(Cs,
                              cs_def::Cs,
                              model::SimulationModel{<:Any, ActiveMaterial{P2Ddiscretization}, <:Any, <:Any},
                              Cp,
                              ix
                              )
        N = model.system.discretization[:N]
        for cell in ix
            @inbounds Cs[cell] = Cp[N, cell]
        end
    end
)

@jutul_secondary(
    function update_diffusion!(DiffusionCoef                                            ,
                               tv::DiffusionCoef                                        ,
                               model::SimulationModel{<:Any, ActiveMaterial{P2Ddiscretization}, <:Any, <:Any},
                               Cp                                                       ,
                               ix
                               )
        diff_func = model.system.params[:diffusion_coef_func]
        refT = 298.15
        for cell in ix
            @inbounds @views DiffusionCoef[cell] = diff_func(refT, Cp[:, cell])
        end
    end
)

@jutul_secondary(
    function update_reaction_rate!(ReactionRateConst                                                        ,
                                   tv::ReactionRateConst                                    ,
                                   model::SimulationModel{<:Any, ActiveMaterial{P2Ddiscretization}, <:Any, <:Any},
                                   Cs                                                       ,
                                   ix
                                   )
        rate_func = model.system.params[:reaction_rate_constant_func]
        refT = 298.15
        for cell in ix
            @inbounds ReactionRateConst[cell] = rate_func(refT, Cs[cell])
        end
    end
)

@jutul_secondary(
    function update_solid_diffusion_flux!(SolidDiffFlux,
                                          tv::SolidDiffFlux,
                                          model::SimulationModel{<:Any, ActiveMaterial{P2Ddiscretization}, <:Any, <:Any},
                                          Cp,
                                          DiffusionCoef,
                                          ix)
    s = model.system
    for cell in ix
        @inbounds @views update_solid_flux!(SolidDiffFlux[:, cell], Cp[:, cell], DiffusionCoef[cell], s)
    end
end
)


function update_solid_flux!(flux, Cp, D, system::ActiveMaterial{P2Ddiscretization})
    # compute lithium flux in particle, using harmonic averaging. At the moment D has a constant value within particle
    # but this is going to change.
    
    disc = system.discretization
    N    = disc[:N]
    A    = disc[:A]
    vols = disc[:vols]
    
    for i = 1 : (N - 1)

        T1 = A[i]*D
        T2 = A[i + 1]*D
        T  = 1/(1/T1 + 1/T2)
        
        flux[i] = -T*(Cp[i + 1] - Cp[i])
        
    end

end


function Jutul.update_equation_in_entity!(eq_buf           ,
                                          self_cell        ,
                                          state            ,
                                          state0           ,
                                          eq::SolidMassCons,
                                          model            ,
                                          dt               ,
                                          ldisc = Nothing)
    
    disc  = model.system.discretization
    N    = disc[:N]
    vols = disc[:vols]
    div  = disc[:div]
    
    Cp   = state.Cp[:, self_cell]
    Cp0  = state0.Cp[:, self_cell]
    flux = state.SolidDiffFlux[:, self_cell]
    
    for i = 1 : N
        eq_buf[i] = vols[i]*(Cp[i] - Cp0[i])/dt
    end

    for k = 1 : length(div)
        i, j, sgn = div[k]
        eq_buf[i] += sgn*flux[j]
    end

end

#####################################################
## We setup the case with full no particle diffusion
#####################################################

function select_primary_variables!(S,
                                   system::ActiveMaterial{NoParticleDiffusion},
                                   model::SimulationModel
                                   )
    S[:Phi] = Phi()
    S[:C]   = C()
    
end

function select_secondary_variables!(S,
                                     system::ActiveMaterial{NoParticleDiffusion},
                                     model::SimulationModel
                                     )
    
    S[:Charge]            = Charge()
    S[:Mass]              = Mass()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    
end

function select_equations!(eqs,
                           system::ActiveMaterial{NoParticleDiffusion},
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)
    
end

@jutul_secondary(
    function update_vocp!(Ocp ,
                          tv::Ocp ,
                          model::M,
                          C       ,
                          ix
                          ) where {M <: SimulationModel{<:Any, ActiveMaterial{NoParticleDiffusion}, <:Any, <:Any}}
        
        ocp_func = model.system.params[:ocp_func]
        cmax     = model.system.params[:maximum_concentration]
        refT     = 298.15
        
        for cell in ix
            @inbounds Ocp[cell] = ocp_func(refT, C[cell], cmax)
        end
    end
)

@jutul_secondary(
    function update_diffusion!(DiffusionCoef    ,
                               tv::DiffusionCoef,
                               model::SimulationModel{<:Any, ActiveMaterial{NoParticleDiffusion}, <:Any, <:Any},
                               C                ,
                               ix
                               )
        diff_func = model.system.params[:diffusion_coef_func]
        refT = 298.15
        for cell in ix
            @inbounds @views DiffusionCoef[cell] = diff_func(refT, C[cell], s)
        end
    end
)

@jutul_secondary(
    function update_reaction_rate!(ReactionRateConst    ,
                                   tv::ReactionRateConst,
                                   model::SimulationModel{<:Any, ActiveMaterial{NoParticleDiffusion}, <:Any, <:Any},
                                   C                    ,
                                   ix
                                   )
        rate_func = model.system.params[:reaction_rate_constant_func]
        refT = 298.15
        for i in ix
            @inbounds ReactionRateConst[i] = rate_func(refT, C[i])
        end
    end
)


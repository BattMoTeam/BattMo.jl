export ActiveMaterial, ActiveMaterialModel, SolidMassCons, NoParticleDiffusion


abstract type ActiveMaterial <: ElectroChemicalComponent end
abstract type NoParticleDiffusion <: ActiveMaterial end

struct Ocp               <: ScalarVariable  end
struct DiffusionCoef     <: ScalarVariable  end
struct ReactionRateConst <: ScalarVariable  end
struct Cp                <: VectorVariables end # particle concentrations in p2d model
struct Cs                <: ScalarVariable  end # surface variable in p2d model
struct SolidDiffFlux     <: VectorVariables end # flux in P2D model

struct SolidMassCons{T} <: JutulEquation
    discretization::T
end

const ActiveMaterialModel = SimulationModel{O, S} where {O<:JutulDomain, S<:ActiveMaterial}

function select_minimum_output_variables!(out                   ,
                                          system::ActiveMaterial,
                                          model::SimulationModel
                                          )
    push!(out, :Charge)
    push!(out, :Mass)
    push!(out, :Ocp)
    push!(out, :Temperature)
    
end

function select_primary_variables!(S                     ,
                                   system::ActiveMaterial,
                                   model::SimulationModel
                                   )
    S[:Phi] = Phi()
    S[:Cp]  = Cp()
    
end

function select_primary_variables!(S                          ,
                                   system::NoParticleDiffusion,
                                   model::SimulationModel
                                   )
    S[:Phi] = Phi()
    S[:C]   = C()
    
end

degrees_of_freedom_per_entity(model::ActiveMaterialModel, ::Cp) =  solid_diffusion_discretization_number(model.system)
degrees_of_freedom_per_entity(model::ActiveMaterialModel, ::SolidDiffFlux) =  solid_diffusion_discretization_number(model.system) - 1

function select_secondary_variables!(S                          ,
                                     system::NoParticleDiffusion,
                                     model::SimulationModel
                                     )
    
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    
end

function select_secondary_variables!(S                     ,
                                     system::ActiveMaterial,
                                     model::SimulationModel
                                     )
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    S[:Cs]                = Cs()
    S[:DiffusionCoef]     = DiffusionCoef()
    S[:SolidDiffFlux]     = SolidDiffFlux()
    
end

function Jutul.select_parameters!(S                     ,
                                  system::ActiveMaterial,
                                  model::SimulationModel
                                  )
    
    S[:Temperature]  = Temperature()
    S[:Conductivity] = Conductivity()
    S[:Diffusivity]  = Diffusivity()
    
end


function select_equations!(eqs,
                           system::NoParticleDiffusion,
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)
    
end

function select_equations!(eqs,
                           system::ActiveMaterial,
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = SolidMassCons(disc)
    
end


Jutul.number_of_equations_per_entity(model::ActiveMaterialModel, ::SolidMassCons) = solid_diffusion_discretization_number(model.system)

@jutul_secondary(
    function update_vocp!(Ocp,
                          tv::Ocp,
                          model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                          Cs,
                          ix
                          ) where {MaterialType <:ActiveMaterial}
        
        s = model.system
        refT = 298.15
        @inbounds Ocp[cell] = compute_ocp(refT, Cs[cell], s)
        
    end
)


@jutul_secondary(
    function update_vocp!(Ocp,
                          tv::Ocp,
                          model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                          Cs,
                          ix
                          ) where {MaterialType <:NoParticleDiffusion}
        
        s = model.system
        refT = 298.15
        @inbounds Ocp[cell] = compute_ocp(refT, Cs[cell], s)
        
    end
)

@jutul_secondary(
    function update_cSurface!(Cs,
                              cs_def::Cs,
                              model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                              Cp,
                              ix
                              ) where {MaterialType <:ActiveMaterial}
        s = model.system
        N = s[:N]
        for cell in ix
            @inbounds Cs[cell] = Cp[N, cell]
        end
    end
)

@jutul_secondary(
    function update_diffusion!(DiffusionCoef                                            ,
                               tv::DiffusionCoef                                        ,
                               model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                               Cp                                                       ,
                               ix
                               ) where {MaterialType <:ActiveMaterial}
        s = model.system
        refT = 298.15
        for cell in ix
            @inbounds @views DiffusionCoef[cell] = diffusion_rate(refT, Cp[:, cell], s)
        end
    end
)

@jutul_secondary(
    function update_diffusion!(DiffusionCoef                                            ,
                               tv::DiffusionCoef                                        ,
                               model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                               C                                                        ,
                               ix
                               ) where {MaterialType <:NoParticleDiffusion}
        s = model.system
        refT = 298.15
        for cell in ix
            @inbounds @views DiffusionCoef[cell] = diffusion_rate(refT, C[cell], s)
        end
    end
)


@jutul_secondary(
    function update_reaction_rate!(ReactionRateConst                                                        ,
                                   tv::ReactionRateConst                                    ,
                                   model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                                   Cs                                                       ,
                                   ix
                                   ) where {MaterialType <:ActiveMaterial}
        s = model.system
        refT = 298.15
        for i in ix
            @inbounds ReactionRateConst[i] = reaction_rate_const(refT, Cs[i], s)
        end
    end
)

@jutul_secondary(
    function update_reaction_rate!(ReactionRateConst                                                        ,
                                   tv::ReactionRateConst                                    ,
                                   model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                                   C                                                        ,
                                   ix
                                   ) where {MaterialType <: NoParticleDiffusion}
        s = model.system
        refT = 298.15
        for i in ix
            @inbounds ReactionRateConst[i] = reaction_rate_const(refT, C[i], s)
        end
    end
)



@jutul_secondary(
    function update_solid_diffusion_flux!(SolidDiffFlux,
                                          tv::SolidDiffFlux,
                                          model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                                          Cp,
                                          DiffusionCoef,
                                          ix) where {MaterialType <:ActiveMaterial}
    s = model.system
    for cell in ix
        @inbounds @views update_solid_flux!(SolidDiffFlux[:, cell], Cp[:, cell], DiffusionCoef[cell], s)
    end
end
)


function update_solid_flux!(flux, Cp, D, system::ActiveMaterial)
    # compute lithium flux in particle, using harmonic averaging. At the moment D has a constant value within particle
    # but this is going to change.
    
    N    = system[:N]
    A    = system[:A]
    vols = system[:vols]
    
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
    
    sys  = model.system
    N    = sys[:N]
    vols = sys[:vols]
    div  = sys[:div]
    
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

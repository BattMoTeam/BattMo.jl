export ActiveMaterial, ActiveMaterialModel

abstract type ActiveMaterial <: ElectroChemicalComponent end

struct Ocp               <: ScalarVariable  end
struct Diffusion         <: ScalarVariable  end
struct ReactionRateConst <: ScalarVariable  end
struct Cp                <: VectorVariables end # particle concentrations in p2d model
struct Cs                <: ScalarVariable  end # surface variable in p2d model
struct SolidDiffFlux     <: VectorVariables end # flux in P2D model

struct SolidMassCons     <: JutulEquation   end

const ActiveMaterialModel = SimulationModel{<:Any, <:ActiveMaterial, <:Any, <:Any}


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

degrees_of_freedom_per_entity(model::ActiveMaterialModel, ::Cp) =  solid_diffusion_discretization_number(model.system)
degrees_of_freedom_per_entity(model::ActiveMaterialModel, ::SolidDiffFlux) =  solid_diffusion_discretization_number(model.system) - 1


function select_secondary_variables!(S                     ,
                                     system::ActiveMaterial,
                                     model::SimulationModel
                                     )
    
    S[:Charge]            = Charge()
    S[:Mass]              = Mass()
    S[:Ocp]               = Ocp()
    S[:Cs]                = Cs()
    S[:ReactionRateConst] = ReactionRateConst()
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
                           system::ActiveMaterial,
                           model::SimulationModel
                           )
    
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = SolidMassCons()
    
end

number_of_equations_per_entity(model::ActiveMaterial, ::SolidMassCons) = solid_diffusion_discretization_number(model.system)

@jutul_secondary(
    function update_vocp!(vocp,
                          tv::Ocp,
                          model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                          C,
                          ix
                          ) where {MaterialType <:ActiveMaterial}
        
        s = model.system
        # @tullio vocp[i] = ocp(T[i], C[i], s)
        refT = 298.15
        for cell in ix
            @inbounds vocp[cell] = ocp(refT, C[cell], s)
        end
        
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
        N = s.N
        for cell in ix
            @inbounds Cs[cell] = Cp[N, cell]
        end
    end
)


@jutul_secondary(
    function update_diffusion!(D,
                               tv::Diffusion,
                               model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                               Cp,
                               ix
                               ) where {MaterialType <:ActiveMaterial}
        s = model.system
        refT = 298.15
        for cell in ix
            @inbounds D[cell] = diffusion_rate(refT, Cp[:, cell], s)
        end
    end
)


@jutul_secondary(
    function update_reaction_rate!(R                                                        ,
                                   tv::ReactionRateConst                                    ,
                                   model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                                   Cs                                                       ,
                                   ix
                                   ) where {MaterialType <:ActiveMaterial}
        s = model.system
        refT = 298.15
        for i in ix
            @inbounds R[i] = reaction_rate_const(refT, Cs[i], s)
        end
    end
)

@jutul_secondary(
    function update_solid_diffusion_flux!(flux,
                                          tv::SolidDiffFlux,
                                          model::SimulationModel{<:Any, MaterialType, <:Any, <:Any},
                                          Cp,
                                          D,
                                          ix) where {MaterialType <:ActiveMaterial}
    s = model.system
    for cell in ix
        @inbounds @views update_solid_flux!(flux[:, cell], Cp[:, cell], D, s)
    end
end
)


function update_solid_flux!(flux, Cp, D, system::ActiveMaterial)
    # compute lithium flux in particle, using harmonic averaging. At the moment D has a constant value within particle
    # but this is going to change.
    
    N    = system.N
    A    = system.A
    vols = system.vols
    
    for i = 1 : (N - 1)

        T1 = A[i]*D
        T2 = A[i + 1]*D
        T  = 1/(1/T1 + 1/T2)
        
        flux[i] = -T*(Cp[i + 1] - Cp[i])
        
    end

end


function update_equation_in_entity!(eq_buf                    ,
                                    self_cell                 ,
                                    state                     ,
                                    state0                    ,
                                    eq::SolidMassCons         ,
                                    model::ActiveMaterialModel,
                                    dt                        ,
                                    ldisc)
    
    sys  = model.system
    N    = sys.N
    vols = sys.vols
    div = sys.div
    
    Cp   = state.Cp[:, self_cell]
    Cp0  = state0.Cp[:, self_cell]
    flux = state.flux[:, self_cell]
    
    for i = 1 : N
        eq_buf[i] = vols[i]*(Cp[i] - Cp0[i])/dt
    end

    for k = 1 : length(div)
        i, j, sgn = div[k]
        eq_buf[i] += sgn*flux[j]
    end
    
end

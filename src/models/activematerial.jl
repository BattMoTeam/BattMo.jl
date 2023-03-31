export ActiveMaterial, ACMaterial, ActiveMaterialModel

abstract type ActiveMaterial <: ElectroChemicalComponent end
struct ACMaterial <: ActiveMaterial end
struct Ocp <: ScalarVariable end
struct Diffusion <: ScalarVariable end
struct ReactionRateConst <: ScalarVariable end

const ActiveMaterialModel = SimulationModel{<:Any, <:ActiveMaterial, <:Any, <:Any}
function select_minimum_output_variables!(out,
    system::ActiveMaterial, model::SimulationModel
    )
    push!(out, :Charge)
    push!(out, :Mass)
    push!(out, :Ocp)
    push!(out, :Temperature)
end

function select_primary_variables!(
    S, system::ActiveMaterial, model::SimulationModel
    )
    S[:Phi] = Phi()
    S[:C] = C()
end

function select_secondary_variables!(
    S, system::ActiveMaterial, model::SimulationModel
    )
    S[:Charge] = Charge()
    S[:Mass] = Mass()

    S[:Ocp] = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
end

function Jutul.select_parameters!(S, system::ActiveMaterial, model::SimulationModel)
    S[:Temperature] = Temperature()
    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
end

function select_equations!(
    eqs, system::ActiveMaterial, model::SimulationModel
    )
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation] = ConservationLaw(disc, :Mass)
end

# ? Does this maybe look better ?
@jutul_secondary(
function update_vocp!(
    vocp, tv::Ocp, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C, ix
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    # @tullio vocp[i] = ocp(T[i], C[i], s)
    refT = 298.15
    for i in ix
        @inbounds vocp[i] = ocp(refT, C[i], s)
    end
end
)



@jutul_secondary(
function update_diffusion!(
    vdiffusion, tv::Diffusion, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C, ix
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    refT = 298.15
    for i in ix
        @inbounds vdiffusion[i] = diffusion_rate(refT, C[i], s)
    end
end
)


@jutul_secondary(
function update_reaction_rate!(
    vReactionRateConst, tv::ReactionRateConst, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C, ix
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    refT = 298.15
    for i in ix
        @inbounds vReactionRateConst[i] = reaction_rate_const(refT, C[i], s)
    end
end
)

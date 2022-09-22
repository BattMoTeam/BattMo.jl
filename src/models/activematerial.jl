export ActiveMaterial, ACMaterial, ActiveMaterialModel

abstract type ActiveMaterial <: ElectroChemicalComponent end
struct ACMaterial <: ActiveMaterial end
struct Ocd <: ScalarVariable end
struct Diffusion <: ScalarVariable end
struct ReactionRateConst <: ScalarVariable end

const ActiveMaterialModel = SimulationModel{<:Any, <:ActiveMaterial, <:Any, <:Any}
function select_minimum_output_variables!(out,
    system::ActiveMaterial, model
    )
    push!(out, :Charge)
    push!(out, :Mass)
    push!(out, :Ocd)
    push!(out, :Temperature)
end

function select_primary_variables!(
    S, system::ActiveMaterial, model
    )
    S[:Phi] = Phi()
    S[:C] = C()
end

function select_secondary_variables!(
    S, system::ActiveMaterial, model
    )    
    S[:Charge] = Charge()
    S[:Mass] = Mass()

    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
    S[:Ocd] = Ocd()
    S[:ReactionRateConst] = ReactionRateConst()
end

function Jutul.select_parameters!(S, system::ActiveMaterial, model)
    S[:Temperature] = Temperature()
end

function select_equations!(
    eqs, system::ActiveMaterial, model
    )
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation] = ConservationLaw(disc, :Mass)
end

# ? Does this maybe look better ?
@jutul_secondary(
function update_as_secondary!(
    vocd, tv::Ocd, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    # @tullio vocd[i] = ocd(T[i], C[i], s)
    refT = 298.15
    @tullio vocd[i] = ocd(refT, C[i], s)
end
)



@jutul_secondary(
function update_as_secondary!(
    vdiffusion, tv::Diffusion, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    refT = 298.15
    @tullio vdiffusion[i] = diffusion_rate(refT, C[i], s)
end
)


@jutul_secondary(
function update_as_secondary!(
    vReactionRateConst, tv::ReactionRateConst, model::SimulationModel{<:Any, MaterialType, <:Any, <:Any}, C
    ) where   {MaterialType <:ActiveMaterial}
    s = model.system
    refT = 298.15
    @tullio vReactionRateConst[i] = reaction_rate_const(refT, C[i], s)
end
)

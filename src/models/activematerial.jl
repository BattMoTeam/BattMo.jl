export ActiveMaterial, ACMaterial, ActiveMaterialModel

abstract type ActiveMaterial <: ElectroChemicalComponent end
struct ACMaterial <: ActiveMaterial end
struct Ocd <: ScalarVariable end
struct Diffusion <: ScalarVariable end
struct ReactionRateConst <: ScalarVariable end

const ActiveMaterialModel = SimulationModel{<:Any, <:ActiveMaterial, <:Any, <:Any}
function minimum_output_variables(
    system::ActiveMaterial, primary_variables
    )
    [:Charge, :Mass, :Ocd, :T, :TPkGrad_Phi]
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
    S[:TPkGrad_Phi] = TPkGrad{Phi}()
    S[:TPkGrad_C] = TPkGrad{C}()
    S[:T] = T()
    
    S[:Charge] = Charge()
    S[:Mass] = Mass()

    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
    S[:Ocd] = Ocd()
    S[:ReactionRateConst] = ReactionRateConst()
end

function select_equations!(
    eqs, system::ActiveMaterial, model
    )
    # charge_cons = (arg...; kwarg...) -> Conservation(Charge(), arg...; kwarg...)
    # mass_cons = (arg...; kwarg...) -> Conservation(Mass(), arg...; kwarg...)
    disc = model.domain.discretizations.charge_flow
    T = typeof(disc)
    eqs[:charge_conservation] = Conservation{Charge(), T}(disc)# (charge_cons, 1)
    eqs[:mass_conservation] = Conservation{Mass(), T}(disc)# (mass_cons, 1)
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

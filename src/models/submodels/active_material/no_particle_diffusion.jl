#########################################################################################
# In this module we define methods to handle the AcriveMaterialNoParticleDiffusion model
# 
# File structure:
# - Initiate a Jutul.JutulStorage
# - Create a subclass of Jutul.JutulSystem
# - Initiate a Jutul.SimulationModel
# - Extend functions called by Jutul.SimulationModel
# - Define methods for calculating secondary variables
# - Define methods for calculating face fluxes
#
#########################################################################################

export NoParticleDiffusion

struct NoParticleDiffusion <: SolidDiffusionDiscretization end

const ActiveMaterialNoParticleDiffusion{T} = ActiveMaterial{nothing, NoParticleDiffusion, T}

## Create ActiveMaterial with no solid diffusion
function ActiveMaterialNoParticleDiffusion(params::ActiveMaterialParameters, scalings = Dict())
    discretization = NoParticleDiffusion()
    params = Jutul.convert_to_immutable_storage(params)
    return ActiveMaterialNoParticleDiffusion{NoParticleDiffusion, typeof(params), typeof(scalings)}(params, discretization, scalings)
end

function discretisation_type(system::ActiveMaterialNoParticleDiffusion)
    return :NoParticleDiffusion
end




function Jutul.select_primary_variables!(S,
    system::ActiveMaterialNoParticleDiffusion,
    model::SimulationModel
    )
S[:Phi] = Phi()
S[:C]   = C()

end

function Jutul.select_secondary_variables!(S,
      system::ActiveMaterialNoParticleDiffusion,
      model::SimulationModel
      )

S[:Charge]            = Charge()
S[:Mass]              = Mass()
S[:Ocp]               = Ocp()
S[:ReactionRateConst] = ReactionRateConst()

end

function Jutul.select_parameters!(S,
system::ActiveMaterialNoParticleDiffusion,
model::SimulationModel)

S[:Temperature]  = Temperature()
S[:Conductivity] = Conductivity()
S[:Diffusivity]  = Diffusivity()
S[:VolumeFraction] = VolumeFraction()

if hasentity(model.data_domain, BoundaryDirichletFaces())
S[:BoundaryPhi]  = BoundaryPotential(:Phi)
end

end

function Jutul.select_equations!(eqs,
system::ActiveMaterialNoParticleDiffusion,
model::SimulationModel
)

disc = model.domain.discretizations.charge_flow
eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)

end


function Jutul.select_minimum_output_variables!(out                   ,
           system::ActiveMaterialNoParticleDiffusion,
           model::SimulationModel
           )
push!(out, :Charge)
push!(out, :Mass)
push!(out, :Ocp)
push!(out, :Temperature)

end


@jutul_secondary(
function update_vocp!(Ocp,
tv::Ocp,
model:: SimulationModel{<:Any, ActiveMaterialNoParticleDiffusion{T}, <:Any, <:Any},
C,
ix
) where T

ocp_func = model.system.params[:ocp_func]

cmax = model.system.params[:maximum_concentration]
refT = 298.15

if haskey(model.system.params, :ocp_funcexp)
theta0   = model.system.params[:theta0]
theta100 = model.system.params[:theta100]
end


for cell in ix

if haskey(model.system.params, :ocp_funcexp)

@inbounds Ocp[cell] = ocp_func(C[cell], refT, refT, cmax)

elseif haskey(model.system.params, :ocp_funcdata)

@inbounds Ocp[cell] = ocp_func(C[cell]/cmax)

else

@inbounds Ocp[cell] = ocp_func(C[cell], refT, cmax)

end
end
end
)

@jutul_secondary(
function update_reaction_rate!(ReactionRateConst    ,
    tv::ReactionRateConst,
    model::SimulationModel{<:Any, ActiveMaterialNoParticleDiffusion{T}, <:Any, <:Any},
    C                    ,
    ix
    ) where T
rate_func = model.system.params[:reaction_rate_constant_func]
refT = 298.15
for i in ix
@inbounds ReactionRateConst[i] = rate_func(C[i], refT)
end
end
)


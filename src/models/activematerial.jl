
export ActiveMaterial, ActiveMaterialModel, SolidMassCons, NoParticleDiffusion

## The parameter for the active material are stored in a dictionnary
const ActiveMaterialParameters = JutulStorage

abstract type SolidDiffusionDiscretization end

struct P2Ddiscretization{T} <: SolidDiffusionDiscretization
	data::T
	# At the moment the following keys are included :
	# N::Integer                   # Discretization size for solid diffusion
	# rp::Real                     # Particle radius
	# hT::Vector{Float64}(N + 1)   # vector of coefficients for harmonic average (half-transmissibility for spherical coordinate)
	# v::Vector{Float64}           # vector of volumes (volume of spherical layer)
	# div::Vector{Vector{Float64}} # Helping structure to compute divergence operator for particle diffusion
	# D::Real diffusion coefficient
end

struct NoParticleDiffusion <: SolidDiffusionDiscretization end

abstract type AbstractActiveMaterial{label} <: ElectroChemicalComponent end

activematerial_label(::AbstractActiveMaterial{label}) where label = label

struct ActiveMaterial{label, D, T, Di} <: AbstractActiveMaterial{label} where {D <: SolidDiffusionDiscretization, T <: ActiveMaterialParameters, Di <: AbstractDict}
	params::T
	# At the moment the following keys are include
	# - diffusion_coef_func::F where {F <: Function}
	# - maximum_concentration::Real
	# - n_charge_carriers::Integer
	# - ocp_func::F where {F <: Function}
	# - ocp_funcdata
	# - ocp_funcexp
	# - reaction_rate_constant_func::F where {F <: Function}
	# - theta0::Real
	# - theta100::Real
	# - volume_fraction::Real
	# - volume_fractions::Vector{Real}
	# - volumetric_surface_area::Real
	# - effective_density::Real
	#
	# If SEI layer is present, we have the following in addition
	# - SEIlengthInitial
	# - SEIvoltageDropRef
	# - SEIlengthRef
	# - SEIstoichiometryCoefficient
	# - SEImolarVolume
	# - SEIelectronicDiffusionCoefficient
	# - SEIinterstitialConcentration
	# - SEIionicConductivity

	discretization::D

	scalings::Di

end

const ActiveMaterialP2D{label, D, T, Di} = ActiveMaterial{label, D, T, Di}
const ActiveMaterialNoParticleDiffusion{T} = ActiveMaterial{nothing, NoParticleDiffusion, T}

struct Ocp <: ScalarVariable end
struct DiffusionCoef <: ScalarVariable end
struct ReactionRateConst <: ScalarVariable end
struct Cp <: VectorVariables end # particle concentrations in p2d model
struct Cs <: ScalarVariable end # surface variable in p2d model
struct SolidDiffFlux <: VectorVariables end # flux in P2D model


Jutul.minimum_value(::Cp) = 0.0
Jutul.minimum_value(::Cs) = 0.0

struct SolidMassCons <: JutulEquation end
Jutul.local_discretization(::SolidMassCons, i) = nothing

struct SolidDiffusionBc <: JutulEquation end
Jutul.local_discretization(::SolidDiffusionBc, i) = nothing

const ActiveMaterialModel = SimulationModel{O, S} where {O <: JutulDomain, S <: ActiveMaterial}

## Create ActiveMaterial with full p2d solid diffusion
function ActiveMaterialP2D(params::ActiveMaterialParameters, rp, N, D, scalings = Dict(); label::Union{Nothing, Symbol} = nothing)
	data = setupSolidDiffusionDiscretization(rp, N, D)
	discretization = P2Ddiscretization(data)
	params = convert_to_immutable_storage(params)
	return ActiveMaterialP2D{label, typeof(discretization), typeof(params), typeof(scalings)}(params, discretization, scalings)
end

## Create ActiveMaterial with no solid diffusion
function ActiveMaterialNoParticleDiffusion(params::ActiveMaterialParameters, scalings = Dict())
	discretization = NoParticleDiffusion()
	params = convert_to_immutable_storage(params)
	return ActiveMaterialNoParticleDiffusion{NoParticleDiffusion, typeof(params), typeof(scalings)}(params, discretization, scalings)
end


###########################
# Setup functions for P2D #
###########################

function Base.getindex(disc::P2Ddiscretization, key::Symbol)
	return disc.data[key]
end

function discretisation_type(system::ActiveMaterialP2D)
	return :P2Ddiscretization
end

function discretisation_type(system::ActiveMaterialNoParticleDiffusion)
	return :NoParticleDiffusion
end

function discretisation_type(model::ActiveMaterialModel)
	discretisation_type(model.system)
end

function solid_diffusion_discretization_number(system::ActiveMaterialP2D)
	return system.discretization[:N]
end

function maximum_concentration(system::ActiveMaterial)
	# used in convergence criteria
	return system.params[:maximum_concentration]
end

function setupSolidDiffusionDiscretization(rp, N, D)
	rp, D = promote(rp, D)
	T = typeof(rp)

	N  = Int64(N)

	hT   = zeros(T, N + 1)
	vols = zeros(T, N)

	dr = rp / N
	rc = [dr * (i - 1 / 2) for i ∈ 1:N]
	rf = [dr * i for i ∈ 0:(N+1)]

	for i ∈ 1:N
		vols[i] = 4 * pi / 3 * (rf[i+1]^3 - rf[i]^3)
	end

	for i ∈ 1:N+1
		hT[i] = (4 * pi * rf[i]^2 / (dr / 2))
	end

	div = Vector{Tuple{Int64, Int64, Int64}}(undef, 2 * (N - 1))

	k = 1
	for j ∈ 1:N-1
		div[k] = (j, j, 1)
		k += 1
		div[k] = (j + 1, j, -1)
		k += 1
	end
	hT = SVector(hT...)
	div = SVector(div...)
	vols = SVector(vols...)

	data = Dict(:N    => N,
		:D    => D,
		:rp   => rp,
		:hT   => hT,
		:vols => vols,
		:div  => div,
	)
	# Convert to concrete type
	return NamedTuple(pairs(data))
end

#################################################################################
# setup case with full P2d discretization : variables and equations declaration #
#################################################################################

function Jutul.select_primary_variables!(S,
	system::ActiveMaterialP2D,
	model::SimulationModel,
)
	S[:Phi] = Phi()
	S[:Cp]  = Cp()
	S[:Cs]  = Cs()

end

function Jutul.degrees_of_freedom_per_entity(model::ActiveMaterialModel,
	::Cp)
	return solid_diffusion_discretization_number(model.system)
end

function Jutul.degrees_of_freedom_per_entity(model::ActiveMaterialModel,
	::SolidDiffFlux)
	return solid_diffusion_discretization_number(model.system) - 1
end

function Jutul.select_parameters!(S,
	system::ActiveMaterialP2D,
	model::SimulationModel)

	S[:Temperature]    = Temperature()
	S[:Conductivity]   = Conductivity()
	S[:VolumeFraction] = VolumeFraction()

	if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
		S[:BoundaryPhi] = BoundaryPotential(:Phi)
	end

end

function Jutul.select_secondary_variables!(S,
	system::ActiveMaterialP2D,
	model::SimulationModel,
)
	S[:Charge]            = Charge()
	S[:Ocp]               = Ocp()
	S[:ReactionRateConst] = ReactionRateConst()
	S[:SolidDiffFlux]     = SolidDiffFlux()

end


function Jutul.select_equations!(eqs,
	system::ActiveMaterialP2D,
	model::SimulationModel,
)

	disc                      = model.domain.discretizations.charge_flow
	eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
	eqs[:mass_conservation]   = SolidMassCons()
	eqs[:solid_diffusion_bc]  = SolidDiffusionBc()

end




# Jutul.number_of_equations_per_entity(model::ActiveMaterialModel, ::SolidDiffusionBc) = 1

function Jutul.number_of_equations_per_entity(model::ActiveMaterialModel, ::SolidMassCons)

	return solid_diffusion_discretization_number(model.system)

end

function Jutul.select_minimum_output_variables!(out,
	system::ActiveMaterialP2D,
	model::SimulationModel)
	push!(out, :Charge)
	push!(out, :Ocp)
	push!(out, :Temperature)

end


##############################
# Update secondary variables #
##############################

@jutul_secondary(
	function update_vocp!(Ocp,
		tv::Ocp,
		model::SimulationModel{<:Any, ActiveMaterialP2D{label, D, T, Di}, <:Any, <:Any},
		Cs,
		ix,
	) where {label, D, T, Di}

		ocp_func = model.system.params[:ocp_func]

		cmax = model.system.params[:maximum_concentration]
		refT = 298.15

		if Jutul.haskey(model.system.params, :ocp_funcexp)
			theta0   = model.system.params[:theta0]
			theta100 = model.system.params[:theta100]
		end


		for cell in ix

			if Jutul.haskey(model.system.params, :ocp_funcexp)

				@inbounds Ocp[cell] = ocp_func(Cs[cell], refT, refT, cmax)

			elseif Jutul.haskey(model.system.params, :ocp_funcdata)

				@inbounds Ocp[cell] = ocp_func(Cs[cell] / cmax)

			else

				@inbounds Ocp[cell] = ocp_func(Cs[cell], refT, cmax)

			end
		end
	end
)

@jutul_secondary(
	function update_reaction_rate!(ReactionRateConst,
		tv::ReactionRateConst,
		model::SimulationModel{<:Any, ActiveMaterialP2D{label, D, T, Di}, <:Any, <:Any},
		Cs,
		ix) where {label, D, T, Di}
		rate_func = model.system.params[:reaction_rate_constant_func]
		refT = 298.15
		for cell in ix
			@inbounds ReactionRateConst[cell] = rate_func(Cs[cell], refT)
		end
	end
)

@jutul_secondary(
	function update_solid_diffusion_flux!(SolidDiffFlux,
		tv::SolidDiffFlux,
		model::SimulationModel{<:Any, ActiveMaterialP2D{label, D, T, Di}, <:Any, <:Any},
		Cp,
		ix) where {label, D, T, Di}
		s = model.system
		for cell in ix
			@inbounds @views update_solid_flux!(SolidDiffFlux[:, cell], Cp[:, cell], s)
		end
	end
)


function update_solid_flux!(flux, Cp, system::ActiveMaterialP2D)
	# compute lithium flux in particle, using harmonic averaging. At the moment D has a constant value within particle
	# but this is going to change.

	disc = system.discretization
	N    = disc[:N]
	hT   = disc[:hT]
	D    = disc[:D]

	@inline globFace(i::Int64) = i + 1

	for i ∈ 1:(N-1)
		# At the moment D is equal in the whole domain, but it will be changed later
		T1 = hT[globFace(i)] * D
		T2 = hT[globFace(i)] * D
		T  = 1 / (1 / T1 + 1 / T2)

		flux[i] = -T * (Cp[i+1] - Cp[i])

	end

end

########################################
# update equations for solid diffusion #
########################################

function Jutul.update_equation_in_entity!(eq_buf,
	self_cell,
	state,
	state0,
	eq::SolidMassCons,
	model,
	dt,
	ldisc = Nothing)

	disc = model.system.discretization
	N = length(eq_buf)
	hT = disc[:hT]
	vols = disc[:vols]
	div = disc[:div]
	D = disc[:D]

	Cp   = @views state.Cp[:, self_cell]
	Cp0  = @views state0.Cp[:, self_cell]
	flux = @views state.SolidDiffFlux[:, self_cell]
	Cs   = state.Cs[self_cell]

	for i ∈ 1:N
		eq_buf[i] = vols[i] * (Cp[i] - Cp0[i]) / dt
	end

	for k ∈ 1:length(div)
		i, j, sgn = div[k]
		eq_buf[i] += sgn * flux[j]
	end

	eq_buf[N] += hT[N+1] * D * (Cp[N] - Cs)

end


function Jutul.update_equation_in_entity!(eq_buf,
	self_cell,
	state,
	state0,
	eq::SolidDiffusionBc,
	model,
	dt,
	ldisc = Nothing)

	disc = model.system.discretization
	N = disc[:N]
	hT = disc[:hT]
	D = disc[:D]

	Cp = state.Cp[N, self_cell]
	Cs = state.Cs[self_cell]

	eq_buf[] = hT[N+1] * D * (Cp - Cs)

end


#####################################################
# We setup the case with full no particle diffusion #
#####################################################


function Jutul.select_primary_variables!(S,
	system::ActiveMaterialNoParticleDiffusion,
	model::SimulationModel,
)
	S[:Phi] = Phi()
	S[:C]   = C()

end

function Jutul.select_secondary_variables!(S,
	system::ActiveMaterialNoParticleDiffusion,
	model::SimulationModel,
)

	S[:Charge]            = Charge()
	S[:Mass]              = Mass()
	S[:Ocp]               = Ocp()
	S[:ReactionRateConst] = ReactionRateConst()

end

function Jutul.select_parameters!(S,
	system::ActiveMaterialNoParticleDiffusion,
	model::SimulationModel)

	S[:Temperature] = Temperature()
	S[:Conductivity] = Conductivity()
	S[:Diffusivity] = Diffusivity()
	S[:VolumeFraction] = VolumeFraction()

	if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
		S[:BoundaryPhi] = BoundaryPotential(:Phi)
	end

end

function Jutul.select_equations!(eqs,
	system::ActiveMaterialNoParticleDiffusion,
	model::SimulationModel,
)

	disc                      = model.domain.discretizations.charge_flow
	eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
	eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)

end


function Jutul.select_minimum_output_variables!(out,
	system::ActiveMaterialNoParticleDiffusion,
	model::SimulationModel,
)
	push!(out, :Charge)
	push!(out, :Mass)
	push!(out, :Ocp)
	push!(out, :Temperature)

end



# @jutul_secondary(
#     function update_vocp!(Ocp ,
#                           tv::Ocp ,
#                           model::SimulationModel{<:Any, ActiveMaterialNoParticleDiffusion{T}, <:Any, <:Any},
#                           C       ,
#                           ix
#                           ) where T

#         ocp_func = model.system.params[:ocp_func]
#         cmax     = model.system.params[:maximum_concentration]
#         refT     = 298.15
#         ocp_eq   = model.system.params[:ocp_eq]
#         global ocp_ex = ocp_eq
#         for cell in ix
#             ################### Lorena #############
#             global c = Cs[cell]
#             @inbounds Ocp[cell] = ocp_func(ocp_eq,Cs[cell], refT, cmax)
#             #@inbounds Ocp[cell] = @evaluate_ocp_function(ocp_eq , Cs[cell], refT, cmax)
#             ########################################
#             #@inbounds Ocp[cell] = ocp_func(C[cell], refT, cmax)
#         end
#     end
# )

@jutul_secondary(
	function update_vocp!(Ocp,
		tv::Ocp,
		model::SimulationModel{<:Any, ActiveMaterialNoParticleDiffusion{T}, <:Any, <:Any},
		C,
		ix,
	) where T

		ocp_func = model.system.params[:ocp_func]

		cmax = model.system.params[:maximum_concentration]
		refT = 298.15

		if Jutul.haskey(model.system.params, :ocp_funcexp)
			theta0   = model.system.params[:theta0]
			theta100 = model.system.params[:theta100]
		end


		for cell in ix

			if Jutul.haskey(model.system.params, :ocp_funcexp)

				@inbounds Ocp[cell] = ocp_func(C[cell], refT, refT, cmax)

			elseif Jutul.haskey(model.system.params, :ocp_funcdata)

				@inbounds Ocp[cell] = ocp_func(C[cell] / cmax)

			else

				@inbounds Ocp[cell] = ocp_func(C[cell], refT, cmax)

			end
		end
	end
)

@jutul_secondary(
	function update_reaction_rate!(ReactionRateConst,
		tv::ReactionRateConst,
		model::SimulationModel{<:Any, ActiveMaterialNoParticleDiffusion{T}, <:Any, <:Any},
		C,
		ix,
	) where T
		rate_func = model.system.params[:reaction_rate_constant_func]
		refT = 298.15
		for i in ix
			@inbounds ReactionRateConst[i] = rate_func(C[i], refT)
		end
	end
)


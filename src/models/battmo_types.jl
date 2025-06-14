export BattMoSystem, CurrentCollector
export vonNeumannBC, DirichletBC, BoundaryCondition, MinimalECTPFAGrid
export ChargeFlow, BoundaryPotential, BoundaryCurrent
export Phi, C, Temperature, Charge, Mass
export BCCurrent
export TPFAInterfaceFluxCT, ButlerVolmerActmatToElyteCT, ButlerVolmerElyteToActmatCT, ButlerVolmerInterfaceFluxCT
export BoundaryDirichletFaces

abstract type BattMoSystem <: JutulSystem end
# Alias for a general electro-chemical model

const BattMoModel = SimulationModel{<:Any, <:BattMoSystem, <:Any, <:Any}

struct BoundaryDirichletFaces <: JutulEntity end

function Base.getindex(system::BattMoSystem, key::Symbol)
	return system.params[key]
end

abstract type BattMoGrid <: JutulMesh end

# Potential variables

abstract type Potential <: ScalarVariable end
struct Phi <: Potential end

# minimum_value(::Phi) = -10
# maximum_value(::Phi) = 10
# absolute_increment_limit(::Phi) = 0.

struct C <: Potential end
Jutul.minimum_value(::C) = 0.0
# maximum_value(::C)   = 10000
# absolute_increment_limit(::C) = 500
# relative_increment_limit(::C) = 0.1

struct Temperature <: Potential end
struct BruggemanCoefficient <: ScalarVariable end

Jutul.default_value(model, ::BruggemanCoefficient) = 1.5

struct Conductivity <: ScalarVariable end
struct Diffusivity <: ScalarVariable end

# Jutul.variable_scale(::Diffusivity) = 1e-10

# Accumulation variables

struct Charge <: ScalarVariable end
struct Mass <: ScalarVariable end
struct Energy <: ScalarVariable end

# Boundary variables

const BCCurrent = Dict(
	:Charge => :BCCharge,
	:Mass   => :BCMass,
	:Energy => :BCCurrent,
)

struct BoundaryPotential{label} <: ScalarVariable
	function BoundaryPotential(label::Symbol)
		return new{label}()
	end
end

Jutul.associated_entity(::BoundaryPotential) = BoundaryDirichletFaces()

struct BoundaryCurrent{label, C} <: ScalarVariable
	cells::C
	function BoundaryCurrent(cells::C, label::Symbol) where C
		new{label, C}(cells)
	end
end

Jutul.associated_entity(::BoundaryCurrent) = BoundaryDirichletFaces()

struct MinimalECTPFAGrid{V, N, B, BT, M} <: BattMoGrid
	"""
	Simple grid for a electro chemical component
	"""
	volumes::V
	neighborship::N
	boundary_cells::B # indices of the boundary cells (some can can be repeated if a cell has two boundary faces). Same length as boundary_hfT.
	boundary_hfT::BT # Boundary half face transmissibilities
	P::M # Tensor to map from cells to faces
	S::M # Tensor map cell vector to cell scalar
	vol_frac::V
	trans::V
	function MinimalECTPFAGrid(pv, N, T; bc_cells = [], bc_hfT = [], P = [], S = [], vf = [])
		nc = length(pv)
		pv::AbstractVector
		@assert size(N, 1) == 2
		if length(N) > 0
			@assert minimum(N) > 0
			@assert maximum(N) <= nc
		end
		@assert all(pv .> 0)
		@assert size(bc_cells) == size(bc_hfT)
		if isempty(vf)
			vf = 1
		end
		if length(vf) != nc
			vf = vf * ones(nc)
		end
		return new{typeof(pv), typeof(N), typeof(bc_cells), typeof(bc_hfT), typeof(P)}(pv, N, bc_cells, bc_hfT, P, S, vf, T)
	end
end

function Jutul.number_of_cells(G::MinimalECTPFAGrid)
	return length(G.volumes)
end

Base.show(io::IO, g::MinimalECTPFAGrid) = print(io, "MinimalECTPFAGrid ($(number_of_cells(g)) cells, $(number_of_faces(g)) faces)")
################
# Constructors #
################

struct TPFAInterfaceFluxCT{T, F} <: AdditiveCrossTerm
	target_cells::T
	source_cells::T
	trans::F
	function TPFAInterfaceFluxCT(target::T, source::T, trans::F) where {T, F}
		new{T, F}(target, source, trans)
	end
end


export AccumulatorInterfaceFluxCT
struct AccumulatorInterfaceFluxCT{T, F} <: AdditiveCrossTerm
	target_cell::Integer
	source_cells::T
	trans::F
	function AccumulatorInterfaceFluxCT(target::Integer, source::T, trans::F) where {T, F}
		new{T, F}(target, source, trans)
	end
end

struct ButlerVolmerActmatToElyteCT{T} <: AdditiveCrossTerm
	target_cells::T
	source_cells::T
end

struct ButlerVolmerElyteToActmatCT{T} <: AdditiveCrossTerm
	target_cells::T
	source_cells::T
end

## used in no particle diffusion model
struct ButlerVolmerInterfaceFluxCT{T} <: AdditiveCrossTerm
	target_cells::T
	source_cells::T
end

## Transmissibilities
function data_domain_helper(d::DataDomain, k::Symbol)
	r = physical_representation(d)
	if r isa DataDomain
		d = r
	end
	return d[k]
end

struct ECTransmissibilities <: ScalarVariable end
Jutul.variable_scale(::ECTransmissibilities) = 1e-10
Jutul.associated_entity(::ECTransmissibilities) = Faces()

function Jutul.default_parameter_values(d::DataDomain, model::SimulationModel{O, S, F, C}, ::ECTransmissibilities, symb) where {G <: MinimalECTPFAGrid, D, E, M, O <: DiscretizedDomain{G, D, E, M}, S, F, C}

	repG = physical_representation(model)
	return repG.trans

end

function Jutul.default_parameter_values(d::DataDomain, model, ::ECTransmissibilities, symb)

	return data_domain_helper(d, :trans)

end

## Volume
struct Volume <: ScalarVariable end
Jutul.associated_entity(::Volume) = Cells()

function Jutul.default_parameter_values(d::DataDomain, model::SimulationModel{O, S, F, C}, ::Volume, symb) where {G <: MinimalECTPFAGrid, D, E, M, O <: DiscretizedDomain{G, D, E, M}, S, F, C}

	repG = physical_representation(model)
	return repG.volumes

end

function Jutul.default_parameter_values(d::DataDomain, model, ::Volume, symb)
	return data_domain_helper(d, :volumes)
end

Jutul.minimum_value(::Volume) = eps()

## Volume fraction
struct VolumeFraction <: ScalarVariable end
Jutul.associated_entity(::VolumeFraction) = Cells()

function Jutul.default_parameter_values(d::DataDomain, model::SimulationModel{O, S, F, C}, ::VolumeFraction, symb) where {G <: MinimalECTPFAGrid, D, E, M, O <: DiscretizedDomain{G, D, E, M}, S, F, C}

	repG = physical_representation(model)
	return repG.vol_frac

end

function Jutul.default_parameter_values(d::DataDomain, model, ::VolumeFraction, symb)
	return data_domain_helper(d, :volumeFraction)
end

Jutul.minimum_value(::VolumeFraction) = eps(Float64)

mutable struct VariablePrecond # mutable needed?
	precond::Any
	var::Any
	eq::Any
	models::Any
	data::Any

end

function VariablePrecond(precond, var, eq, models)
	return VariablePrecond(precond, var, eq, models, nothing)
end

mutable struct BatteryGeneralPreconditioner <: JutulPreconditioner
	varpreconds::Any
	g_varprecond::Any
	params::Any
	data::Any
end

function BatteryGeneralPreconditioner(varpreconds, g_precond, params)
	return BatteryGeneralPreconditioner(varpreconds, g_precond, params, nothing)
end

function BatteryGeneralPreconditioner()
	varpreconds = Vector{VariablePrecond}()
	push!(varpreconds, VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Phi, :charge_conservation, nothing))
	g_varprecond = VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)
	params = Dict()
	params["method"] = "block"
	params["post_solve_control"] = true
	params["pre_solve_control"] = true
	return BatteryGeneralPreconditioner(varpreconds, g_varprecond, params, nothing)
end


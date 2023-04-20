using Jutul

export ElectroChemicalComponent, CurrentCollector, Electectrolyte, TestElyte
export vonNeumannBC, DirichletBC, BoundaryCondition, MinimalECTPFAGrid
export ChargeFlow, BoundaryPotential, BoundaryCurrent
export Phi, C, Temperature, Charge, Mass, Energy, KGrad
export BCCurrent
export TPFAInterfaceFluxCT, ButlerVolmerActmatToElyteCT, ButlerVolmerElyteToActmatCT, ButlerVolmerInterfaceFluxCT

struct BoundaryFaces <: Jutul.JutulEntity end

abstract type ElectroChemicalComponent <: JutulSystem end
# Alias for a genereal Electro Chemical Model
const ECModel = SimulationModel{<:Any, <:ElectroChemicalComponent, <:Any, <:Any}

abstract type ElectroChemicalGrid <: JutulMesh end

# Potentials
abstract type Potential <: ScalarVariable end
struct Phi <: Potential end
struct C <: Potential end
struct Temperature <: Potential end

struct Conductivity <: ScalarVariable end
struct Diffusivity <: ScalarVariable end

Jutul.variable_scale(::Diffusivity) = 1e-10

struct ThermalConductivity <: ScalarVariable end

# Accumulation variables
abstract type Conserved <: ScalarVariable end
struct Charge <: Conserved end
struct Mass <: Conserved end
struct Energy <: Conserved end

# Currents corresponding to a accumulation type
const BCCurrent = Dict(
    :Charge => :BCCharge,
    :Mass   => :BCMass,
    :Energy => :BCEnergy,
)

abstract type KGrad{T} <: ScalarVariable end
Jutul.associated_entity(::KGrad) = Faces()

struct TPkGrad{T} <: KGrad{T} end

struct BoundaryPotential{label} <: ScalarVariable
    function BoundaryPotential(label::Symbol)
        return new{label}()
    end
end

Jutul.associated_entity(::BoundaryPotential) = BoundaryFaces()

struct BoundaryCurrent{label, C} <: ScalarVariable 
    cells::C
    function BoundaryCurrent(cells::C, label::Symbol) where C
        new{label, C}(cells)
    end
end

Jutul.associated_entity(::BoundaryCurrent) = BoundaryFaces()


abstract type Current <: ScalarVariable end
Jutul.associated_entity(::Current) = Faces()

#struct TotalCurrent <: Current end
#struct ChargeCarrierFlux <: Current end
#struct EnergyFlux <: Current end

function number_of_entities(model, pv::Current)
    return 2*count_entities(model.domain, Faces())
end

struct MinimalECTPFAGrid{V, N, B, BT, M} <: ElectroChemicalGrid
    """
    Simple grid for a electro chemical component
    """
    volumes::V
    neighborship::N
    boundary_cells::B
    boundary_T_hf::BT
    P::M # Tensor to map from cells to faces
    S::M # Tensor map cell vector to cell scalar
    vol_frac::V
    trans::V
    function MinimalECTPFAGrid(pv, N, T; bc=[], T_hf=[], P=[], S=[], vf=[])
        nc = length(pv)
        pv::AbstractVector
        @assert size(N, 1) == 2
        if length(N) > 0
            @assert minimum(N) > 0
            @assert maximum(N) <= nc
        end
        @assert all(pv .> 0)
        @assert size(bc) == size(T_hf)
        if length(vf) != nc
            vf = ones(nc)
        end
        return new{typeof(pv), typeof(N), typeof(bc), typeof(T_hf), typeof(P)}(pv, N, bc, T_hf, P, S, vf, T)
    end
end

number_of_cells(G::MinimalECTPFAGrid) = length(G.volumes)

Base.show(io::IO, g::MinimalECTPFAGrid) = print(io, "MinimalECTPFAGrid ($(number_of_cells(g)) cells, $(number_of_faces(g)) faces)")

import Jutul: FlowDiscretization

################
# Constructors #
################

struct TPFAInterfaceFluxCT{T,F} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
    trans::F
    is_symmetric::Bool
    function TPFAInterfaceFluxCT(target::T, source::T, trans::F; symmetric = true) where {T, F}
        new{T, F}(target, source, trans, symmetric)
    end
end

Jutul.has_symmetry(ct::TPFAInterfaceFluxCT) = ct.is_symmetric

export AccumulatorInterfaceFluxCT
struct AccumulatorInterfaceFluxCT{T,F} <: Jutul.AdditiveCrossTerm
    target_cell::Integer
    source_cells::T
    trans::F
    function AccumulatorInterfaceFluxCT(target::Integer, source::T, trans::F) where {T, F}
        new{T, F}(target, source, trans)
    end
end

struct ButlerVolmerActmatToElyteCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

struct ButlerVolmerElyteToActmatCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

## used in no particle diffusion model
struct ButlerVolmerInterfaceFluxCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

## Transmissibilities
struct ECTransmissibilities <: ScalarVariable end
Jutul.variable_scale(::ECTransmissibilities) = 1e-10
Jutul.associated_entity(::ECTransmissibilities) = Faces()
function Jutul.default_parameter_values(data_domain, model, ::ECTransmissibilities, symb)

    repG = physical_representation(model)
    return repG.trans

end

## Volume
struct Volume <: ScalarVariable end
Jutul.associated_entity(::Volume) = Cells()
function Jutul.default_parameter_values(data_domain, model, ::Volume, symb)

    repG = physical_representation(model)
    return repG.volumes
    
end
Jutul.minimum_value(::Volume) = eps()

## Volume fraction
struct VolumeFraction <: ScalarVariable end
Jutul.associated_entity(::VolumeFraction) = Cells()
function Jutul.default_parameter_values(data_domain, model, ::VolumeFraction, symb)

    repG = physical_representation(model)
    return repG.vol_frac
    
end
Jutul.minimum_value(::VolumeFraction) = eps(Float64)

mutable struct BatteryCPhiPreconditioner <: JutulPreconditioner
    c_precond
    p_precond
    data
end

function BatteryCPhiPreconditioner(c_precond = AMGPreconditioner(), p_precond = AMGPreconditioner())
    return BatteryCPhiPreconditioner(c_precond, p_precond, nothing)
end

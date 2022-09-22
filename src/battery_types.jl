using Jutul
export ElectroChemicalComponent, CurrentCollector, Electectrolyte, TestElyte
export vonNeumannBC, DirichletBC, BoundaryCondition, MinimalECTPFAGrid
export ChargeFlow, BoundaryPotential, BoundaryCurrent
export Phi, C, T, Charge, Mass, Energy, KGrad
export BOUNDARY_CURRENT
export TPFAInterfaceFluxCT,ButlerVolmerInterfaceFluxCT
###########
# Classes #
###########

struct BoundaryFaces <: Jutul.JutulEntity end

abstract type ElectroChemicalComponent <: JutulSystem end
# Alias for a genereal Electro Chemical Model
const ECModel = SimulationModel{<:Any, <:ElectroChemicalComponent, <:Any, <:Any}

abstract type ElectroChemicalGrid <: AbstractJutulMesh end

# Potentials
abstract type Potential <: ScalarVariable end
struct Phi <: Potential end
struct C <: Potential end
struct T <: Potential end

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
const BOUNDARY_CURRENT = Dict(
    :Charge => :BCCharge,
    :Mass   => :BCMass,
    :Energy => :BCEnergy,
)

# Represents k∇T, where k is a tensor, T a potential
abstract type KGrad{T} <: ScalarVariable end
Jutul.associated_entity(::KGrad) = Faces()

struct TPkGrad{T} <: KGrad{T} end

# abstract type ECFlow <: FlowType end
# struct ChargeFlow <: ECFlow end


struct BoundaryPotential{T} <: ScalarVariable
    function BoundaryPotential(b_label::Symbol)
        return new{b_label}()
    end
end
Jutul.associated_entity(::BoundaryPotential) = BoundaryFaces()

struct BoundaryCurrent{T, C} <: ScalarVariable 
    cells::C
    function BoundaryCurrent(cells::TC, b_label::Symbol) where TC
        new{b_label, TC}(cells)
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
end

Base.show(io::IO, g::MinimalECTPFAGrid) = print(io, "MinimalECTPFAGrid ($(number_of_cells(g)) cells, $(number_of_faces(g)) faces)")


import Jutul: FlowDiscretization

################
# Constructors #
################

function MinimalECTPFAGrid(pv, N, bc=[], T_hf=[], P=[], S=[], vf=[])
    nc = length(pv)
    pv::AbstractVector
    @assert size(N, 1) == 2
    if length(N) > 0
        @assert minimum(N) > 0
        @assert maximum(N) <= nc
    end
    @assert all(pv .> 0)
    @assert size(bc) == size(T_hf)

    if size(vf) != nc
        vf = ones(nc)
    end

    MinimalECTPFAGrid{typeof(pv), typeof(N), typeof(bc), typeof(T_hf), typeof(P)}(pv, N, bc, T_hf, P, S, vf)
end

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

struct ButlerVolmerInterfaceFluxCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

struct ECTransmissibilities <: ScalarVariable end
Jutul.variable_scale(::ECTransmissibilities) = 1e-10
Jutul.minimum_value(::ECTransmissibilities) = 0.0

Jutul.associated_entity(::ECTransmissibilities) = Faces()
function Jutul.default_values(model, ::ECTransmissibilities)
    d = model.domain
    nf = number_of_faces(d)
    T = zeros(nf)
    conn_data = d.discretizations.charge_flow.conn_data
    for cd in conn_data
        T[cd.face] = cd.T
    end
    @info "" T
    return T
end

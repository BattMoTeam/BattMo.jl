
export DmuDc, ChemCoef, SolidDiffFlux
export Ocp, DiffusionCoef
export ReactionRateConst, Cp, Cs
export ChargeFlow, BoundaryPotential, BoundaryCurrent
export Phi, C, Temperature, Charge, Mass
export BCCurrent
export BoundaryDirichletFaces


struct DmuDc <: ScalarVariable end # derivative of potential with respect to concentration
struct ChemCoef <: ScalarVariable end # coefficient that comes before the DmuDc in the transport eq?

struct Ocp               <: ScalarVariable  end
struct DiffusionCoef     <: ScalarVariable  end
struct ReactionRateConst <: ScalarVariable  end
struct Cp                <: VectorVariables end # particle concentrations in p2d model
struct Cs                <: ScalarVariable  end # surface variable in p2d model
struct SolidDiffFlux     <: VectorVariables end # flux in P2D model


Jutul.minimum_value(::Cp) = 0.0
Jutul.minimum_value(::Cs) = 0.0

# Potential variables

abstract type Potential <: ScalarVariable end
struct Phi <: Potential end

# minimum_value(::Phi) = -10
# maximum_value(::Phi) = 10
# absolute_increment_limit(::Phi) = 0.

struct C <: Potential end
Jutul.minimum_value(::C) = 0.
# maximum_value(::C)   = 10000
# absolute_increment_limit(::C) = 500
# relative_increment_limit(::C) = 0.1

struct Temperature <: Potential end

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
    :Energy => :BCCurrent
)

struct BoundaryPotential{label} <: ScalarVariable
    function BoundaryPotential(label::Symbol)
        return new{label}()
    end
end

struct BoundaryDirichletFaces <: JutulEntity end

Jutul.associated_entity(::BoundaryPotential) = BoundaryDirichletFaces()

struct BoundaryCurrent{label, C} <: ScalarVariable 
    cells::C
    function BoundaryCurrent(cells::C, label::Symbol) where C
        new{label, C}(cells)
    end
end

Jutul.associated_entity(::BoundaryCurrent) = BoundaryDirichletFaces()

export DmuDc, ChemCoef

# export Phi, C, Temperature, Charge, Mass, Conductivity, Diffusivity
# export BoundaryPotential, BoundaryCurrent
# export BCCurrent


struct DmuDc <: ScalarVariable end # derivative of potential with respect to concentration
struct ChemCoef <: ScalarVariable end # coefficient that comes before the DmuDc in the transport eq?



# abstract type Potential <: ScalarVariable end
# struct Phi <: Potential end

# # minimum_value(::Phi) = -10
# # maximum_value(::Phi) = 10
# # absolute_increment_limit(::Phi) = 0.

# struct C <: Potential end
# minimum_value(::C)   = 0.
# # maximum_value(::C)   = 10000
# # absolute_increment_limit(::C) = 500
# # relative_increment_limit(::C) = 0.1

# struct Temperature <: Potential end

# struct Conductivity <: ScalarVariable end
# struct Diffusivity <: ScalarVariable end

# # Jutul.variable_scale(::Diffusivity) = 1e-10

# # Accumulation variables

# struct Charge <: ScalarVariable end
# struct Mass <: ScalarVariable end
# struct Energy <: ScalarVariable end




# # Boundary variables

# const BCCurrent = Dict(
#     :Charge => :BCCharge,
#     :Mass   => :BCMass,
#     :Energy => :BCCurrent
# )

# struct BoundaryPotential{label} <: ScalarVariable
#     function BoundaryPotential(label::Symbol)
#         return new{label}()
#     end
# end

# jt.associated_entity(::BoundaryPotential) = BoundaryDirichletFaces()

# struct BoundaryCurrent{label, C} <: ScalarVariable 
#     cells::C
#     function BoundaryCurrent(cells::C, label::Symbol) where C
#         new{label, C}(cells)
#     end
# end

# jt.associated_entity(::BoundaryCurrent) = BoundaryDirichletFaces()

using Jutul

export CurrentCollector
export vonNeumannBC, DirichletBC, BoundaryCondition, MinimalECTPFAGrid
export ChargeFlow, BoundaryPotential, BoundaryCurrent
export Phi, C, Temperature, Charge, Mass
export BCCurrent
export TPFAInterfaceFluxCT, ButlerVolmerActmatToElyteCT, ButlerVolmerElyteToActmatCT, ButlerVolmerInterfaceFluxCT
export BoundaryDirichletFaces








################
# Constructors #
################

struct TPFAInterfaceFluxCT{T,F} <: AdditiveCrossTerm
    target_cells::T
    source_cells::T
    trans::F
    function TPFAInterfaceFluxCT(target::T, source::T, trans::F) where {T, F}
        new{T, F}(target, source, trans)
    end
end


export AccumulatorInterfaceFluxCT
struct AccumulatorInterfaceFluxCT{T,F} <:AdditiveCrossTerm
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
struct ECTransmissibilities <: ScalarVariable end
Jutul.variable_scale(::ECTransmissibilities) = 1e-10
Jutul.associated_entity(::ECTransmissibilities) = Faces()

function Jutul.default_parameter_values(d::DataDomain, model::SimulationModel{O, S, F, C}, ::ECTransmissibilities, symb) where {G <: MinimalECTPFAGrid, D, E, M, O <: DiscretizedDomain{G, D, E, M}, S, F, C}

    repG = physical_representation(model)
    return repG.trans

end

function Jutul.default_parameter_values(d::DataDomain, model, ::ECTransmissibilities, symb)

    return d.representation[:trans]

end

## Volume
struct Volume <: ScalarVariable end
Jutul.associated_entity(::Volume) = Cells()

function Jutul.default_parameter_values(d::DataDomain, model::SimulationModel{O, S, F, C}, ::Volume, symb) where {G <: MinimalECTPFAGrid, D, E, M, O <: DiscretizedDomain{G, D, E, M}, S, F, C}

    repG = physical_representation(model)
    return repG.volumes
    
end

function Jutul.default_parameter_values(d::DataDomain, model, ::Volume, symb)

    return d.representation[:volumes]
    
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

    return d.representation[:volumeFraction]
    
end


Jutul.minimum_value(::VolumeFraction) = eps(Float64)

mutable struct VariablePrecond # mutable needed?
    precond
    var
    eq
    models
    data
    
end
function VariablePrecond(precond,var,eq,models)
    return VariablePrecond(precond,var,eq,models,nothing)
end

mutable struct BatteryGeneralPreconditioner <: JutulPreconditioner
    varpreconds
    g_varprecond
    params
    data
end



function BatteryGeneralPreconditioner(varpreconds, g_precond, params)
    return BatteryGeneralPreconditioner(varpreconds, g_precond, params, nothing)
end

function BatteryGeneralPreconditioner()
    varpreconds = Vector{VariablePrecond}()
    push!(varpreconds,VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben),:Phi,:charge_conservation, nothing))
    g_varprecond = VariablePrecond(Jutul.ILUZeroPreconditioner(),:Global,:Global,nothing)
    params = Dict()
    params["method"] = "block"
    params["post_solve_control"] = true
    params["pre_solve_control"] = true
    return BatteryGeneralPreconditioner(varpreconds, g_varprecond, params, nothing)
end


mutable struct BatteryCPhiPreconditioner <: JutulPreconditioner
    c_precond
    p_precond
    g_precond
    data
end

function BatteryCPhiPreconditioner(c_precond = Jutul.AMGPreconditioner(:ruge_stuben), 
    p_precond = Jutul.AMGPreconditioner(:ruge_stuben), g_precond = nothing)
    return BatteryCPhiPreconditioner(c_precond, p_precond, g_precond, nothing)
end

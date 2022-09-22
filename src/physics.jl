using Tullio
export half_face_two_point_kgrad


#####################
# Gradient operator #
#####################

@inline function half_face_two_point_kgrad(
    conn_data::NamedTuple, p::AbstractArray, k::AbstractArray
    )
    half_face_two_point_kgrad(
        conn_data.self, conn_data.other, conn_data.T, p, k
        )
end

@inline function harm_av(
    c_self::I, c_other::I, T::R, k::AbstractArray
    ) where {R<:Real, I<:Integer}
    return T * (k[c_self]^-1 + value(k[c_other])^-1)^-1
end

@inline function grad(c_self, c_other, p::AbstractArray)
    return +(p[c_self] - value(p[c_other]))
end

@inline function half_face_two_point_kgrad(
    c_self::I, c_other::I, T::R, phi::AbstractArray, k::AbstractArray
    ) where {R<:Real, I<:Integer}
    k_av = harm_av(c_self, c_other, T, k)
    grad_phi = grad(c_self, c_other, phi)
    return k_av * grad_phi
end

function Jutul.update_half_face_flux!(eq_s::ConservationLawTPFAStorage, law::ConservationLaw, state, model::ECModel, dt, flow::TwoPointPotentialFlowHardCoded)
    f = get_entries(eq_s.half_face_flux_cells)
    internal_flux!(f, model, law, state, flow.conn_data)
end

function internal_flux!(kGrad, model::ECModel, law::ConservationLaw{:Mass, <:Any}, state, conn_data)
    @tullio kGrad[i] = -half_face_two_point_kgrad(conn_data[i], state.C, state.Diffusivity)
end

function internal_flux!(kGrad, model, law::ConservationLaw{:Charge, <:Any}, state, conn_data)
    @tullio kGrad[i] = -half_face_two_point_kgrad(conn_data[i], state.Phi, state.Conductivity)
end

function internal_flux!(kGrad, model::ElectrolyteModel, law::ConservationLaw{:Mass, <:Any}, state, conn_data)
    sys = model.system
    z = sys.z
    t = sys.t
    F = FARADAY_CONST

    @inbounds for i in eachindex(kGrad)
        cd = conn_data[i]
        TPDGrad_C = half_face_two_point_kgrad(cd, state.C, state.Diffusivity)
        TPDGrad_Phi = half_face_two_point_kgrad(cd, state.Phi, state.Conductivity)
        TotalCurrent = -TPDGrad_C - TPDGrad_Phi
        ChargeCarrierFlux = TPDGrad_C + t / (F * z) * TotalCurrent
        kGrad[i] = ChargeCarrierFlux
    end
end

#######################
# Boundary conditions #
#######################
# TODO: Add possibilites for different potentials to have different boundary cells

# Called from uppdate_state_dependents
function Jutul.apply_boundary_conditions!(storage, parameters, model::ECModel)
    equations_storage = storage.equations
    equations = model.equations
    for (eq, eq_s) in zip(values(equations), equations_storage)
        apply_bc_to_equation!(storage, parameters, model, eq, eq_s)
    end
end


function apply_boundary_potential!(
    acc, state, parameters, model, eq::ConservationLaw{:Charge}
    )
    # values
    Phi = state[:Phi]
    BoundaryPhi = state[:BoundaryPhi]
    κ = state[:Conductivity]

    bc = model.domain.grid.boundary_cells
    T_hf = model.domain.grid.boundary_T_hf

    for (i, c) in enumerate(bc)
        @inbounds acc[c] -= - κ[c]*T_hf[i]*(Phi[c] - BoundaryPhi[i])
    end
end

function apply_boundary_potential!(
    acc, state, parameters, model, eq::ConservationLaw{:Mass}
    )
    # values
    C = state[:C]
    BoundaryC = state[:BoundaryC]
    D = state[:Diffusivity]

    # Type
    bc = model.domain.grid.boundary_cells
    T_hf = model.domain.grid.boundary_T_hf

    for (i, c) in enumerate(bc)
        @inbounds acc[c] += - D[c]*T_hf[i]*(C[c] - BoundaryC[i])
    end
end

function apply_boundary_potential!(
    acc, state, parameters, model, eq::ConservationLaw{:Energy}
    )
    # values
    T = state[:T]
    BoundaryT = state[:BoundaryT]
    λ = state[:ThermalConductivity]

    bc = model.domain.grid.boundary_cells
    T_hf = model.domain.grid.boundary_T_hf

    for (i, c) in enumerate(bc)
        @inbounds acc[c] += - λ[c]*T_hf[i]*(T[c] - BoundaryT[i])
    end
end


function apply_bc_to_equation!(storage, parameters, model, eq::ConservationLaw, eq_s)
    acc = get_entries(eq_s.accumulation)
    state = storage.state

    apply_boundary_potential!(acc, state, parameters, model, eq)

    jkey = BOUNDARY_CURRENT[conserved_symbol(eq)]
    if haskey(state, jkey)
        apply_boundary_current!(acc, state, jkey, model, eq)
    end
end

function apply_boundary_current!(acc, state, jkey, model, eq::ConservationLaw)
    J = state[jkey]

    jb = model.secondary_variables[jkey]
    for (i, c) in enumerate(jb.cells)
        @inbounds acc[c] -= J[i]
    end
end

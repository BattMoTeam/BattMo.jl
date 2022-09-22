using Tullio
export half_face_two_point_kgrad


#####################
# Gradient operator #
#####################
@inline harmonic_average(c1, c2, T, k) = @inbounds T * (k[c1]^-1 + k[c2]^-1)^-1
@inline grad(c_self, c_other, p::AbstractArray) = @inbounds +(p[c_self] - p[c_other])

@inline function half_face_two_point_kgrad(
    c_self::I, c_other::I, T::R, phi::AbstractArray, k::AbstractArray
    ) where {R<:Real, I<:Integer}
    k_av = harmonic_average(c_self, c_other, T, k)
    grad_phi = grad(c_self, c_other, phi)
    return k_av * grad_phi
end

function Jutul.compute_tpfa_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model, dt, flow_disc) where T
    @inbounds trans = state.ECTransmissibilities[face]
    q = -half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    return T(q)
end

function Jutul.compute_tpfa_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model, dt, flow_disc) where T
    @inbounds trans = state.ECTransmissibilities[face]
    q = -half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    return T(q)
end

function Jutul.compute_tpfa_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T
    sys = model.system
    z = sys.z
    t = sys.t
    F = FARADAY_CONST
    @inbounds trans = state.ECTransmissibilities[face]
    TPDGrad_C = half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    TPDGrad_Phi = half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)
    TotalCurrent = -TPDGrad_C - TPDGrad_Phi
    ChargeCarrierFlux = TPDGrad_C + t / (F * z) * TotalCurrent
    return T(ChargeCarrierFlux)
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
    BoundaryTemperature = state[:BoundaryTemperature]
    λ = state[:ThermalConductivity]

    bc = model.domain.grid.boundary_cells
    T_hf = model.domain.grid.boundary_T_hf

    for (i, c) in enumerate(bc)
        @inbounds acc[c] += - λ[c]*T_hf[i]*(T[c] - BoundaryTemperature[i])
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

    jb = model.parameters[jkey]
    for (i, c) in enumerate(jb.cells)
        @inbounds acc[c] -= J[i]
    end
end

function Jutul.select_parameters!(prm, D::TwoPointPotentialFlowHardCoded, model::Union{ECModel, SimpleElyteModel})
    prm[:ECTransmissibilities] = ECTransmissibilities()
end

function Jutul.select_parameters!(prm, D::MinimalECTPFAGrid, model::Union{ECModel, SimpleElyteModel})
    prm[:Volume] = Volume()
    prm[:VolumeFraction] = VolumeFraction()
end

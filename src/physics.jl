using Tullio
export half_face_two_point_kgrad


#####################
# Gradient operator #
#####################
@inline function harmonic_average(c1, c2, k)
    
    @inbounds l = k[c1]
    @inbounds r = k[c2]
    
    return 1.0/(1.0/l + 1.0/r)
end

@inline grad(c_self, c_other, p::AbstractArray) = @inbounds +(p[c_self] - p[c_other])

@inline function half_face_two_point_kgrad(c_self::I         ,
                                           c_other::I        ,
                                           T::R              ,
                                           phi::AbstractArray,
                                           k::AbstractArray
                                           ) where {R<:Real, I<:Integer}
    
    k_av = harmonic_average(c_self, c_other, k)
    grad_phi = grad(c_self, c_other, phi)
    
    return T*k_av*grad_phi
    
end

@inline function Jutul.face_flux!(q_i, face, eq::ConservationLaw, state, model::ECModel, dt, flow_disc::PotentialFlow, ldisc)

    # Inner version, for generic flux
    kgrad, upw = ldisc.face_disc(face)
    (; left, right, face_sign) = kgrad
    
    return Jutul.face_flux!(q_i, left, right, face, face_sign, eq, state, model, dt, flow_disc)
    
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.C, state.Diffusivity)
    
    return T(q)
end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.Phi, state.Conductivity)

    return T(q)
    
end

export output_flux

function output_flux(model, state, parameters, eqname = :mass_conservation)

    n   = number_of_faces(model)
    N   = model.domain.representation.neighborship
    out = zeros(n)
    fd  = model.domain.discretizations.charge_flow
    dt  = NaN
    
    state_t = convert_to_immutable_storage(merge(state, parameters))

    if haskey(model.equations, eqname)
        eq = model.equations[eqname]
        for i in eachindex(out)
            l = N[1, i]
            r = N[2, i]
            out[i] = Jutul.face_flux!(1.0, l, r, i, 1, eq, state_t, model, dt, fd)
        end
    else
        @. out = NaN
    end
    return out
end
#######################
# Boundary conditions #
#######################
# TODO: Add possibilites for different potentials to have different boundary cells

# Called from update_state dependents
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

    bc = model.domain.representation.boundary_cells

    if length(bc) > 0
        
        Phi         = state[:Phi]
        BoundaryPhi = state[:BoundaryPhi]
        κ           = state[:Conductivity]

        T_hf = model.domain.representation.boundary_T_hf

        for (i, c) in enumerate(bc)
            @inbounds acc[c] -= - κ[c]*T_hf[i]*(Phi[c] - value(BoundaryPhi[i]))
        end
    end
    
end

function apply_boundary_potential!(
    acc, state, parameters, model, eq::ConservationLaw{:Mass}
    )
    
    bc = model.domain.representation.boundary_cells
    
    if length(bc) > 0
        # values
        C         = state[:C]
        BoundaryC = state[:BoundaryC]
        D         = state[:Diffusivity]

        # Type
        T_hf = model.domain.representation.boundary_T_hf

        for (i, c) in enumerate(bc)
            @inbounds acc[c] += - D[c]*T_hf[i]*(C[c] - value(BoundaryC[i]))
        end
    end
end


function apply_bc_to_equation!(storage, parameters, model, eq::ConservationLaw, eq_s)
    
    acc   = get_diagonal_entries(eq, eq_s)
    state = storage.state

    apply_boundary_potential!(acc, state, parameters, model, eq)

    jkey = BCCurrent[conserved_symbol(eq)]
    if haskey(state, jkey)
        apply_boundary_current!(acc, state, jkey, model, eq)
    end
end

function apply_bc_to_equation!(storage, parameters, model, eq::SolidMassCons, eq_s)
    
end


function apply_boundary_current!(acc, state, jkey, model, eq::ConservationLaw)

    J = state[jkey]

    jb = get_variable(model, jkey)
    for (i, c) in enumerate(jb.cells)
        @inbounds acc[c] -= J[i]
    end
    
end

function Jutul.select_parameters!(prm, D::Union{TwoPointPotentialFlowHardCoded, PotentialFlow}, model::Union{ECModel, SimpleElyteModel})
    
    prm[:ECTransmissibilities] = ECTransmissibilities()
    
end

function Jutul.select_parameters!(prm, D::MinimalECTPFAGrid, model::Union{ECModel, SimpleElyteModel})
    
    prm[:Volume]         = Volume()
    prm[:VolumeFraction] = VolumeFraction()
    
end

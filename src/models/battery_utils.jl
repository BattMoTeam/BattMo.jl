using Jutul

export
    half_face_two_point_kgrad

function declare_entities(G::MinimalECTPFAGrid)
    # cells
    c = (entity = Cells(), count = length(G.volumes))
    # faces
    f = (entity = Faces(), count = size(G.neighborship, 2))
    # boundary faces
    bf = (entity = BoundaryDirichletFaces(), count = length(G.boundary_cells))
    return [c, f, bf]
end

@jutul_secondary function update_ion_mass!(acc           ,
                                           tv::Mass      ,
                                           model         ,
                                           C             ,
                                           Volume        ,
                                           VolumeFraction,
                                           ix)
    for i in ix
        @inbounds acc[i] = C[i] * Volume[i] * VolumeFraction[i]
    end
end

@jutul_secondary function update_as_secondary!(acc       ,
                                               tv::Charge,
                                               model     ,
                                               Phi       ,
                                               ix)
    for i in ix
        @inbounds acc[i] = 0.0
    end
end

#####################
# Gradient operator #
#####################
@inline function harmonic_average(c1, c2, k)
    
    @inbounds l = k[c1]
    @inbounds r = k[c2]
    
    return 2.0/(1.0/l + 1.0/r)
end

@inline grad(c_self, c_other, p::AbstractArray) = @inbounds (p[c_other] - p[c_self])

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

@inline function Jutul.face_flux!(q_i, face, eq::ConservationLaw, state, model::BattMoModel, dt, flow_disc::PotentialFlow, ldisc)

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

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model, dt, flow_disc) where T

    @inbounds trans = state.ECTransmissibilities[face]

    q = - half_face_two_point_kgrad(c, other, trans, state.Temperature, state.Conductivity)

    return T(q)
    
end


export output_flux

function output_flux(model, state, parameters, eqname = :mass_conservation)

    n   = number_of_faces(model)
    N   = model.domain.representation.neighborship
    out = zeros(n)
    fd  = model.domain.discretizations.flow
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

####################
# Setup Parameters #
####################

""" We set the transmissibilities as parameters. They are used to compute fluxes, most of time using harmonic average
for the coefficient, see FaceFlux function above """
function select_parameters!(prm, D::Union{TwoPointPotentialFlowHardCoded, PotentialFlow}, model::BattMoModel)
    
    prm[:ECTransmissibilities] = ECTransmissibilities()
    
end

function select_parameters!(prm, D::MinimalECTPFAGrid, model::BattMoModel)    

    prm[:Volume]         = Volume()
    prm[:VolumeFraction] = VolumeFraction()
    
end

function select_parameters!(prm, d::DataDomain, model::BattMoModel)
    prm[:Volume] = Volume()
end


#######################
# Boundary conditions #
#######################


function Jutul.apply_boundary_conditions!(storage, parameters, model::BattMoModel)
    equations_storage = storage.equations
    equations = model.equations
    for (eq, eq_s) in zip(values(equations), equations_storage)
        apply_bc_to_equation!(storage, parameters, model, eq, eq_s)
    end
end


function apply_bc_to_equation!(storage, parameters, model::BattMoModel, eq::ConservationLaw{:Charge}, eq_s)
    
    acc   = get_diagonal_entries(eq, eq_s)
    state = storage.state

    apply_boundary_potential!(acc, state, parameters, model, eq)

end

apply_bc_to_equation!(storage, parameters, model::BattMoModel, eq, eq_s) = nothing

function apply_boundary_potential!(acc, state, parameters, model::BattMoModel, eq::ConservationLaw{:Charge})

    dolegacy = false
    
    if model.domain.representation isa MinimalECTPFAGrid
        bc = model.domain.representation.boundary_cells
        if length(bc) > 0
            dobc = true
        else
            dobc = false
        end
        dolegacy = true
    elseif Jutul.hasentity(model.domain, BoundaryDirichletFaces())
        nc = count_active_entities(model.domain, BoundaryDirichletFaces())
        dobc = nc > 0
        if dobc
            bcdirhalftrans = model.domain.representation[:bcDirHalfTrans]
            bcdircells     = model.domain.representation[:bcDirCells]
            bcdirinds      = model.domain.representation[:bcDirInds]
        end
    else
        dobc = false
    end
    
    if dobc
        
        Phi          = state[:Phi]
        BoundaryPhi  = state[:BoundaryPhi]
        conductivity = state[:Conductivity]

        if dolegacy
            T_hf = model.domain.representation.boundary_hfT
            for (i, c) in enumerate(bc)
                @inbounds acc[c] += conductivity[c]*T_hf[i]*(Phi[c] - value(BoundaryPhi[i]))
            end
        else
            for (ht, c, i) in zip(bcdirhalftrans, bcdircells, bcdirinds)
                @inbounds acc[c] += conductivity[c]*ht*(Phi[c] - value(BoundaryPhi[i]))
            end
        end
    end
    
end

apply_boundary_potential!(acc, state, parameters, model::BattMoModel, eq::ConservationLaw) = nothing



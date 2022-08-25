using Jutul
using Tullio
export fluid_volume

#########
# utils #
#########


function fluid_volume(grid::MinimalECTPFAGrid)
    grid.volumes
end

function declare_entities(G::MinimalECTPFAGrid)
    # Cells equal to number of pore volumes
    c = (entity = Cells(), count = length(G.volumes))
    # Faces
    f = (entity = Faces(), count = size(G.neighborship, 2))
    bf = (entity = BoundaryFaces(), count = length(G.boundary_cells))
    return [c, f, bf]
end

################
# All EC-comps #
################

# ? Is this necessary?
function single_unique_potential(model::ECModel)
    return false
end

function number_of_entities(model, pv::KGrad)
    """ Two fluxes per face """
    return 2*count_entities(model.domain, Faces())
end

function number_of_entities(model, ::Potential)
    return count_entities(model.domain, Cells())
end

function number_of_entities(model, BP::BoundaryPotential)
    return size(model.domain.grid.boundary_cells)[1]
end
function number_of_entities(model, BP::BoundaryCurrent)
    return size(BP.cells)[1]
end

function number_of_entities(model, pv::NonDiagCellVariables)
    """ Each value depends on a cell and all its neighbours """
    return size(model.domain.discretizations.charge_flow.cellcell.tbl, 1) #! Assumes 2D
end

function values_per_entity(model, u::CellVector)
    return 2
end

function values_per_entity(model, u::ScalarNonDiagVaraible)
    return 1
end

function degrees_of_freedom_per_entity(model, sf::NonDiagCellVariables)
    return values_per_entity(model, sf) 
end

# ?Why not faces?
#function associated_entity(::KGrad)
#    Cells()
#end

@inline function get_diagonal_cache(eq::ConservationTPFAStorage)
    return eq.accumulation
end

function initialize_variable_value(
    model, pvar::NonDiagCellVariables, val; perform_copy=true
    )
    nu = number_of_entities(model, pvar)
    nv = values_per_entity(model, pvar)
    
    @assert length(val) == nu * nv "Expected val length $(nu*nv), got $(length(val))"
    val::AbstractVector

    if perform_copy
        val = deepcopy(val)
    end
    return transfer(model.context, val)
end

function initialize_variable_value!(
    state, model, pvar::NonDiagCellVariables, symb::Symbol, val::Number
    )
    num_val = number_of_entities(model, pvar)*values_per_entity(model, pvar)
    V = repeat([val], num_val)
    return initialize_variable_value!(state, model, pvar, symb, V)
end


function align_to_jacobian!(
    law::ConservationTPFAStorage, eq::Conservation, jac, model, u::Cells; equation_offset = 0, 
    variable_offset = 0
    )
    fd = eq.flow_discretization
    M = global_map(model.domain)

    acc = law.accumulation
    hflux_cells = law.half_face_flux_cells

    diagonal_alignment!(
        acc, eq, jac, u, model.context;
        target_offset = equation_offset, source_offset = variable_offset
        )
    half_face_flux_cells_alignment!(
        hflux_cells, acc, jac, model.context, M, fd, 
        target_offset = equation_offset, source_offset = variable_offset
        )
end

function find_and_place_density!(
    jac, target, source, nu, ne, np, index, density, context
    )
    for e in 1:ne
        for d = 1:np
            pos = find_jac_position(
                jac, target, source, 
                e, d, 
                nu, nu, 
                ne, np, 
                context
                )
            set_jacobian_pos!(density, index, e, d, pos)
        end
    end
end

function density_alignment!(
    density, acc_cache, jac, context, flow_disc;
    target_offset = 0, source_offset = 0
    )
    
    nu, ne, np = ad_dims(acc_cache)
    facepos = flow_disc.conn_pos
    nc = length(facepos) - 1
    cc = flow_disc.cellcell

    Threads.@threads for cell in 1:nc
        for cn in cc.pos[cell]:(cc.pos[cell+1]-1)
            c, n = cc.tbl[cn]
            @assert c == cell
            other = n
            index = cn
            find_and_place_density!(
                jac, other + target_offset, cell + source_offset, nu, ne, np, index, 
                density, context
                )
        end
    end
end


function declare_pattern(model, e::Conservation, e_s::ConservationTPFAStorage, ::Cells)
    df = e.flow_discretization
    hfd = Array(df.conn_data)
    n = number_of_entities(model, e)
    # Fluxes
    I = map(x -> x.self, hfd)
    J = map(x -> x.other, hfd)
    # Diagonals
    D = [i for i in 1:n]

    I = vcat(I, D)
    J = vcat(J, D)

    return (I, J)
end

function declare_pattern(model, e::Conservation, e_s::ConservationTPFAStorage, ::Faces)
    df = e.flow_discretization
    cd = df.conn_data
    I = map(x -> x.self, cd)
    J = map(x -> x.face, cd)
    return (I, J)
end

#####################
# Updating Jacobian #
#####################


function update_linearized_system_equation!(nz, r, model, law::Conservation, eq_s::ConservationTPFAStorage)
    acc = get_diagonal_cache(eq_s)
    cell_flux = eq_s.half_face_flux_cells
    cpos = law.flow_discretization.conn_pos
    Jutul.update_linearized_system_subset_conservation_accumulation!(nz, r, model, acc, cell_flux, cpos, model.context)
end


function fill_jac_density!(nz, r, model, density)
    """
    Fills the entries of the Jacobian.
    First loop: Adds the contribution from density terms to the loop
    Second loop: Adds contributions from density to r.
    """

    # Cells, equations, partials
    nud, ne, np = ad_dims(density)
    dentries = density.entries
    dp = density.jacobian_positions

    # Fill density term
    Threads.@threads for i = 1:nud
        for e in 1:ne
            entry = get_entry(density, i, e, dentries)

            for d = 1:np
                pos = get_jacobian_pos(density, i, e, d, dp)
                @inbounds nz[pos] -= entry.partials[d]
            end
        end
    end

    nc = number_of_cells(model.domain)
    # Add value from densities
    mf = model.domain.discretizations.charge_flow
    cc = mf.cellcell
    nc = number_of_cells(model.domain)
    Threads.@threads for cn in cc.pos[1:end-1] # The diagonal elements
        for e in 1:ne
            @inbounds c, n = cc.tbl[cn]
            @assert c == n
            entry = get_entry(density, cn, e, dentries)
            @inbounds r[e, c] -= entry.value
        end
    end

end


############################
# Standard implementations #
############################

@jutul_secondary function update_as_secondary!(
    acc, tv::Mass, model, C
    )
    V = fluid_volume(model.domain.grid)
    vf = model.domain.grid.vol_frac
    @tullio acc[i] = C[i] * V[i] * vf[i]
end

@jutul_secondary function update_as_secondary!(
    acc, tv::Energy, model, T
    )
    V = fluid_volume(model.domain.grid)
    vf = model.domain.grid.vol_frac
    @tullio acc[i] = T[i] * V[i] * vf[i]
end

@jutul_secondary function update_as_secondary!(
    acc, tv::Charge, model, Phi # only for the graph
    )
    @tullio acc[i] = 0 # Charge neutrality
end

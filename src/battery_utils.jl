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

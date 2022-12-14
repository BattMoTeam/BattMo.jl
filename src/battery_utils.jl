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

# function number_of_entities(model, pv::KGrad)
#     """ Two fluxes per face """
#     return 2*count_entities(model.domain, Faces())
# end

# function number_of_entities(model, ::Potential)
#     return count_entities(model.domain, Cells())
# end

# function number_of_entities(model, BP::BoundaryPotential)
#     return size(model.domain.grid.boundary_cells)[1]
# end
# function number_of_entities(model, BP::BoundaryCurrent)
#     return size(BP.cells)[1]
# end

############################
# Standard implementations #
############################

@jutul_secondary function update_ion_mass!(
    acc, tv::Mass, model, C, Volume, VolumeFraction, ix
    )
    for i in ix
        @inbounds acc[i] = C[i] * Volume[i] * VolumeFraction[i]
    end
end

@jutul_secondary function update_energy!(
    acc, tv::Energy, model, T, Volume, VolumeFraction, ix
    )
    for i in ix
        @inbounds acc[i] = T[i] * Volume[i] * VolumeFraction[i]
    end
end

@jutul_secondary function update_as_secondary!(
    acc, tv::Charge, model, Phi, # only for the graph
    ix
    )
    for i in ix
        @inbounds acc[i] = 0.0
    end
end

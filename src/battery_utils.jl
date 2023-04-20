using Jutul
using Tullio
export fluid_volume

function fluid_volume(grid::MinimalECTPFAGrid)
    grid.volumes
end

function declare_entities(G::MinimalECTPFAGrid)
    # cells
    c = (entity = Cells(), count = length(G.volumes))
    # faces
    f = (entity = Faces(), count = size(G.neighborship, 2))
    # boundary faces
    bf = (entity = BoundaryFaces(), count = length(G.boundary_cells))
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

export find_coupling

function find_coupling(cellmap1, cellmap2, facemap1, facemap2, modelname = "placeholder")
    """
    docstring
    """
    Coupling = Dict()
    Coupling["model"] = modelname
    Coupling["cells"] = find_common(cellmap1, cellmap2)
    Coupling["faces"] = find_common(facemap1, facemap2)
    return Coupling
end

function find_common(map_grid1, map_grid2)

    """
    Insert cellmaps or facemaps

    """

    common_ground = intersect(map_grid1, map_grid2)
    entity1 = findall(x -> x ∈ common_ground, map_grid1)
    entity2 = findall(x -> x ∈ common_ground, map_grid2)
    if isempty(entity1)
        return nothing
    end
    return collect([entity1 entity2]) ###This might be quite slow, but I wanted output to be matrix
end
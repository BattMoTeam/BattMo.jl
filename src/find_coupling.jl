export find_coupling, find_coupling2


# Almost same as find_coupling. If cells overlap, all its faces will too. 
# Those are excluded in find_coupling2
function find_coupling2(maps1, maps2, G_mother, modelname = "placeholder")
    Coupling = Dict()
    Coupling["model"] = modelname
    Coupling["cells"] = find_common(maps1[1], maps2[1])
    Coupling["faces"] = find_common(maps1[2], maps2[2])

    M = G_mother["faces"]["neighbors"][maps1[2][Coupling["faces"][:, 1]],:]
    S1 = M[:,1] .∈ Ref(maps1[1]) .&& M[:,1] .∈ Ref(maps2[1])
    S2 = M[:,2] .∈ Ref(maps1[1]) .&& M[:,2] .∈ Ref(maps2[1])
    S = S1 .|| S2

    if all(S)
        Coupling["faces"] = nothing
    else
        Coupling["faces"] = Coupling["faces"][.!S, :]
    end

    return Coupling
end

function find_coupling(maps1, maps2, modelname = "placeholder")
    Coupling = Dict()
    Coupling["model"] = modelname
    Coupling["cells"] = find_common(maps1[1], maps2[1])
    Coupling["faces"] = find_common(maps1[2], maps2[2])
    return Coupling
end

function find_common(map_grid1, map_grid2)
    common_ground = intersect(map_grid1, map_grid2)
    entity1 = findall(x -> x ∈ common_ground, map_grid1)
    entity2 = findall(x -> x ∈ common_ground, map_grid2)
    if isempty(entity1)
        return nothing
    end
    return collect([entity1 entity2]) ###This might be quite slow, but I wanted output to be matrix
end
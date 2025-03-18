using Jutul, BattMo

export
    find_coupling,
    find_common,
    findBoundary,
    convert_geometry

#####################
# utility functions #
#####################

"""
   find coupling cells and faces between two grid maps
"""
function find_coupling(maps1, maps2, modelname = "placeholder")
    Coupling = Dict()
    Coupling["model"] = modelname
    Coupling["cells"] = find_common(maps1[1], maps2[1])
    Coupling["faces"] = find_common(maps1[2], maps2[2])
    return Coupling
end

"""
    find common elements between two mappings
"""
function find_common(map_grid1, map_grid2)
    common_ground = intersect(map_grid1, map_grid2)
    entity1 = findall(x -> x ∈ common_ground, map_grid1)
    entity2 = findall(x -> x ∈ common_ground, map_grid2)
    if isempty(entity1)
        return nothing
    end

    return collect([entity1 entity2]) ###This might be quite slow, but I wanted output to be matrix

end

""" Generic function to compute the couplings structure between the components
"""
function setup_couplings(components, grids, global_maps)

    couplings = Dict{String,Dict{String,Any}}()

    for (ind1, comp1) in enumerate(components)

        couplings[comp1] = Dict{String,Any}()

        for (ind2, comp2) in enumerate(components)

            intersection = find_coupling(global_maps[comp1], global_maps[comp2], [comp1, comp2])

            intersection_tmp = Dict() # intersection

            if ind1 != ind2

                cells = intersection["cells"]
                faces = intersection["faces"]

                if isnothing(cells)
                    # We recover the coupling cells from the neighbors
                    if !isnothing(faces)
                        nb = grids[comp1]["faces"]["neighbors"]
                        locfaces = faces[:, 1]
                        loccells = nb[locfaces,1] + nb[locfaces,2]
                        intersection_tmp = Dict("cells" => loccells, "faces" => locfaces, "face_type" => true)
                    end

                else
                    # Coupling between cells and, in this case, face couplings are meaningless
                    if isnothing(faces)
                        faces = []
                    end

                    if size(faces, 1) != size(cells, 1)
                        intersection_tmp = Dict("cells" => cells[:, 1], "faces" => [], "face_type" => false)
                    else
                        @assert false
                    end
                end

                if !(isnothing(cells) && isnothing(faces))
                    couplings[comp1][comp2] = intersection_tmp
                end
            end
        end
    end

    return couplings

end






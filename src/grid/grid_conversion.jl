using Infiltrator

export convert_to_mrst_grid


"""
Convert grid from jutul format to mrst format
"""
function convert_to_mrst_grid(g)

    # Some utility functions

    """ From an indirection map, create the array of matching pairs
    """
    function get_pairs(pos, vals)
        
        cells = Int[]
        sizehint!(cells, length(vals))
        
        for icell in eachindex(pos[1 : end - 1])
            n = pos[icell + 1] - pos[icell]
            if n > 0
                cells = append!(cells, fill(icell, n))
            end
        end

        return hcat(cells, vals)
        
    end
    
    """ From an array of pair, create the indirection map. The pair should be sorted with respect to the first column
    """
    function get_pos(inds)
        
        pos = Int[]
        n = inds[end]
        sizehint!(pos, n)
        push!(pos, 1)
        current_index = 1
        for i in eachindex(inds)
            if inds[i] != current_index
                push!(pos, i)
                current_index = inds[i]
            end
        end
        push!(pos, length(inds) + 1)
        return pos
        
    end

    ## setup cellface mapping
    # Remove the separate boundary face indexing
    
    int_cellface = get_pairs(g.faces.cells_to_faces.pos, g.faces.cells_to_faces.vals)
    bd_cellface  = get_pairs(g.boundary_faces.cells_to_faces.pos, g.boundary_faces.cells_to_faces.vals)
    
    bd_cellface[: , 2] = bd_cellface[: , 2] .+ size(g.faces.neighbors, 1)
    
    cellface = vcat(int_cellface, bd_cellface)
    cellface = sortslices(cellface, dims = 1)

    G_raw_cells = Dict()
    G_raw_cells["faces"]    = cellface[:, 2]
    G_raw_cells["facePos"]  = get_pos(cellface[:, 1])
    G_raw_cells["num"]      = length(g.faces.cells_to_faces)

    ## setup facenode mapping
    # Remove the separate boundary face indexing

    int_facenode = get_pairs(g.faces.faces_to_nodes.pos, g.faces.faces_to_nodes.vals)
    bd_facenode  = get_pairs(g.boundary_faces.faces_to_nodes.pos, g.boundary_faces.faces_to_nodes.vals)
    
    bd_facenode[: , 1] = bd_facenode[: , 1] .+ size(g.faces.neighbors, 1)

    facenode = vcat(int_facenode, bd_facenode)

    neighbors = mapreduce(x -> [x[1] x[2]], vcat, g.faces.neighbors)
    neighbors = vcat(neighbors, hcat(g.boundary_faces.neighbors, zeros(Int, length(g.boundary_faces.neighbors))))

    G_raw_faces = Dict()
    G_raw_faces["nodes"]     = facenode[:, 2]
    G_raw_faces["nodePos"]   = get_pos(facenode[:, 1])
    G_raw_faces["neighbors"] = neighbors
    G_raw_faces["num"]       = length(g.faces.neighbors) + length(g.boundary_faces.neighbors)

    G_raw_nodes = Dict()
    G_raw_nodes["num"]    = length(g.node_points)
    G_raw_nodes["coords"] = transpose(reduce(hcat, g.node_points))

    G_raw = Dict()
    G_raw["cells"]   = G_raw_cells
    G_raw["faces"]   = G_raw_faces
    G_raw["nodes"]   = G_raw_nodes
    G_raw["griddim"] = length(g.node_points[1])
    G_raw["type"]    = Matrix{Any}(undef, 0, 0)

    return G_raw
    
end

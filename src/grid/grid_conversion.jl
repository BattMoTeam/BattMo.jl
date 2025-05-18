using Infiltrator

export convert_to_mrst_grid

function add_order(list)
    len = length(list)
    return hcat(list, collect(1:len))
end

function convert_to_mrst_grid(g)
    """
    Convert grid from jutul format to mrst format
    """
    G_raw = Dict{String, Any}()

    G_raw_cells = Dict()
    G_raw_faces = Dict()
    G_raw_nodes = Dict()


    ## setup cellface mapping
    # Remove the separate boundary face indexing
    
    function get_pairs(pos, vals)
        
        cells = Int[]
        sizehint!(cells, length(vals))
        
        for icell in eachindex(pos[1 : end - 1])
            n = pos[icell + 1] - pos[icell]
            if n > 0
                cells = append!(cells, repeat(icell, n))
            end
        end

        return hcat(cells, vals)
        
    end

    int_cellface = get_pairs(g.faces.cells_to_faces.pos, g.faces.cells_to_faces.vals)
    bd_cellface  = get_pairs(g.boundary_faces.cells_to_faces.pos, g.boundary_faces.cells_to_faces.vals)
    
    bd_cellface[: , 2] = bd_cellface[: , 2] .+ size(g.faces.cells_to_faces.neighbors, 1)
    
    cellface = vcat(int_cellface, bd_cellface)
    cellface = sortslices(cellface, dims = 1)

    ## setup facenode mapping
    # Remove the separate boundary face indexing

    int_facenode = get_pairs(g.faces.faces_to_nodes.pos, g.faces.faces_to_nodes.vals)
    bd_facenode  = get_pairs(g.boundary_faces.faces_to_nodes.pos, g.boundary_faces.faces_to_nodes.vals)
    
    bd_facenode[: , 1] = bd_facenode[: , 1] .+ size(g.faces.cells_to_faces.neighbors, 1)

    facenode = vcat(int_facenode, bd_facenode)
    facenode = sortslices(facenode, dims = 1)

    function set_pos(inds)
        pos = Int[]
        n = inds[end]
        sizehint!(pos, n)
        pos[1] = 1
        current_index = 1
        for i in eachindex(inds)
            if inds[i] != current_index
                push!(pos, i)
                current_index = inds[i]
            end
        end
        push!(pos, n + 1)
        return pos
    end
    
    g.faces.cells_to_faces.vals
    
    
    dim = length(g.node_points[1])

    cells_facePos = diff(g.faces.cells_to_faces.pos) + diff(g.boundary_faces.cells_to_faces.pos)
    
    faces_neighbors          = findall(x -> 1 ∈ x, g.faces.neighbors)
    boundary_faces_neighbors = findall(x -> x == 1, g.boundary_faces.neighbors) .+ length(g.faces.neighbors)
    
    neighbors = add_order([faces_neighbors; boundary_faces_neighbors])
    G_raw_cells_faces = neighbors    
    
    for i in 2:length(g.faces.cells_to_faces)
        faces_neighbors = findall(x -> i ∈ x, g.faces.neighbors)
        boundary_faces_neighbors = findall(x -> x == i, g.boundary_faces.neighbors) .+ length(g.faces.neighbors)
        neighbors = add_order([faces_neighbors; boundary_faces_neighbors])
        G_raw_cells_faces = [G_raw_cells_faces ; neighbors]
    end

    G_raw_cells["faces"]    = G_raw_cells_faces
    # IDK what indexmap, but often is 1:number_of_cells so I keep it that way
    G_raw_cells["indexmap"] = collect(1:length(g.faces.cells_to_faces)) 
    G_raw_cells["facePos"]  = cumsum([1;cells_facePos])
    G_raw_cells["num"]      = length(g.faces.cells_to_faces)


    a = diff(g.faces.faces_to_nodes.pos)
    b = diff(g.boundary_faces.faces_to_nodes.pos)
    c = g.faces.faces_to_nodes.vals
    d = g.boundary_faces.faces_to_nodes.vals

    G_raw_faces_neighbors = zeros(Int64, length(g.faces.neighbors) + length(g.boundary_faces.neighbors), 2)
    for i in 1:length(g.faces.neighbors)
        G_raw_faces_neighbors[i, :] = findall(x-> i ∈ x, G_raw_cells_faces[:,1])
    end
    
    for i in 1:length(g.boundary_faces.neighbors)
        G_raw_faces_neighbors[i + length(g.faces.neighbors)] = findfirst(x -> i + length(g.faces.neighbors) ∈ x, G_raw_cells_faces[:,1])
    end

    G_raw_faces["nodes"]     = reshape([c; d],:,1)
    G_raw_faces["tag"]       = zeros(length(g.faces.neighbors) + length(g.boundary_faces.neighbors))
    G_raw_faces["neighbors"] = ceil.(Int64, G_raw_faces_neighbors/6)
    G_raw_faces["num"]       = length(g.faces.neighbors) + length(g.boundary_faces.neighbors)
    G_raw_faces["nodePos"]   = reshape(cumsum([1;[a; b]]), :, 1)

    G_raw_nodes["num"]    = length(g.node_points)
    G_raw_nodes["coords"] = transpose(reduce(hcat, g.node_points))


    G_raw["faces"]   = G_raw_faces
    G_raw["nodes"]   = G_raw_nodes
    G_raw["griddim"] = dim
    G_raw["cells"]   = G_raw_cells
    G_raw["type"]    = Matrix{Any}(undef, 0, 0)

    return G_raw
    
end

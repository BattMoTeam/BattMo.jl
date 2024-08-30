using Jutul, BattMo, Infiltrator

export
    pouch_grid,
    find_coupling,
    find_common,
    setup_geometry,
    findBoundary,
    pouch_grid,
    convert_geometry,
    one_dimensional_grid

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

"""
 Convert the grids given in MRST format (given as dictionnaries, also called raw grids) to Jutul format (UnstructuredMesh)
 In particular, for the external face couplings, we need to recover the coupling face indices in the boundary face indexing (jutul mesh structure holds a different indexing for the boundary faces)
"""
function convert_geometry(grids, couplings; include_current_collectors = true)

    if include_current_collectors
        components = ["NegativeCurrentCollector",
                      "NegativeElectrode"       ,
                      "Separator"               ,
                      "PositiveElectrode"       ,
                      "PositiveCurrentCollector",
                      "Electrolyte"]
    else
        components = ["NegativeElectrode"       ,
                      "Separator"               ,
                      "PositiveElectrode"       ,
                      "Electrolyte"]
    end
    
    ugrids = Dict()
    
    for component in components
        ugrids[component] = UnstructuredMesh(grids[component])
    end
    
    ucouplings = deepcopy(couplings)
    
    for component in components

        component_couplings = ucouplings[component]
        
        grid  = grids[component]
        ugrid = ugrids[component]
        
        for (other_component, coupling) in component_couplings
            
            if !isempty(coupling)
                
                if coupling["face_type"]
                    
                    faces = coupling["faces"]
                    cells = coupling["cells"]
                    
                    for fi in eachindex(faces)

                        face = faces[fi]
                        cell = cells[fi]

                        candidates = ugrid.boundary_faces.cells_to_faces[cell]
                        rface = face
                        rawfaces = grid["faces"]
                        lnodePos = rawfaces["nodePos"][rface : (rface + 1)]
                        lnodes = Set(rawfaces["nodes"][lnodePos[1] : lnodePos[2] - 1])
                        count = 0

                        for lfi in eachindex(candidates)
                            fnodes = Set(ugrid.boundary_faces.faces_to_nodes[candidates[lfi]])
                            if fnodes == lnodes
                                faces[fi] = candidates[lfi]
                                count += 1
                            end
                        end
                        @assert count == 1
                    end
                else
                    @assert isempty(coupling["faces"])
                end
            end
        end
    end
    
    return ugrids, ucouplings
    
end 

##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(geomparams::InputGeometryParams)

    grids       = Dict()
    global_maps = Dict()
    
    include_current_collectors = geomparams["include_current_collectors"]
    faceArea = geomparams["faceArea"]
    
    if include_current_collectors

        components = ["NegativeCurrentCollector",
                      "NegativeElectrode"       ,
                      "Separator"               ,
                      "PositiveElectrode"       ,
                      "PositiveCurrentCollector"]
        
        elyte_comp_start = 2
        
    else
        
        components = ["NegativeElectrode",
                      "Separator"        ,
                      "PositiveElectrode"]
        
        elyte_comp_start = 1
        
    end

    ns = [geomparams[component]["N"] for component in components]
    xs = [geomparams[component]["thickness"] for component in components]
    
    L = StatsBase.inverse_rle(xs./ns, ns)

    mesh = CartesianMesh((sum(ns), 1, 1), (L, faceArea, 1.))
    
    uParentGrid = UnstructuredMesh(mesh)
    parentGrid = convert_to_mrst_grid(uParentGrid)

    cinds = vcat(1, 1 .+ cumsum(ns))

    uParentGrid = tpfv_geometry(uParentGrid)
    x = uParentGrid.cell_centroids[1, :]
    x = [[val, i] for (i, val) in enumerate(x)]
    x = sort!(x, by = xx -> xx[1])

    ## setup the grid for each component
    for (icomponent, component) in enumerate(components)
        allinds = collect((1 : sum(ns)))
        inds = cinds[icomponent] : cinds[icomponent + 1] - 1
        G, maps... = remove_cells(parentGrid, setdiff!(allinds, inds))
        grids[component] = G
        global_maps[component] = maps
    end

    ## setup for the eletrolyte
    allinds = collect((1 : sum(ns)))
    inds = cinds[elyte_comp_start] : (cinds[elyte_comp_start + 3] - 1)
    G, maps... = remove_cells(parentGrid, setdiff!(allinds, inds))

    grids["Electrolyte"]       = G
    global_maps["Electrolyte"] = maps

    push!(components, "Electrolyte")
    
    couplings = setup_couplings(components, grids, global_maps)

    grids, couplings = convert_geometry(grids, couplings; include_current_collectors = include_current_collectors)
    
    """Add  external coupling to the coupling structure.
       Function can be used both with and without current collector."""
    if include_current_collectors
        boundaryComponents = Dict("left"  => "NegativeCurrentCollector",
                                  "right" => "PositiveCurrentCollector")
    else
        boundaryComponents = Dict("left"  => "NegativeElectrode",
                                  "right" => "PositiveElectrode")
    end

    """get x-coordinate of the boundary faces"""
    function getcoord(grid, i)
        centroid, = Jutul.compute_centroid_and_measure(grid, BoundaryFaces(), i)
        return centroid[1]
    end

    component = boundaryComponents["left"]
    grid = grids[component]
    
    nf = number_of_boundary_faces(grid)
    
    bcfaceind = argmin(i -> getcoord(grid, i), 1 : nf)
    
    couplings[component]["External"] = Dict("cells" => [1], "boundaryfaces" => [bcfaceind])        
    
    component = boundaryComponents["right"]
    grid = grids[component]
    
    nf = number_of_boundary_faces(grid)
    nc = number_of_cells(grid)
    
    bcfaceind = argmax(i -> getcoord(grid, i), 1 : nf)
    
    couplings[component]["External"] = Dict("cells" => [nc], "boundaryfaces" => [bcfaceind])
    
    return grids, couplings
    
end

#################################
# single layer pouch cell setup #
#################################

""" Create a single layer pouch grid
    """
function pouch_grid(geomparams::InputGeometryParams)

    nx          = geomparams["nx"] 
    ny          = geomparams["ny"]
    nz          = geomparams["nz"]
    tab_cell_nx = geomparams["tab_cell_nx"]
    tab_cell_ny = geomparams["tab_cell_ny"]
    
    ne_cc_nx     = tab_cell_nx
    int_elyte_nx = nx
    pe_cc_nx     = tab_cell_nx
    
    ne_cc_ny = tab_cell_ny
    elyte_ny = ny
    pe_cc_ny = tab_cell_ny

    ne_cc_nz = nz
    ne_am_nz = nz
    sep_nz   = nz
    pe_am_nz = nz
    pe_cc_nz = nz
    
    x0_cells, x4_cells = tab_cell_nx, tab_cell_nx ### These can be zero, then CC is on the edge
    x0, x4 = 6, 6

    paramsx = [x0_cells, ne_cc_nx, int_elyte_nx, pe_cc_nx, x4_cells]
    paramsy = [ne_cc_ny, elyte_ny, pe_cc_ny]
    paramsz = [ne_cc_nz, ne_am_nz, sep_nz, pe_am_nz, pe_cc_nz]

    x = [x0, 4, 2, 4, x4] .* 1e-2/nx 
    y = [2, 20, 2] .* 1e-3/ny
    z = [10, 100, 50, 80, 10] .* 1e-6/nz
    
    same_side = false # if true, needs pe_cc_ny >= ne_cc_ny. I think they usually are equal
    strip = true

    Lx = StatsBase.inverse_rle(x, paramsx)
    Ly = StatsBase.inverse_rle(y, paramsy)
    Lz = StatsBase.inverse_rle(z, paramsz)
    
    Nx = length(Lx)
    Ny = length(Ly)
    Nz = length(Lz)
    
    h = CartesianMesh((Nx, Ny, Nz), (Lx, Ly, Lz))
    H_back = convert_to_mrst_grid(UnstructuredMesh(h));
    
    #################################################################
    
    # Iterators in the z-direction over the cells that contains the positive current collector.
    # Each iterator contains an horizonzal slab at the end
    pe_cc_list_of_iterators = [Nx * (i * Ny - pe_cc_ny)  + 1 : Nx * Ny * i for i in 1:Nz]

    # pecc_extra_cells : Those cells will be removed
    pe_cc_extra_cells = cat(pe_cc_list_of_iterators..., dims = 1)
    
    # (x-y) Carthesian indices of the cells of the positive current collector (not expanded in the z direction). 
    index_of_pe_cc = cat([Nx * i - pe_cc_nx + 1 : Nx * i for i in 1:pe_cc_ny]..., dims = 1)

    # Index of the positive current collector
    pe_cc_cells = cat(getindex.(pe_cc_list_of_iterators[end - pe_cc_nz + 1:end], [index_of_pe_cc .- x4_cells])..., dims = 1)

    setdiff!(pe_cc_extra_cells, pe_cc_cells)

    # We proceed in the same way for the negative current collector
   
    ne_cc_list_of_iterators = [Nx * Ny * (i-1)  + 1 : Nx * (Ny * (i-1) + ne_cc_ny) for i in 1:Nz]
    ne_cc_extra_cells = cat(ne_cc_list_of_iterators..., dims = 1)
    
    index_of_ne_cc = cat([Nx * (i - 1) + 1 : Nx * (i - 1) + ne_cc_nx for i in 1:ne_cc_ny]..., dims = 1)
    
    if same_side
        ne_cc_cells = cat(getindex.(pe_cc_list_of_iterators[1:ne_cc_nz], [index_of_ne_cc .+ x0_cells])..., dims = 1)
        setdiff!(pe_cc_extra_cells, ne_cc_cells)
    else
        ne_cc_cells = cat(getindex.(ne_cc_list_of_iterators[1:ne_cc_nz], [index_of_ne_cc .+ x0_cells])..., dims = 1)
        setdiff!(ne_cc_extra_cells, ne_cc_cells)
    end
    
    zvals =  paramsz .* z

    G, = remove_cells(H_back, vcat(pe_cc_extra_cells, ne_cc_extra_cells))

    grids, couplings = setup_geometry(G, zvals)
    grids, couplings = convert_geometry(grids, couplings)

    # Negative current collector external coupling

    grid = grids["NegativeCurrentCollector"]

    neighbors = get_neighborship(grid; internal = false)

    bcfaces = findBoundary(grid, 2, false);
    bccells = neighbors[bcfaces]
    
    couplings["NegativeCurrentCollector"]["External"] = Dict("cells" => bccells, "boundaryfaces" => bcfaces)        
    
    # Positive current collector external coupling

    grid = grids["PositiveCurrentCollector"]

    neighbors = get_neighborship(grid; internal = false)

    bcfaces = findBoundary(grid, 2, true);
    bccells = neighbors[bcfaces]
    
    couplings["PositiveCurrentCollector"]["External"] = Dict("cells" => bccells, "boundaryfaces" => bcfaces)        

    return grids, couplings
    
end

"""
Single layer pouch cell utility function
find the tags of each cell (tag from 1 to 5 for each grid component such as negative current collector and so
on). Returns a list with 5 elements, each element containing a list of cells for the corresponding tag
"""
function find_tags(h, paramsz_z)
    
    h_with_geo = tpfv_geometry(h)
    cut_offs = cumsum(paramsz_z)
    tag = searchsortedfirst.([cut_offs], h_with_geo.cell_centroids[3,:])
    return [findall(x -> x == i, tag) for i in 1 : 5]
    
end

"""
Single layer pouch cell utility function
Find the face boundary of the grid in a given Cartesian direction (dim) and direction (true of false correpondings to "left" and "right"). It is used to obtain the external coupling for the grid
"""
function findBoundary(grid, dim, dir)
    
    nf = number_of_boundary_faces(grid)
    
    if dir
        max_min = -Inf
    else
        max_min = Inf
    end
    
    tol = 1000*eps()

    function getcoord(i)
        centroid, = Jutul.compute_centroid_and_measure(grid, BoundaryFaces(), i)
        return centroid[dim]
    end
    
    coord = [getcoord(i) for i in 1 : nf]

    if dir
        max_min = maximum(coord)
    else
        max_min = minimum(coord)
    end

    faces = findall(abs.(coord .- max_min) .< tol)

    return faces
    
end

""" single layer pouch cell utility function,
    From a global grid and the position of the z-values for the different components, returns the grids with the coupling
"""
function setup_geometry(H_mother, paramsz)
    
    grids       = Dict()
    global_maps = Dict()

    components = ["NegativeCurrentCollector",
                  "NegativeElectrode"       ,
                  "Separator"               ,
                  "PositiveElectrode"       ,
                  "PositiveCurrentCollector"]
    
    tags = find_tags(UnstructuredMesh(H_mother), paramsz)

    grids["Global"] = UnstructuredMesh(H_mother)
    nglobal = number_of_cells(grids["Global"])
    tags = find_tags(grids["Global"], paramsz)
    

    # Setup the grids and mapping for all components
    allinds = 1 : nglobal
    for (ind, component) in enumerate(components)
        G, maps... = remove_cells(H_mother, setdiff(allinds, tags[ind]))
        grids[component] = G
        global_maps[component] = maps
    end
    
    # Setup the grid and mapping for the electrolyte
    G, maps... = remove_cells(H_mother, setdiff(allinds, vcat(tags[2:4]...)))
    grids["Electrolyte"] = G
    global_maps["Electrolyte"] = maps
    
    # Add Electrolyte in the component list
    push!(components, "Electrolyte")

    # Setup the couplings
    couplings = setup_couplings(components, grids, global_maps)
    
    return grids, couplings
    
end

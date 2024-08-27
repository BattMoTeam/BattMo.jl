using Jutul, BattMo

function plot_grid_test(G)
    fig, ax = plot_mesh(G)
    Jutul.plot_mesh_edges!(ax, G)
end;

function find_tags(h, paramsz_z)
    h_with_geo = tpfv_geometry(h)
    cut_offs = cumsum(paramsz_z)
    tag = searchsortedfirst.([cut_offs], h_with_geo.cell_centroids[3,:])
    return [findall(x -> x == i, tag) for i in 1:5]
end;

function basic_grid_example_p4d2(;
                                 nx          = 1,
                                 ny          = 1,
                                 nz          = 1,
                                 tab_cell_nx = 0,
                                 tab_cell_ny = 0)

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
    H_back = back_converter(UnstructuredMesh(h));
    
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
    G, cellmap, facemap, nodemap = remove_cells(H_back, vcat(pe_cc_extra_cells, ne_cc_extra_cells))

    return G, cellmap, facemap, nodemap, zvals

end;


function setup_geometry(H_mother, paramsz)
    couplings = []
    grids=Dict()
    global_maps = Dict()

    components = ["NegativeCurrentCollector","NegativeElectrode","Separator",
             "PositiveElectrode","PositiveCurrentCollector"]#"Electrolyte"]             
    
             tags = find_tags(UnstructuredMesh(H_mother), paramsz)

    grids["Global"] = UnstructuredMesh(H_mother)
    nglobal = number_of_cells(grids["Global"])
    tags = find_tags(grids["Global"], paramsz)
    allinds = 1:nglobal
    for (ind, component) in enumerate(components)
        G, maps... = remove_cells(H_mother, setdiff(allinds, tags[ind]))
        grids[component] = G#UnstructuredMesh(G)
        global_maps[component] =maps
    end
    begin
        G, maps... = remove_cells(H_mother, setdiff(allinds, vcat(tags[2:4]...)))
        grids["Electrolyte"] = G#UnstructuredMesh(G)
        global_maps["Electrolyte"] = maps
    end
    ##
    allcomps = components
    append!(allcomps,["Electrolyte"])
    grids["Couplings"] = Dict{String,Dict{String,Any}}()
    for (ind1, comp1) in enumerate(allcomps)
        grids["Couplings"][comp1] = Dict{String,Any}()
      for (ind2, comp2) in enumerate(allcomps)
            #println([comp1,comp2])
            intersection=find_coupling(global_maps[comp1],global_maps[comp2],  [comp1, comp2])
            intersection_tmp = Dict() # intersection
            #tmp = Dict(comp2=> intersection)
            if(ind1 < ind2)
                append!(couplings,[intersection])
            end
            #println(size(couplings))
            if(ind1 == ind2)

            else
                cells = intersection["cells"]
                faces = intersection["faces"]
                if isnothing(cells) 
                    if isnothing(faces)
                        #println("No coupling")
                        #break;
                    else
                        nb = grids[comp1]["faces"]["neighbors"]
                        #println(nb)
                        locfaces = faces[:,1]
                        loccells = nb[locfaces,1] + nb[locfaces,2]                     
                        intersection_tmp = Dict("cells" => loccells, "faces" => locfaces,"face_type" => true)
                        #@assert sum(nb[locfaces,1] * nb[locfaces,2]) == 0
                    end
                else
                    if isnothing(faces)
                        faces = []
                    end
                    if size(faces,1) != size(cells,1)
                        intersection_tmp = Dict("cells" => cells[:,1], "faces" => [],"face_type" => false)
                    else
                       @assert false
                    end
                     
                    #intersection_tmp = Dict("cells" => cells[,1], "faces" => faces[:,1])
                end
                

                if(isnothing(cells) && isnothing(faces))
                    #println("No coupling")
                else   
                    grids["Couplings"][comp1][comp2] = intersection_tmp
                end
            end
      end
    end
    # ##
    return grids
end

function findBoundary(g, dim, dir)
    nf = number_of_boundary_faces(g)
    if(dir)
        max_min = -1e99
    else
        max_min = 1e99
    end
    face = BoundaryFaces()
    faces = Vector()
    tol = 1000*eps()
    for i in 1:nf
        centroid, area = Jutul.compute_centroid_and_measure(g, face, i)
        diffmax = centroid[dim]-max_min 
        if dir
            if  diffmax > 0
                #push!(faces, i)
                max_min = centroid[dim]
            end
        else
            if diffmax < 0
                #push!(faces, i)
                max_min = centroid[dim]
            end
        end
    end
    for i in 1:nf
        centroid, area = Jutul.compute_centroid_and_measure(g, face, i)
        diffmax = centroid[dim]-max_min 
        if dir
            if  abs(diffmax) < tol
                push!(faces, i)
                #max_min = centroid[dim]
            end
        else
            if abs(diffmax) < tol
                push!(faces, i)
                #max_min = centroid[dim]
            end
        end
    end

    return faces, max_min
end

function convert_geometry(grids)
    components = ["NegativeCurrentCollector","NegativeElectrode","Separator",
             "PositiveElectrode","PositiveCurrentCollector","Electrolyte"]
    ugrids = Dict()         
    for (ind, component) in enumerate(components)
        #println(component)
        ugrids[component] = UnstructuredMesh(grids[component])
    end 
    ugrids["Couplings"] = deepcopy(grids["Couplings"])
    for (ind, component) in enumerate(components)
        couplings = ugrids["Couplings"][component]
        graw = grids[component]
        g = ugrids[component]
        for (component2, coupling) in couplings
            #println([component,component2])
            #println(coupling)
            if !isempty(coupling)
                if coupling["face_type"]
                    # remap faces
                    faces = coupling["faces"]
                    cells = coupling["cells"]
                    for fi in eachindex(faces)
                        face = faces[fi]
                        cell = cells[fi]
                        candidates = g.boundary_faces.cells_to_faces[cell]
                        rface = face
                        rawface = graw["faces"]
                        lnodePos = rawface["nodePos"][rface:(rface+1)]
                        lnodes = Set(rawface["nodes"][lnodePos[1]:lnodePos[2]-1])
                        count = 0
                        #println(rface)
                        #println(lnodes)
                        #println("hei")
                        #print(candidates)
                        for lfi in eachindex(candidates)
                            fnodes = Set(g.boundary_faces.faces_to_nodes[candidates[lfi]])
                            if fnodes == lnodes
                                faces[fi] = candidates[lfi]
                                #ugrids["Couplings"][component][component2]["faces"][fi] = candidates[lfi]
                                count += 1
                            end
                        end
                        #println(count)
                        @assert count == 1
                        #end
                    end
                else
                    @assert isempty(coupling["faces"])
                end
            end
        end
    end
    return ugrids        
end

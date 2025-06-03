export
	pouch_grid,
	find_coupling,
	find_common,
	findBoundary,
	convert_geometry,
	one_dimensional_grid,
    jelly_roll_grid

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
    Arguments:
    - components  : vector of strings that gives the name of the component to be coupled
    - grids       : dictionnay of grids
    - global_maps : maps from the subgrid to the global grid
"""
function setup_couplings(components, grids, global_maps)

	couplings = Dict{String, Dict{String, Any}}()

	for (ind1, comp1) in enumerate(components)

		couplings[comp1] = Dict{String, Any}()

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
						loccells = nb[locfaces, 1] + nb[locfaces, 2]
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
			          "NegativeElectrode",
			          "Separator",
			          "PositiveElectrode",
			          "PositiveCurrentCollector",
			          "Electrolyte"]
	else
		components = ["NegativeElectrode",
			          "Separator",
			          "PositiveElectrode",
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
						lnodePos = rawfaces["nodePos"][rface:(rface+1)]
						lnodes = Set(rawfaces["nodes"][lnodePos[1]:lnodePos[2]-1])
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

	if haskey(grids, "Global")
		ugrids["Global"] = UnstructuredMesh(grids["Global"])
	end

	return ugrids, ucouplings

end

#########################
# jelly roll grid setup #
#########################

function jelly_roll_grid(geomparams::InputGeometryParams)

    geometry = geomparams["Geometry"]

    nangles = geometry["numberOfDiscretizationCellsAngular"]
    nz      = geometry["numberOfDiscretizationCellsVertical"]
    rinner  = geometry["innerRadius"]
    router  = geometry["outerRadius"] 
    height  = geometry["height"] 

    function get_vector(geomparams, fdname)
        # double coated electrode
        v = [geomparams["PositiveElectrode"]["Coating"][fdname],
             geomparams["PositiveElectrode"]["CurrentCollector"][fdname],
             geomparams["PositiveElectrode"]["Coating"][fdname],
             geomparams["Separator"][fdname],
             geomparams["NegativeElectrode"]["Coating"][fdname],
             geomparams["NegativeElectrode"]["CurrentCollector"][fdname],
             geomparams["NegativeElectrode"]["Coating"][fdname],
             geomparams["Separator"][fdname]]
        
        return v
    end

    Ns  = get_vector(geomparams, "N")
    dxs = get_vector(geomparams, "thickness")

    dx = mapreduce((dx, N) -> repeat([dx], N), vcat, dxs./Ns, Ns)
    
    spacing = [0; cumsum(dx)]
    spacing = spacing/spacing[end]

    thickness = sum(dxs)

    depths = [0; cumsum(repeat([height/nz], nz))]
    
    components = ["PositiveCurrentCollector",
                  "PositiveElectrode",
                  "Separator",
                  "Electrolyte",
                  "NegativeElectrode",
                  "NegativeCurrentCollector"]

    component_indices = Dict()
    component_indices["PositiveElectrode"]        = [1, 3]
    component_indices["PositiveCurrentCollector"] = [2]
    component_indices["Separator"]                = [4, 8]
    component_indices["NegativeElectrode"]        = [5, 7]
    component_indices["NegativeCurrentCollector"] = [6]
    component_indices["Electrolyte"]              = reduce(vcat, [component_indices["PositiveElectrode"],
                                                                  component_indices["Separator"],
                                                                  component_indices["NegativeElectrode"]])
    spacingtags = Dict()
    for component in components
        inds = Bool[]
        for i in eachindex(Ns)
            append!(inds, fill(i in component_indices[component], Ns[i]))
        end
        spacingtags[component] = findall(inds)
    end

    C = rinner
    A = thickness/(2*pi)

    nrot = Int(round((router - rinner)/(2*pi*A)))

    uParentGrid = Jutul.RadialMeshes.spiral_mesh(nangles, nrot; spacing = spacing, start = 0, A = A, C = C)

    uParentGrid = Jutul.extrude_mesh(uParentGrid, depths)

    tags = Jutul.RadialMeshes.spiral_mesh_tags(uParentGrid, spacing)

	parentGrid = convert_to_mrst_grid(uParentGrid)

	components = ["PositiveCurrentCollector",
			      "PositiveElectrode",
			      "Separator",
                  "Electrolyte",
			      "NegativeElectrode",
			      "NegativeCurrentCollector"]

    grids = Dict()
    global_maps = Dict()

    grids["Global"] = uParentGrid
    
	for component in components
		allinds = collect(1 : parentGrid["cells"]["num"])
		inds = findall(x -> x in spacingtags[component], tags[:spacing])
		G, maps... = remove_cells(parentGrid, setdiff!(allinds, inds))
		grids[component] = G
		global_maps[component] = maps
	end
    
	couplings = setup_couplings(components, grids, global_maps)

    grids, couplings = convert_geometry(grids, couplings)

    components = ["NegativeCurrentCollector", "PositiveCurrentCollector"]

    for component in components
        couplings[component]["External"] = setup_tab_couplings(grids, geomparams, component)
    end

    return grids, couplings
    
end

""" returns the coupling cells and faces for the tabs for the given component ("NegativeCurrentCollector" or "PositiveCurrentCollector")"""
function setup_tab_couplings(grids, inputparams, component)
    
    if component == "NegativeCurrentCollector"
        ip_component = "NegativeElectrode"
    else
        ip_component = "PositiveElectrode"
    end
        
    if haskey(inputparams[ip_component]["CurrentCollector"], "tabparams") && inputparams[ip_component]["CurrentCollector"]["tabparams"]["usetab"]
        grid = grids[component]
        geo = tpfv_geometry(grid)

        # We use the vertical faces of the current collector, at the top, to compute the spiral length. We collect their indices
        # in the structure vectbcface

        c  = geo.boundary_centroids[1 : 2, :]
        n  = geo.boundary_normals[1 : 2, :]
        nc = [norm(col) for col in eachslice(c, dims = 2)]

        vectbcface = findall(((1.0 ./nc) .* vec(sum(c .* n, dims = 1))) .< - (1 - 0.01)) 

        zc = geo.boundary_centroids[3, vectbcface]

        nz = inputparams["Geometry"]["numberOfDiscretizationCellsVertical"]

        if component == "NegativeCurrentCollector"
            vectbcface = vectbcface[abs.(zc .- maximum(zc)) .<= 0.01/nz*(maximum(zc) - minimum(zc))]
        else
            vectbcface = vectbcface[abs.(zc .- minimum(zc)) .<= 0.01/nz*(maximum(zc) - minimum(zc))]
        end

        # we sort by radius, so that the cells are ordered along the spiral in increasing order of radius

        vectbcface = sort(vectbcface, by = x -> norm(geo.boundary_centroids[1 : 2, x]))

        # We use the horizontal face centroids to compute the spiral length which we store in the structure spiral_lengths

        c = geo.boundary_centroids[1 : 2, vectbcface]
        dc = diff(c, dims = 2)
        dl = [norm(col) for col in eachslice(dc, dims = 2)]

        spiral_lengths = [0; cumsum(dl)]
        spiral_length  = spiral_lengths[end]

        # We recover the parameters for the tabs. The location of the tabs is given by a fraction which determines the fraction
        # of the total spiral length where the tab is located.

        tab_width     = inputparams[ip_component]["CurrentCollector"]["tabparams"]["width"]
        tab_fractions = inputparams[ip_component]["CurrentCollector"]["tabparams"]["fractions"]

        # The tab_intervals is an array of intervals given the lower and upper limit of the tab extent in term of the spiral
        # length
        tab_intervals  = [spiral_length*fraction .+ [-tab_width/2, tab_width/2] for fraction in tab_fractions]

        # We collect the faces (still vertical faces at top of current collector) in the tab_vert_faces structure.
        tab_vert_faces = []

        for interval in tab_intervals
            inds = findall(l -> ((l > interval[1]) && (l < interval[2])), spiral_lengths)
            push!(tab_vert_faces, vectbcface[inds])
        end

        # We use neigborship to retrieve the current collector cells that contains the collected current collector tab vertical
        # faces
        tab_cells = [geo.boundary_neighbors[tabvertface] for tabvertface in tab_vert_faces]

        # We retrieve the top (bottom) faces corresponding to the tab_cells and collect the indices in the structure first_tab_faces.
        """ For a given cell, collect the face that is at the top (bottom) of the cell"""
        function get_tab_first_horz_faces(cells)
            im = grid.boundary_faces.cells_to_faces
            tabfaces = []
            for cell in cells
                for iface in im.pos[cell] : im.pos[cell + 1] - 1
                    f = im.vals[iface]
                    n = geo.boundary_normals[:, f] 
                    if abs(n[1]) + abs(n[2]) < 1e-3*abs(n[3])
                        push!(tabfaces, f)
                    end
                end
            end
            return tabfaces
        end

        first_tab_faces = [get_tab_first_horz_faces(tab_cell) for tab_cell in tab_cells]

        # The structure first_tab_faces now contains the indices of the first row of top (bottom) faces of the current
        # collector and it remains to collect the other rows. To do so, we use the geometrical properties.

        # We collect all the top (bottom) faces in the vector horzfaces
        ns = geo.boundary_normals
        if component == "NegativeCurrentCollector"
            horzfaces = findall(n -> abs(n[1]) + abs(n[2]) < 0.01*n[3], eachslice(ns, dims = 2))
        elseif component == "PositiveCurrentCollector"
            horzfaces = findall(n -> abs(n[1]) + abs(n[2]) < -0.01*n[3], eachslice(ns, dims = 2))
        end

        # We setup angle and radius of the top (bottom) faces.
        angle_horzfaces  = [atan(c[2], c[1]) for c in eachslice(geo.boundary_centroids[1 : 2, horzfaces], dims = 2)]
        radius_horzfaces = [norm(c) for c in eachslice(geo.boundary_centroids[1 : 2, horzfaces], dims = 2)]

        """ Given a face in the first row of current collector, we collect the other cells in the radial direction. The
        centroids of those cells should have the same angle and a radius higher as the first row face and within the
        thickness of the current collector """
        function get_tab_radial_faces(first_tab_face)
            c = geo.boundary_centroids[1 : 2, first_tab_face]
            angle = atan(c[2], c[1])
            radius = norm(c)
            tabhorzfaces = []
            for (i, (angle_topface, radius_topface)) in enumerate(zip(angle_horzfaces, radius_horzfaces))
                if (abs(angle_topface - angle) < (0.1*2*pi/inputparams["Geometry"]["numberOfDiscretizationCellsAngular"])) && (radius_topface >= radius) && (radius_topface <= (radius + inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"]))
                    push!(tabhorzfaces, i)
                end
            end
            return horzfaces[tabhorzfaces]
        end

        """ For a row of top faces, we collect all the faces in the radial direction, using get_tab_radial_faces"""
        function get_tab_faces(firsttabrowfaces)
            return reduce(vcat, [get_tab_radial_faces(first_tab_face) for first_tab_face in firsttabrowfaces])
        end

        coupling_boundaryfaces = reduce(vcat, [get_tab_faces(first_tab_face) for first_tab_face in first_tab_faces])
        coupling_cells = geo.boundary_neighbors[coupling_boundaryfaces]

        coupling = Dict("cells" => coupling_cells, "boundaryfaces" => coupling_boundaryfaces)

    else

        g = grids[component]

        bc_faces = Int[]
        bc_cells = Int[]    
        geo = tpfv_geometry(g)
        for bf in 1 : number_of_boundary_faces(g)
            N = geo.boundary_normals[:, bf]
            Nz = N[3]
            if ((abs(N[1]) + abs(N[2]) < 0.01*abs(Nz))
                && (((Nz > 0) && (component == "NegativeCurrentCollector"))) ||((Nz < 0) && (component == "PositiveCurrentCollector")))
                push!(bc_faces, bf)
                push!(bc_cells, g.boundary_faces.neighbors[bf])
            end
        end
        
	    coupling = Dict("cells" => bc_cells, "boundaryfaces" => bc_faces)

    end
    
    return coupling
    
end

##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(geomparams::InputGeometryParams)

	grids       = Dict()
	global_maps = Dict()

	include_current_collectors = geomparams["include_current_collectors"]

	faceArea = geomparams["Geometry"]["faceArea"]

	vars = ["thickness", "N"]

	function getvals(var)
		neval = geomparams["NegativeElectrode"]["Coating"][var]
		sepval = geomparams["Separator"][var]
		peval = geomparams["PositiveElectrode"]["Coating"][var]
		if include_current_collectors
			ne_ccval = geomparams["NegativeElectrode"]["CurrentCollector"][var]
			pe_ccval = geomparams["PositiveElectrode"]["CurrentCollector"][var]
			out = [ne_ccval, neval, sepval, peval, pe_ccval]
		else
			out = [neval, sepval, peval]
		end
		return out
	end
	vals = Dict(
		"thickness" => getvals("thickness"),
		"N" => Int.(getvals("N")),
	)

	if include_current_collectors

		components = ["NegativeCurrentCollector",
			          "NegativeElectrode",
			          "Separator",
			          "PositiveElectrode",
			          "PositiveCurrentCollector"]

		elyte_comp_start = 2

	else

		components = ["NegativeElectrode",
			          "Separator",
			          "PositiveElectrode"]

		elyte_comp_start = 1

	end

	ns = vals["N"]
	xs = vals["thickness"]

	L = inverse_rle(xs ./ ns, ns)

	mesh = CartesianMesh((sum(ns), 1, 1), (L, faceArea, 1.0))

	uParentGrid = UnstructuredMesh(mesh)
	parentGrid = convert_to_mrst_grid(uParentGrid)

	cinds = vcat(1, 1 .+ cumsum(ns))

	uParentGrid = tpfv_geometry(uParentGrid)

	## setup the grid for each component
	for (icomponent, component) in enumerate(components)
		allinds = collect((1:sum(ns)))
		inds = cinds[icomponent]:cinds[icomponent+1]-1
		G, maps... = remove_cells(parentGrid, setdiff!(allinds, inds))
		grids[component] = G
		global_maps[component] = maps
	end

	## setup for the eletrolyte
	allinds = collect((1:sum(ns)))
	inds = cinds[elyte_comp_start]:(cinds[elyte_comp_start+3]-1)
	G, maps... = remove_cells(parentGrid, setdiff!(allinds, inds))

	grids["Electrolyte"]       = G
	global_maps["Electrolyte"] = maps

	push!(components, "Electrolyte")

	couplings = setup_couplings(components, grids, global_maps)

	grids, couplings = convert_geometry(grids, couplings; include_current_collectors = include_current_collectors)

	"""Add  external coupling to the coupling structure.
	   Function can be used both with and without current collector."""
	if include_current_collectors
		boundaryComponents = Dict("left" => "NegativeCurrentCollector",
			"right" => "PositiveCurrentCollector")
	else
		boundaryComponents = Dict("left" => "NegativeElectrode",
			"right" => "PositiveElectrode")
	end

	"""get x-coordinate of the boundary faces"""
	function getcoord(grid, i)
		centroid, = compute_centroid_and_measure(grid, BoundaryFaces(), i)
		return centroid[1]
	end

	component = boundaryComponents["left"]
	grid = grids[component]

	nf = number_of_boundary_faces(grid)

	bcfaceind = argmin(i -> getcoord(grid, i), 1:nf)

	couplings[component]["External"] = Dict("cells" => [1], "boundaryfaces" => [bcfaceind])

	component = boundaryComponents["right"]
	grid = grids[component]

	nf = number_of_boundary_faces(grid)
	nc = number_of_cells(grid)

	bcfaceind = argmax(i -> getcoord(grid, i), 1:nf)

	couplings[component]["External"] = Dict("cells" => [nc], "boundaryfaces" => [bcfaceind])

	return grids, couplings

end

#################################
# single layer pouch cell setup #
#################################

""" Create a single layer pouch grid
    returns two dictionaries containing the grids and the couplings.

    The fields for the `grid` dictionary are:
    + "NegativeCurrentCollector"
    + "NegativeElectrode"
    + "Separator"
    + "PositiveElectrode",
    + "PositiveCurrentCollector"

    The fields for the `couplings` dictionary are the same as `grid`. For each component, we have again a dictionary
    with field as in `grid` which provides the coupling with the two resulting components.
"""
function pouch_grid(geomparams::InputGeometryParams)

	ne_cc_z  = geomparams["NegativeElectrode"]["CurrentCollector"]["thickness"]
	ne_cc_nz = geomparams["NegativeElectrode"]["CurrentCollector"]["N"]

	ne_co_z  = geomparams["NegativeElectrode"]["Coating"]["thickness"]
	ne_co_nz = geomparams["NegativeElectrode"]["Coating"]["N"]

	pe_cc_z  = geomparams["PositiveElectrode"]["CurrentCollector"]["thickness"]
	pe_cc_nz = geomparams["PositiveElectrode"]["CurrentCollector"]["N"]

	pe_co_z  = geomparams["PositiveElectrode"]["Coating"]["thickness"]
	pe_co_nz = geomparams["PositiveElectrode"]["Coating"]["N"]

	sep_z  = geomparams["Separator"]["thickness"]
	sep_nz = geomparams["Separator"]["N"]

	x  = geomparams["Geometry"]["width"]
	y  = geomparams["Geometry"]["height"]
	nx = geomparams["Geometry"]["Nw"]
	ny = geomparams["Geometry"]["Nh"]

	ne_tab_nx = geomparams["NegativeElectrode"]["CurrentCollector"]["tab"]["Nw"]
	ne_tab_ny = geomparams["NegativeElectrode"]["CurrentCollector"]["tab"]["Nh"]
	ne_tab_x  = geomparams["NegativeElectrode"]["CurrentCollector"]["tab"]["width"]
	ne_tab_y  = geomparams["NegativeElectrode"]["CurrentCollector"]["tab"]["height"]

	pe_tab_nx = geomparams["PositiveElectrode"]["CurrentCollector"]["tab"]["Nw"]
	pe_tab_ny = geomparams["PositiveElectrode"]["CurrentCollector"]["tab"]["Nh"]
	pe_tab_x  = geomparams["PositiveElectrode"]["CurrentCollector"]["tab"]["width"]
	pe_tab_y  = geomparams["PositiveElectrode"]["CurrentCollector"]["tab"]["height"]

	nx = [ne_tab_nx, nx - (ne_tab_nx + pe_tab_nx), pe_tab_nx]
	ny = [ne_tab_ny, ny - (ne_tab_ny + pe_tab_ny), pe_tab_ny]
	nz = [ne_cc_nz, ne_co_nz, sep_nz, pe_co_nz, pe_cc_nz]

	xs = [ne_tab_x, x - (ne_tab_x + pe_tab_x), pe_tab_x]
	ys = [ne_tab_y, y - (ne_tab_y + pe_tab_y), pe_tab_y]
	zs = [ne_cc_z, ne_co_z, sep_z, pe_co_z, pe_cc_z]

	zvals = zs  # used to recover the different regions in setup_pouch_cell_geometry (see below)

	xs = xs ./ nx
	ys = ys ./ ny
	zs = zs ./ nz

	same_side = false # if true, needs pe_cc_ny >= ne_cc_ny. I think they usually are equal

	Lx = inverse_rle(xs, nx)
	Ly = inverse_rle(ys, ny)
	Lz = inverse_rle(zs, nz)

	Nx = length(Lx)
	Ny = length(Ly)
	Nz = length(Lz)

	h = CartesianMesh((Nx, Ny, Nz), (Lx, Ly, Lz))

	H_back = convert_to_mrst_grid(UnstructuredMesh(h))

	#################################################################

	# Iterators in the z-direction over horizontal layers at the end where the positive current collector is located
	pe_endbox_list_of_iterators = [Nx*(i*Ny-pe_tab_ny)+1:Nx*Ny*i for i in 1:Nz]

	# collect from previous iterator. The result is the set of cells that makes up the box-shape end of the domain (in
	# the y-direction), which includes the pe_cc tab
	pe_extra_cells = cat(pe_endbox_list_of_iterators..., dims = 1)

	# (x-y) Carthesian indices of the cells of the positive current collector tab (not expanded in the z direction)
	pe_tab_horz_index = cat([Nx*i-pe_tab_nx+1:Nx*i for i in 1:pe_tab_ny]..., dims = 1)

	# Index of the positive current collector tab.
	# 1) From the pc_cc_list_of_iterators, we take only the horizontal layer that contains tab : pe_endbox_list_of_iterators[end - pe_cc_nz + 1 : end]
	# 2) From each of these layers, we take only the cells that we have a (x, y) cartesian index in the tab region
	pe_tab_cells = cat(getindex.(pe_endbox_list_of_iterators[end-pe_cc_nz+1:end], [pe_tab_horz_index])..., dims = 1)

	# From the end of the domain (in y-direction), we remove the cells that constitutes the tab
	setdiff!(pe_extra_cells, pe_tab_cells)

	# We proceed in the same way for the negative current collector

	ne_endbox_list_of_operators = [Nx*Ny*(i-1)+1:Nx*(Ny*(i-1)+ne_tab_ny) for i in 1:Nz]
	ne_extra_cells = cat(ne_endbox_list_of_operators..., dims = 1)

	ne_tab_horz_index = cat([Nx*(i-1)+1:Nx*(i-1)+pe_tab_nx for i in 1:ne_tab_ny]..., dims = 1)

	if same_side
		ne_tab_cells = cat(getindex.(pe_endbox_list_of_iterators[1:ne_cc_nz], [ne_tab_horz_index])..., dims = 1)
		setdiff!(pe_extra_cells, ne_tab_cells)
	else
		ne_tab_cells = cat(getindex.(ne_endbox_list_of_operators[1:ne_cc_nz], [ne_tab_horz_index])..., dims = 1)
		setdiff!(ne_extra_cells, ne_tab_cells)
	end

	globalgrid, = remove_cells(H_back, vcat(pe_extra_cells, ne_extra_cells))

	grids, couplings = setup_pouch_cell_geometry(globalgrid, zvals)
	grids, couplings = convert_geometry(grids, couplings)

	# Negative current collector external coupling

	grid = grids["NegativeCurrentCollector"]

	neighbors = get_neighborship(grid; internal = false)

	bcfaces = findBoundary(grid, 2, false)
	bccells = neighbors[bcfaces]

	couplings["NegativeCurrentCollector"]["External"] = Dict("cells" => bccells, "boundaryfaces" => bcfaces)

	# Positive current collector external coupling

	grid = grids["PositiveCurrentCollector"]

	neighbors = get_neighborship(grid; internal = false)

	bcfaces = findBoundary(grid, 2, true)
	bccells = neighbors[bcfaces]

	couplings["PositiveCurrentCollector"]["External"] = Dict("cells" => bccells, "boundaryfaces" => bcfaces)

	return grids, couplings

end

s"""
Single layer pouch cell utility function
find the tags of each cell (tag from 1 to 5 for each grid component such as negative current collector and so
on). Returns a list with 5 elements, each element containing a list of cells for the corresponding tag
"""
function find_tags(h, paramsz_z)

	h_with_geo = tpfv_geometry(h)
	cut_offs = cumsum(paramsz_z)
	tag = searchsortedfirst.([cut_offs], h_with_geo.cell_centroids[3, :])
	return [findall(x -> x == i, tag) for i in 1:5]

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

	tol = 1000 * eps()

	function getcoord(i)
		centroid, = compute_centroid_and_measure(grid, BoundaryFaces(), i)
		return centroid[dim]
	end

	coord = [getcoord(i) for i in 1:nf]

	if dir
		max_min = maximum(coord)
	else
		max_min = minimum(coord)
	end

	faces = findall(abs.(coord .- max_min) .< tol)

	return faces

end

""" single layer pouch cell utility function,
From a global grid and the position of the z-values for the different components, returns the grids with the coupling.

"""
function setup_pouch_cell_geometry(H_mother, paramsz)

	grids       = Dict()
	global_maps = Dict()

	components = ["NegativeCurrentCollector",
		          "NegativeElectrode",
		          "Separator",
		          "PositiveElectrode",
		          "PositiveCurrentCollector"]

	tags = find_tags(UnstructuredMesh(H_mother), paramsz)

	grids["Global"] = UnstructuredMesh(H_mother)
	nglobal = number_of_cells(grids["Global"])
	tags = find_tags(grids["Global"], paramsz)

	# Setup the grids and mapping for all components
	allinds = 1:nglobal
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

function spiral_grid(geomparams::InputGeometryParams)

    Ns = [3, 4, 2, 6, 1]
    ls = [1., 2., 2.1, 3.2, 1.1]
    dxs = ls./Ns

    dx = mapreduce((dx, N) -> repeat([dx], N), vcat, dxs, Ns)

    spacing = [0; cumsum(dx)]
    spacing = spacing/spacing[end]
    
end



export
	pouch_grid,
	find_coupling,
	find_common,
	findBoundary,
	convert_geometry,
	one_dimensional_grid

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

##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(geomparams::InputGeometryParams)

	grids       = Dict()
	global_maps = Dict()

	include_current_collectors = geomparams["include_current_collectors"]

	faceArea = geomparams["Geometry"]["faceArea"]

	vars = ["thickness", "N"]
	vals = Dict("thickness" => Vector{Float64}(),
		"N" => Vector{Int}())

	for var in vars
		push!(vals[var], geomparams["NegativeElectrode"]["Coating"][var])
		push!(vals[var], geomparams["Separator"][var])
		push!(vals[var], geomparams["PositiveElectrode"]["Coating"][var])
	end


	if include_current_collectors

		for var in vars
			pushfirst!(vals[var], geomparams["NegativeElectrode"]["CurrentCollector"][var])
			push!(vals[var], geomparams["PositiveElectrode"]["CurrentCollector"][var])
		end

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
	x = uParentGrid.cell_centroids[1, :]
	x = [[val, i] for (i, val) in enumerate(x)]
	x = sort!(x, by = xx -> xx[1])

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

"""
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
	From a global grid and the position of the z-values for the different components, returns the grids with the coupling
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



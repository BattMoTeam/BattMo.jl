export pouch_grid

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
function pouch_grid(input)

	cell_parameters = input.cell_parameters
	simulation_settings = input.simulation_settings

	ne_cc_z  = cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"]
	ne_cc_nz = simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"]

	ne_co_z  = cell_parameters["NegativeElectrode"]["Coating"]["Thickness"]
	ne_co_nz = simulation_settings["NegativeElectrodeCoatingGridPoints"]

	pe_cc_z  = cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"]
	pe_cc_nz = simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"]

	pe_co_z  = cell_parameters["PositiveElectrode"]["Coating"]["Thickness"]
	pe_co_nz = simulation_settings["PositiveElectrodeCoatingGridPoints"]

	sep_z  = cell_parameters["Separator"]["Thickness"]
	sep_nz = simulation_settings["SeparatorGridPoints"]

	x  = cell_parameters["Cell"]["ElectrodeWidth"]
	y  = cell_parameters["Cell"]["ElectrodeLength"]
	nx = simulation_settings["ElectrodeWidthGridPoints"]
	ny = simulation_settings["ElectrodeLengthGridPoints"]

	ne_tab_nx = simulation_settings["NegativeElectrodeCurrentCollectorTabWidthGridPoints"]
	ne_tab_ny = simulation_settings["NegativeElectrodeCurrentCollectorTabLengthGridPoints"]
	ne_tab_x  = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"]
	ne_tab_y  = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabLength"]

	pe_tab_nx = simulation_settings["PositiveElectrodeCurrentCollectorTabWidthGridPoints"]
	pe_tab_ny = simulation_settings["PositiveElectrodeCurrentCollectorTabLengthGridPoints"]
	pe_tab_x  = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"]
	pe_tab_y  = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabLength"]

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
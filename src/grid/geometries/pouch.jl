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
	# -----------------------
	# Geometry and grid input
	# -----------------------
	cell_parameters     = input.cell_parameters
	simulation_settings = input.simulation_settings

	number_of_layers = cell_parameters["Cell"]["NumberOfLayers"]

	# Thickness and grid points
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

	# x-y domain extents and grid points
	x = cell_parameters["Cell"]["ElectrodeWidth"]
	y = cell_parameters["Cell"]["ElectrodeLength"]
	nx_total = simulation_settings["ElectrodeWidthGridPoints"]
	ny_total = simulation_settings["ElectrodeLengthGridPoints"]

	# Tabs
	ne_tab_nx = simulation_settings["NegativeElectrodeCurrentCollectorTabWidthGridPoints"]
	ne_tab_ny = simulation_settings["NegativeElectrodeCurrentCollectorTabLengthGridPoints"]
	ne_tab_x  = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"]
	ne_tab_y  = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabLength"]

	pe_tab_nx = simulation_settings["PositiveElectrodeCurrentCollectorTabWidthGridPoints"]
	pe_tab_ny = simulation_settings["PositiveElectrodeCurrentCollectorTabLengthGridPoints"]
	pe_tab_x  = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"]
	pe_tab_y  = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabLength"]

	# Split x and y into 3 regions: negative tab | active | positive tab
	nx = [ne_tab_nx, nx_total - (ne_tab_nx + pe_tab_nx), pe_tab_nx]
	ny = [ne_tab_ny, ny_total - (ne_tab_ny + pe_tab_ny), pe_tab_ny]
	xs = [ne_tab_x, x - (ne_tab_x + pe_tab_x), pe_tab_x]
	ys = [ne_tab_y, y - (ne_tab_y + pe_tab_y), pe_tab_y]

	# -----------------------------------------
	# z-construction: double-coated, no outer collectors
	# Per layer: NE_co, NE_cc, NE_co, SEP, PE_co, PE_cc, PE_co, (interlayer SEP)
	# -----------------------------------------
	nz_segments = Int[]
	z_segments  = Float64[]

	for i in 1:number_of_layers
		append!(nz_segments, (ne_co_nz, ne_cc_nz, ne_co_nz, sep_nz, pe_co_nz, pe_cc_nz, pe_co_nz))
		append!(z_segments, (ne_co_z, ne_cc_z, ne_co_z, sep_z, pe_co_z, pe_cc_z, pe_co_z))
		if i < number_of_layers
			append!(nz_segments, sep_nz)
			append!(z_segments, sep_z)
		end
	end

	# Keep pre-normalization segment thicknesses for tagging
	zvals = copy(z_segments)

	# Per-cell sizes
	xs = xs ./ nx
	ys = ys ./ ny
	zs_per_segment = z_segments ./ nz_segments

	# Expand to full per-cell arrays
	Lx = inverse_rle(xs, nx)
	Ly = inverse_rle(ys, ny)
	Lz = inverse_rle(zs_per_segment, nz_segments)

	Nx = length(Lx)
	Ny = length(Ly)
	Nz = length(Lz)

	# Build mesh
	h = CartesianMesh((Nx, Ny, Nz), (Lx, Ly, Lz))
	H_back = convert_to_mrst_grid(UnstructuredMesh(h))

	# --------------------------------------------------------
	# TAB CARVING (generalized to *all* CC z-layers)
	# --------------------------------------------------------
	# Build endbox indices per z-layer (same as original single-layer logic)
	#   - Positive end (y-high): last pe_tab_ny rows
	pe_endbox_layers = [(Nx*(i*Ny-pe_tab_ny)+1):(Nx*Ny*i) for i in 1:Nz]
	#   - Negative end (y-low): first ne_tab_ny rows
	ne_endbox_layers = [(Nx*Ny*(i-1)+1):(Nx*(Ny*(i-1)+ne_tab_ny)) for i in 1:Nz]

	# All endbox cells (to remove unless part of a tab corridor in CC slabs)
	pe_extra_cells = cat(pe_endbox_layers..., dims = 1)
	ne_extra_cells = cat(ne_endbox_layers..., dims = 1)

	# Tab corridors within the endbox (x selection per y-row)
	ne_tab_horz_index = cat([(Nx*(i-1)+1):(Nx*(i-1)+ne_tab_nx) for i in 1:ne_tab_ny]..., dims = 1)              # left strip
	pe_tab_horz_index = cat([(Nx*i-pe_tab_nx+1):(Nx*i) for i in 1:pe_tab_ny]..., dims = 1)          # right strip

	# --- Map segment indices -> z-layer indices ---
	S = length(z_segments)
	@assert (S + 1) % 8 == 0 "Expected double-coated pattern without outer collectors (S = 8n - 1)."
	nL = Int((S + 1) ÷ 8)
	@assert nL == number_of_layers

	# Segment indices of NE_cc / PE_cc (1-based)
	ne_cc_segments = [(1 + 8*k) + 1 for k in 0:(nL-1)]  # base = 1 + 8k; NE_cc at base+1
	pe_cc_segments = [(1 + 8*k) + 5 for k in 0:(nL-1)]  # base = 1 + 8k; PE_cc at base+5

	# z-layer start/end for each segment
	cum_nz = cumsum(nz_segments)
	seg_lo = vcat(1, cum_nz[1:(end-1)] .+ 1)
	seg_hi = cum_nz

	# Expand to z-layer indices
	ne_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in ne_cc_segments]...)
	pe_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in pe_cc_segments]...)

	# Build tab cell sets: for *each* CC z-layer, take the tab corridor inside the y-endbox
	pe_tab_cells = isempty(pe_cc_layers) ? Int[] :
				   cat(getindex.(pe_endbox_layers[pe_cc_layers], [pe_tab_horz_index])..., dims = 1)

	ne_tab_cells = isempty(ne_cc_layers) ? Int[] :
				   cat(getindex.(ne_endbox_layers[ne_cc_layers], [ne_tab_horz_index])..., dims = 1)

	# Remove endbox cells except the tab corridors (per CC layer)
	setdiff!(pe_extra_cells, pe_tab_cells)
	setdiff!(ne_extra_cells, ne_tab_cells)

	# Perform removal
	globalgrid, = remove_cells(H_back, vcat(pe_extra_cells, ne_extra_cells))

	# --------------------------------------------------------
	# Build component grids and couplings
	# --------------------------------------------------------
	grids, couplings = setup_pouch_cell_geometry(globalgrid, zvals)
	grids, couplings = convert_geometry(grids, couplings)

	# External couplings for outer faces (unchanged)
	#   Negative CC: boundary at y-low (false), Positive CC: y-high (true)
	for (comp, side) in [("NegativeCurrentCollector", false), ("PositiveCurrentCollector", true)]
		grid = grids[comp]
		neighbors = get_neighborship(grid; internal = false)
		bcfaces = findBoundary(grid, 2, side)
		bccells = neighbors[bcfaces]
		couplings[comp]["External"] = Dict("cells" => bccells, "boundaryfaces" => bcfaces)
	end

	return grids, couplings
end



"""
Multilayer pouch cell utility function
Find the tags of each cell (tag from 1 to 5 for each grid component such as negative current collector and so on).
Returns a list with 5 elements, each element containing a list of cells for the corresponding component.
"""
function find_tags(h, paramsz_z)

	# Compute geometry and z-centroids
	h_with_geo = tpfv_geometry(h)
	z_centroids = h_with_geo.cell_centroids[3, :]

	# Compute cumulative cut-offs for each z-segment
	cut_offs = cumsum(paramsz_z)
	S = length(cut_offs)

	# Tag each cell by segment index (1-based)
	segment_tag = searchsortedfirst.([cut_offs], z_centroids)

	# Infer number of layers
	S = length(paramsz_z)

	@assert (S + 1) % 8 == 0 "paramsz_z does not match expected multilayer pattern"
	number_of_layers = Int((S + 1) ÷ 8)

	# Segment indices
	ne_cc_segs = Int[]
	ne_co_segs = Int[]
	sep_segs   = Int[]
	pe_co_segs = Int[]
	pe_cc_segs = Int[]

	for k in 0:(number_of_layers-1)
		base = 1 + 8*k
		# NE coatings and NE collector
		push!(ne_co_segs, base + 0, base + 2)
		push!(ne_cc_segs, base + 1)
		# Separator(s)
		push!(sep_segs, base + 3)
		if k < number_of_layers - 1
			push!(sep_segs, base + 7) # interlayer SEP
		end
		# PE coatings and PE collector
		push!(pe_co_segs, base + 4, base + 6)
		push!(pe_cc_segs, base + 5)
	end

	# Aggregate tags into 5 logical groups
	tags = Vector{Vector{Int}}(undef, 5)
	tags[1] = findall(x -> x in ne_cc_segs, segment_tag)
	tags[2] = findall(x -> x in ne_co_segs, segment_tag)
	tags[3] = findall(x -> x in sep_segs, segment_tag)
	tags[4] = findall(x -> x in pe_co_segs, segment_tag)
	tags[5] = findall(x -> x in pe_cc_segs, segment_tag)

	return tags
end

# """
# Single layer pouch cell utility function
# find the tags of each cell (tag from 1 to 5 for each grid component such as negative current collector and so
# on). Returns a list with 5 elements, each element containing a list of cells for the corresponding tag
# """
# function find_tags(h, paramsz_z)

# 	h_with_geo = tpfv_geometry(h)
# 	cut_offs = cumsum(paramsz_z)
# 	tag = searchsortedfirst.([cut_offs], h_with_geo.cell_centroids[3, :])
# 	return [findall(x -> x == i, tag) for i in 1:5]

# end

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
	grids       = Dict{String, Any}()
	global_maps = Dict{String, Any}()

	components = [
		"NegativeCurrentCollector",
		"NegativeElectrode",
		"Separator",
		"PositiveElectrode",
		"PositiveCurrentCollector",
	]

	# Mother grid
	grids["Global"] = UnstructuredMesh(H_mother)
	nglobal = number_of_cells(grids["Global"])

	# Get grouped tags directly (length 5)
	grouped_tags = find_tags(grids["Global"], paramsz)

	# Build per-component grids
	allinds = 1:nglobal
	for (i, comp) in enumerate(components)
		keep = grouped_tags[i]
		G, maps... = remove_cells(H_mother, setdiff(allinds, keep))
		grids[comp] = G
		global_maps[comp] = maps
	end

	# Electrolyte = NE + SEP + PE
	electrolyte_cells = vcat(grouped_tags[2], grouped_tags[3], grouped_tags[4])
	G_elec, maps_elec... = remove_cells(H_mother, setdiff(allinds, electrolyte_cells))
	grids["Electrolyte"] = G_elec
	global_maps["Electrolyte"] = maps_elec

	push!(components, "Electrolyte")

	# Couplings from intersections
	couplings = setup_couplings(components, grids, global_maps)

	return grids, couplings
end



#################################
# multi layer pouch cell setup #
#################################
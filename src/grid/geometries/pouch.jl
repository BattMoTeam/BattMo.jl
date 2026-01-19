export pouch_grid

#################################
# Multi layer pouch cell setup #
#################################

"""
Create a multilayer pouch cell grid with flexible tab placement.

Features:
- Double-coated multilayer stack *without* outer collectors.
  Per layer (z-segments): NE_coating | NE_CC | NE_coating | Separator | PE_coating | PE_CC | PE_coating | (interlayer Separator)
- Tabs (in y-direction) can be on the same side or on opposite sides.
- Each current collector has its own tab position *fraction across the x-width*.
- Tab size in grid-points comes from simulation settings; physical sizes are used to set per-cell sizes.

Returns:
- `grids`: component grids for NegativeCurrentCollector, NegativeElectrode, Separator, PositiveElectrode, PositiveCurrentCollector, Electrolyte
- `couplings`: coupling information between components
"""
function pouch_grid(input)
	# --------------------------------------------------------
	# 1) Read inputs
	# --------------------------------------------------------
	cell_parameters     = input.cell_parameters
	simulation_settings = input.simulation_settings

	# Number of repeated cell layers (in z)
	num_layers = cell_parameters["Cell"]["NumberOfLayers"]
	double_coated = get(cell_parameters["Cell"], "DoubleCoatedElectrodes", true)

	if num_layers > 1
		extra_ne = true
	else
		extra_ne = false
	end

	if haskey(cell_parameters["Cell"], "CloseOffWithNegativeElectrode")
		extra_ne = cell_parameters["Cell"]["CloseOffWithNegativeElectrode"]
	else
		extra_ne = extra_ne
	end

	if num_layers > 1 && double_coated == false
		error("A multi-layer pouch cannot have single coated electrodes.")
	end

	if num_layers == 1 && extra_ne == true
		error("A single-layer pouch cannot be closed off with an extra negative electrode.")
	end

	# --- Tab placement configuration ---
	# If true, both NE and PE tabs are placed on the same y-edge (top or bottom).
	# If false, NE tab goes on y-low and PE tab goes on y-high (classic opposite-sides layout).
	tabs_on_same_side = get(cell_parameters["Cell"], "TabsOnSameSide", false)

	# Independent horizontal tab positions (fractions across the x-width).
	neg_tab_position_fraction = get(cell_parameters["NegativeElectrode"]["CurrentCollector"], "TabPositionFraction", 0.2)
	pos_tab_position_fraction = get(cell_parameters["PositiveElectrode"]["CurrentCollector"], "TabPositionFraction", 0.8)

	# When tabs_on_same_side = true, this chooses which y-edge to use for both tabs.
	# Accepted values: "top" (y-high) or "bottom" (y-low)
	same_side_y_side = "top"

	# --------------------------------------------------------
	# 2) Material thickness (z) and resolution (grid points)
	#    These define the vertical (z) stacking of layers.
	# --------------------------------------------------------
	neg_cc_thickness = cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"]
	neg_cc_points    = simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"]

	neg_coating_thickness = cell_parameters["NegativeElectrode"]["Coating"]["Thickness"]
	neg_coating_points    = simulation_settings["NegativeElectrodeCoatingGridPoints"]

	pos_cc_thickness = cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"]
	pos_cc_points    = simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"]

	pos_coating_thickness = cell_parameters["PositiveElectrode"]["Coating"]["Thickness"]
	pos_coating_points    = simulation_settings["PositiveElectrodeCoatingGridPoints"]

	separator_thickness = cell_parameters["Separator"]["Thickness"]
	separator_points    = simulation_settings["SeparatorGridPoints"]

	# --------------------------------------------------------
	# 3) Cell planform (x-y) size and resolution
	#    width_points/length_points are the total number of cells in each direction.
	# --------------------------------------------------------
	electrode_width  = cell_parameters["Cell"]["ElectrodeWidth"]
	electrode_length = cell_parameters["Cell"]["ElectrodeLength"]
	width_points     = simulation_settings["ElectrodeWidthGridPoints"]
	length_points    = simulation_settings["ElectrodeLengthGridPoints"]

	# --------------------------------------------------------
	# 4) Tab physical sizes and *grid-point* sizes
	#    The grid-point sizes control endbox thickness and tab corridor thickness.
	#    The physical sizes are used for per-cell size computation in the mesh.
	# --------------------------------------------------------
	neg_tab_width_points  = simulation_settings["NegativeElectrodeCurrentCollectorTabWidthGridPoints"]
	neg_tab_length_points = simulation_settings["NegativeElectrodeCurrentCollectorTabLengthGridPoints"]
	neg_tab_width         = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"]
	neg_tab_length        = cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabLength"]

	pos_tab_width_points  = simulation_settings["PositiveElectrodeCurrentCollectorTabWidthGridPoints"]
	pos_tab_length_points = simulation_settings["PositiveElectrodeCurrentCollectorTabLengthGridPoints"]
	pos_tab_width         = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"]
	pos_tab_length        = cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabLength"]

	# --------------------------------------------------------
	# 5) x/y segmentation for per-cell size setup (mesh geometry only)
	# --------------------------------------------------------
	width_segments  = [
	neg_tab_width_points,
	width_points - (neg_tab_width_points + pos_tab_width_points),
	pos_tab_width_points
]
	length_segments = [
	neg_tab_length_points,
	length_points - (neg_tab_length_points + pos_tab_length_points),
	pos_tab_length_points
]

	# Physical sizes associated with the segments above (sum to total width/length)
	width_sizes  = [neg_tab_width, electrode_width - (neg_tab_width + pos_tab_width), pos_tab_width]
	length_sizes = [neg_tab_length, electrode_length - (neg_tab_length + pos_tab_length), pos_tab_length]

	# --------------------------------------------------------
	# 6) Build z-direction (thickness) segments.
	#	 
	#	 One layer double coated: NE_co | NE_cc | NE_co | SEP | PE_co | PE_cc | PE_co 
	#	 One layer single coated: NE_cc | NE_co | SEP | PE_co | PE_cc 
	#
	# 	 Multi-layer double coated:
	#     - Per layer: NE_co | NE_cc | NE_co | SEP | PE_co | PE_cc | PE_co | (interlayer SEP)
	# 	  - Extra NE at the top: | SEP | NE_co | NE_cc | NE_co
	#
	#    We collect (z_points_per_segment, z_thickness_per_segment) for the whole stack.
	# --------------------------------------------------------
	z_points_per_segment    = Int[]
	z_thickness_per_segment = Float64[]

	if double_coated == true

		for layer in 1:num_layers
			append!(z_points_per_segment, (
				neg_coating_points, neg_cc_points, neg_coating_points,
				separator_points,
				pos_coating_points, pos_cc_points, pos_coating_points,
			))
			append!(z_thickness_per_segment, (
				neg_coating_thickness, neg_cc_thickness, neg_coating_thickness,
				separator_thickness,
				pos_coating_thickness, pos_cc_thickness, pos_coating_thickness,
			))

			# Interlayer separator between repeated stacks
			if layer < num_layers
				append!(z_points_per_segment, separator_points)
				append!(z_thickness_per_segment, separator_thickness)
			end
		end
		if extra_ne == true
			append!(z_points_per_segment, separator_points, neg_coating_points, neg_cc_points, neg_coating_points)
			append!(z_thickness_per_segment, separator_thickness, neg_coating_thickness, neg_cc_thickness, neg_coating_thickness)
		end
	else

		append!(z_points_per_segment, (
			neg_cc_points, neg_coating_points,
			separator_points,
			pos_coating_points, pos_cc_points,
		))
		append!(z_thickness_per_segment, (
			neg_cc_thickness, neg_coating_thickness,
			separator_thickness,
			pos_coating_thickness, pos_cc_thickness,
		))
	end

	# Keep a copy of the physical segment thicknesses for later region tagging
	z_segment_thicknesses = copy(z_thickness_per_segment)

	# --------------------------------------------------------
	# 7) Create per-cell size arrays (inverse RLE) and build the mesh
	#    - width_sizes_per_cell: size of each x-cell
	#    - length_sizes_per_cell: size of each y-cell
	#    - z_sizes_per_cell: size of each z-cell
	#    Then expands them to full vectors over the whole mesh.
	# --------------------------------------------------------
	width_sizes_per_cell  = width_sizes ./ width_segments
	length_sizes_per_cell = length_sizes ./ length_segments
	z_sizes_per_cell      = z_thickness_per_segment ./ z_points_per_segment

	cell_widths  = inverse_rle(width_sizes_per_cell, width_segments)
	cell_lengths = inverse_rle(length_sizes_per_cell, length_segments)
	cell_heights = inverse_rle(z_sizes_per_cell, z_points_per_segment)

	Nx = length(cell_widths)   # number of cells along x
	Ny = length(cell_lengths)  # number of cells along y
	Nz = length(cell_heights)  # number of cells along z

	# Build a Cartesian mesh and convert to MRST-style raw grid
	mesh     = CartesianMesh((Nx, Ny, Nz), (cell_widths, cell_lengths, cell_heights))
	raw_grid = convert_to_mrst_grid(UnstructuredMesh(mesh))

	# --------------------------------------------------------
	# 8) TAB CARVING (y-direction endboxes + x-direction corridors)
	#
	#    IDEA:
	#      - For each z-layer that belongs to a CURRENT COLLECTOR segment, we keep a rectangular
	#        "tab corridor" at the y-edge (top for PE, bottom for NE unless same-side requested)
	#        and remove the rest of the y-endboxes in that layer.
	#
	#    HOW:
	#      - Build the y-endbox cell ranges for *every* z-layer.
	#      - Compute x-columns for the tab corridor based on a fraction across Nx.
	#      - Keep only the intersection (endbox ∩ corridor) for CC layers.
	# --------------------------------------------------------

	# Helper: produce tab corridor indices *within a single x-y layer* (local indices 1..Nx*Ny).
	# Arguments:
	#   - tab_w: number of columns to keep (width of the tab corridor)
	#   - tab_l: number of rows from the y-edge to keep (length of the tab corridor)
	#   - frac : fractional horizontal position across Nx (0..1 across the whole x span in this version)
	#   - y_side: "bottom" → rows 1:tab_l, "top" → rows (Ny-tab_l+1):Ny

	compute_tab_indices_local = function (Nx::Int, Ny::Int,
		tab_w::Int, tab_l::Int,
		frac::Float64; y_side::String = "top",
		align::Symbol = :left)
		# Map fraction -> x columns
		if align == :center
			# Center-based mapping: 0..1 maps to centers in [1..Nx]
			col_center = clamp(round(Int, frac * (Nx - 1)) + 1, 1, Nx)
			col_start  = clamp(col_center - div(tab_w, 2), 1, max(1, Nx - tab_w + 1))
			col_stop   = min(col_start + tab_w - 1, Nx)
		else
			# Left-edge-based mapping (recommended for tabs): 0..1 maps to starts in [1..Nx - tab_w + 1]
			col_start = clamp(round(Int, frac * (Nx - tab_w)) + 1, 1, max(1, Nx - tab_w + 1))
			col_stop  = col_start + tab_w - 1
		end

		# Select rows at the requested y-edge
		rows = (y_side == "bottom") ? (1:tab_l) : ((Ny-tab_l+1):Ny)

		# Build local linear indices
		return vcat([(Nx * (r - 1) .+ (col_start:col_stop)) for r in rows]...)
	end


	neg_endbox_bottom = [(Nx*Ny*(i-1)+1):(Nx*(Ny*(i-1)+neg_tab_length_points)) for i in 1:Nz]
	neg_endbox_top    = [(Nx*(i*Ny-neg_tab_length_points)+1):(Nx*Ny*i) for i in 1:Nz]

	pos_endbox_top    = [(Nx*(i*Ny-pos_tab_length_points)+1):(Nx*Ny*i) for i in 1:Nz]
	pos_endbox_bottom = [(Nx*Ny*(i-1)+1):(Nx*(Ny*(i-1)+pos_tab_length_points)) for i in 1:Nz]

	# Final assignment based on tab configuration

	if tabs_on_same_side
		if same_side_y_side == "top"
			neg_endbox_per_layer = neg_endbox_top       # NE on top
			pos_endbox_per_layer = pos_endbox_top       # PE on top
			neg_y_side = "top"                          # MATCH
			pos_y_side = "top"
		else # "bottom"
			neg_endbox_per_layer = neg_endbox_bottom    # NE bottom
			pos_endbox_per_layer = pos_endbox_bottom    # PE bottom
			neg_y_side = "bottom"                       # MATCH
			pos_y_side = "bottom"
		end
	else
		# Opposite sides
		neg_endbox_per_layer = neg_endbox_bottom        # NE bottom
		pos_endbox_per_layer = pos_endbox_top           # PE top
		neg_y_side = "bottom"                           # MATCH
		pos_y_side = "top"
	end


	# Identify which z-segments are NE/PE CC and convert them to z-layer indices
	total_segments = length(z_thickness_per_segment)

	if double_coated == true
		neg_cc_segments = [(1 + 8 * k) + 1 for k in 0:(num_layers-1)]  # NE_cc at base+1 (base = 1+8k)
		pos_cc_segments = [(1 + 8 * k) + 5 for k in 0:(num_layers-1)]  # PE_cc at base+5

		if num_layers > 1
			if extra_ne == true
				push!(neg_cc_segments, total_segments - 1)  # <- this is the extra NE_cc
			end
		end
	else
		neg_cc_segments = [(1 + 8 * k) + 0 for k in 0:(num_layers-1)]  # NE_cc at base+1 (base = 1+8k)
		pos_cc_segments = [(1 + 8 * k) + 4 for k in 0:(num_layers-1)]  # PE_cc at base+5

	end

	# Map z-segment indices to [start:stop] z-layer ranges using cumulative z-points
	cum_points = cumsum(z_points_per_segment)
	seg_lo = vcat(1, cum_points[1:(end-1)] .+ 1)
	seg_hi = cum_points

	neg_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in neg_cc_segments]...)
	pos_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in pos_cc_segments]...)

	# # y-side selection based on same-side vs opposite-side configuration
	# # - When opposite: NE bottom / PE top
	# # - When same: both use same_side_y_side ("bottom" or "top")
	# neg_y_side = tabs_on_same_side ? same_side_y_side : "bottom"
	# pos_y_side = tabs_on_same_side ? same_side_y_side : "top"

	# Build local corridors (same x/y rectangle applied to each relevant z-layer)
	neg_tab_corridor_local = compute_tab_indices_local(Nx, Ny, neg_tab_width_points, neg_tab_length_points, neg_tab_position_fraction; y_side = neg_y_side)
	pos_tab_corridor_local = compute_tab_indices_local(Nx, Ny, pos_tab_width_points, pos_tab_length_points, pos_tab_position_fraction; y_side = pos_y_side)

	# Convert each local corridor to absolute indices (per z-layer) and intersect with that layer's endbox rows
	neg_tab_cells = Int[]
	pos_tab_cells = Int[]

	for layer in neg_cc_layers
		z_offset     = (layer - 1) * Nx * Ny
		corridor_abs = z_offset .+ neg_tab_corridor_local
		keep_cells   = intersect(neg_endbox_per_layer[layer], corridor_abs)  # restrict to y-endbox rows
		append!(neg_tab_cells, keep_cells)
	end

	for layer in pos_cc_layers
		z_offset     = (layer - 1) * Nx * Ny
		corridor_abs = z_offset .+ pos_tab_corridor_local
		keep_cells   = intersect(pos_endbox_per_layer[layer], corridor_abs)
		append!(pos_tab_cells, keep_cells)
	end

	# Remove all endbox cells EXCEPT those in tab corridors (kept)

	pos_endbox_all = vcat(pos_endbox_per_layer...)
	neg_endbox_all = vcat(neg_endbox_per_layer...)
	endbox_all     = union(pos_endbox_all, neg_endbox_all)  # protects against overlap

	# Build "cells to keep": union of both corridors
	keep_cells = union(neg_tab_cells, pos_tab_cells)

	# Final removal set: ONLY endbox cells that are not in any corridor
	cells_to_remove = sort!(collect(setdiff(endbox_all, keep_cells)))

	# (Optional sanity)
	@assert !isempty(cells_to_remove)
	@assert all(1 .<= cells_to_remove .<= Nx*Ny*Nz)




	global_grid, = remove_cells(raw_grid, cells_to_remove)

	# ------------------------------------------------------------------
	# (Optional) NOTE on "active-width normalization" for tab fractions:
	#
	# If you want the tab fraction (0..1) to map between the *edges of the
	# active width only* (i.e., from after the NE tab zone to before the PE tab zone),
	# replace compute_tab_indices_local(...) with a version that computes column
	# centers from:
	#
	#   active_width_mm = electrode_width - (neg_tab_width + pos_tab_width)
	#   position_mm     = neg_tab_width + frac * active_width_mm
	#   col_center      = round(Int, position_mm / electrode_width * Nx)
	#
	# This makes `frac=0.0` align with the start of the active area and `frac=1.0`
	# with the end of the active area (more intuitive for symmetric placement).
	# ------------------------------------------------------------------

	# --------------------------------------------------------
	# 9) Build component sub-grids and couplings
	#    - setup_pouch_cell_geometry tags CC / coatings / separator regions
	#    - convert_geometry maps MRST faces -> Jutul boundary faces and preserves couplings
	# --------------------------------------------------------
	grids, couplings = setup_pouch_cell_geometry(global_grid, z_segment_thicknesses, extra_ne, double_coated)
	grids, couplings = convert_geometry(grids, couplings)

	# External couplings on outer faces for CCs:
	# - NegativeCurrentCollector boundary at y-low (false)
	# - PositiveCurrentCollector boundary at y-high (true)
	for (component, side_is_high) in [("NegativeCurrentCollector", false), ("PositiveCurrentCollector", true)]
		grid = grids[component]
		neighbors = get_neighborship(grid; internal = false)
		boundary_faces = findBoundary(grid, 2, side_is_high)
		boundary_cells = neighbors[boundary_faces]
		couplings[component]["External"] = Dict("cells" => boundary_cells, "boundaryfaces" => boundary_faces)
	end

	return grids, couplings
end




"""
Multilayer pouch cell utility function
Find the tags of each cell (tag from 1 to 5 for each grid component such as negative current collector and so on).
Returns a list with 5 elements, each element containing a list of cells for the corresponding component.
"""

function find_tags(h, paramsz_z; extra_ne::Bool = true, double_coated = true)

	# Geometry / centroids
	h_with_geo = tpfv_geometry(h)
	z_centroids = h_with_geo.cell_centroids[3, :]

	cut_offs = cumsum(paramsz_z)
	S = length(cut_offs)
	segment_tag = searchsortedfirst.([cut_offs], z_centroids)

	# -----------------------------------------
	# Infer number of layers depending on pattern
	# -----------------------------------------
	if double_coated == true

		if extra_ne
			@assert (S - 3) % 8 == 0 "paramsz_z does not match expected extra-NE multilayer pattern"
			number_of_layers = Int((S - 3) ÷ 8) + 1
		else
			@assert (S + 1) % 8 == 0 "paramsz_z does not match expected multilayer pattern"
			number_of_layers = Int((S + 1) ÷ 8)
		end

	else

		@assert (S + 1) % 6 == 0 "paramsz_z does not match expected multilayer pattern"
		number_of_layers = Int((S + 1) ÷ 6)


	end

	# Output groups
	ne_cc_segs = Int[]
	ne_co_segs = Int[]
	sep_segs   = Int[]
	pe_co_segs = Int[]
	pe_cc_segs = Int[]

	# -----------------------------------------
	# Build segmentation rules
	# -----------------------------------------
	if double_coated == true

		if !extra_ne
			# -----------------------------
			# Standard pattern (original)
			# -----------------------------
			for k in 0:(number_of_layers-1)
				base = 1 + 8*k
				# NE triple
				push!(ne_co_segs, base + 0, base + 2)
				push!(ne_cc_segs, base + 1)
				# Separator
				push!(sep_segs, base + 3)
				if k < number_of_layers - 1
					push!(sep_segs, base + 7)
				end
				# PE block
				push!(pe_co_segs, base + 4, base + 6)
				push!(pe_cc_segs, base + 5)
			end

		else
			# -----------------------------
			# Extended NE-ending pattern
			# -----------------------------
			# (number_of_layers - 1) full layers
			for k in 0:(number_of_layers-2)
				base = 1 + 8*k
				# NE triple
				push!(ne_co_segs, base + 0, base + 2)
				push!(ne_cc_segs, base + 1)
				# SEP
				push!(sep_segs, base + 3)
				# PE block
				push!(pe_co_segs, base + 4, base + 6)
				push!(pe_cc_segs, base + 5)
				# Interlayer SEP
				push!(sep_segs, base + 7)
			end

			# Final block: SEP | NE_co | NE_cc | NE_co
			final_base = S-3
			push!(sep_segs, final_base + 0)
			push!(ne_co_segs, final_base + 1, final_base + 3)
			push!(ne_cc_segs, final_base + 2)
		end
	else
		for k in 0:(number_of_layers-1)
			base = 1 + 6*k
			# NE triple
			push!(ne_cc_segs, base + 0)
			push!(ne_co_segs, base + 1)
			# Separator
			push!(sep_segs, base + 2)
			# PE block
			push!(pe_co_segs, base + 3)
			push!(pe_cc_segs, base + 4)


		end
	end

	# -----------------------------------------
	# Build final tag groups
	# -----------------------------------------
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

function setup_pouch_cell_geometry(H_mother, paramsz, extra_ne, double_coated)
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
	grouped_tags = find_tags(grids["Global"], paramsz; extra_ne, double_coated)

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


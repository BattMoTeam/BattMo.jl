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
	num_layers = cell_parameters["Cell"]["NumberOfLayersInParallel"]
	double_coated = get(cell_parameters["Cell"], "DoubleCoatedElectrodes", true)

	extra_ne = num_layers > 1
	if haskey(cell_parameters["Cell"], "CloseOffWithNegativeElectrode")
		extra_ne = cell_parameters["Cell"]["CloseOffWithNegativeElectrode"]
	end

	if num_layers > 1 && double_coated == false
		error("A multi-layer pouch cannot have single coated electrodes.")
	end

	if num_layers == 1 && extra_ne == true
		error("A single-layer pouch cannot be closed off with an extra negative electrode.")
	end

	# --- Tab placement configuration ---
	tabs_on_same_side = get(cell_parameters["Cell"], "TabsOnSameSide", false)
	neg_tab_pos_frac = get(cell_parameters["NegativeElectrode"]["CurrentCollector"], "TabPositionFraction", 0.2)
	pos_tab_pos_frac = get(cell_parameters["PositiveElectrode"]["CurrentCollector"], "TabPositionFraction", 0.8)
	same_side_y_side = "top"

	# --------------------------------------------------------
	# 2) Material thickness (z)
	# --------------------------------------------------------
	neg_cc_thickness      = cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"]
	neg_cc_points         = simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"]
	neg_coating_thickness = cell_parameters["NegativeElectrode"]["Coating"]["Thickness"]
	neg_coating_points    = simulation_settings["NegativeElectrodeCoatingGridPoints"]

	pos_cc_thickness      = cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"]
	pos_cc_points         = simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"]
	pos_coating_thickness = cell_parameters["PositiveElectrode"]["Coating"]["Thickness"]
	pos_coating_points    = simulation_settings["PositiveElectrodeCoatingGridPoints"]

	separator_thickness = cell_parameters["Separator"]["Thickness"]
	separator_points    = simulation_settings["SeparatorGridPoints"]

	# --------------------------------------------------------
	# 3) Electrode planform
	# --------------------------------------------------------
	electrode_width  = cell_parameters["Cell"]["ElectrodeWidth"]
	electrode_length = cell_parameters["Cell"]["ElectrodeLength"]
	width_points     = simulation_settings["ElectrodeWidthGridPoints"]
	length_points    = simulation_settings["ElectrodeLengthGridPoints"]

	# --------------------------------------------------------
	# 4) Tab physical sizes & grid points
	# --------------------------------------------------------

	# --- Unified tab width and grid resolution ---
	tab_width_points  = simulation_settings["TabWidthGridPoints"]
	tab_width         = cell_parameters["Cell"]["TabWidth"]
	tab_length_points = simulation_settings["TabLengthGridPoints"]
	tab_length        = cell_parameters["Cell"]["TabLength"]

	# Apply identical width to both electrodes
	neg_tab_width = tab_width
	pos_tab_width = tab_width
	neg_tab_width_points = tab_width_points
	pos_tab_width_points = tab_width_points

	# Tab lengths remain separate unless you want them unified:
	neg_tab_length_points = tab_length_points
	neg_tab_length        = tab_length

	pos_tab_length_points = tab_length_points
	pos_tab_length        = tab_length

	# --------------------------------------------------------
	# 5) X-direction segmentation with tabs anywhere
	# --------------------------------------------------------
	# Compute tab start/end fractions in electrode width
	neg_tab_start_frac = clamp(neg_tab_pos_frac - 0.5 * neg_tab_width / electrode_width, 0.0, 1.0)
	neg_tab_end_frac   = clamp(neg_tab_pos_frac + 0.5 * neg_tab_width / electrode_width, 0.0, 1.0)

	pos_tab_start_frac = clamp(pos_tab_pos_frac - 0.5 * pos_tab_width / electrode_width, 0.0, 1.0)
	pos_tab_end_frac   = clamp(pos_tab_pos_frac + 0.5 * pos_tab_width / electrode_width, 0.0, 1.0)

	if neg_tab_pos_frac <= pos_tab_pos_frac
		left_tab_start_frac = neg_tab_start_frac
		left_tab_end_frac = neg_tab_end_frac
		right_tab_start_frac = pos_tab_start_frac
		right_tab_end_frac = pos_tab_end_frac
		left_tab = "NegativeElectrode"
	else
		left_tab_start_frac = pos_tab_start_frac
		left_tab_end_frac = pos_tab_end_frac
		right_tab_start_frac = neg_tab_start_frac
		right_tab_end_frac = neg_tab_end_frac
		left_tab = "PositiveElectrode"
	end


	middle_active_frac = (right_tab_start_frac - left_tab_end_frac)

	if middle_active_frac > 0
		# Tabs do not overlap
		middle_active_width = clamp((right_tab_start_frac - left_tab_end_frac) * electrode_width, 0, electrode_width)
		overlapping_tab_width = 0.0
		left_tab_width = tab_width
		right_tab_width = tab_width
	else
		# Tabs overlap
		overlapping_tab_width = abs(right_tab_start_frac - left_tab_end_frac) * electrode_width
		left_tab_width = clamp((left_tab_end_frac - left_tab_start_frac) * electrode_width - overlapping_tab_width, 0, electrode_width) # NE tab remainder
		right_tab_width = clamp((right_tab_end_frac - right_tab_start_frac) * electrode_width - overlapping_tab_width, 0, electrode_width) # PE tab remainder
		middle_active_width = 0.0
	end

	# Define segment widths in x-direction (total 5 segments if no overlap, 6 segments if partly overlap, 3 segments if full overlap)
	# 1: left active, 2: left tab remainder, 3: middle active,
	# 4: overlap,     5: right tab remainder, 6: right active

	segment_widths = [
		left_tab_start_frac * electrode_width,                 # left active
		left_tab_width,                                # NE tab remainder 
		middle_active_width, # middle active
		overlapping_tab_width,                                  # overlapping tabs (if any)
		right_tab_width,# PE tab remainder 
		(1.0 - right_tab_end_frac) * electrode_width,            # right active
	]

	# Assign grid points to segments
	remaining_points = width_points - (neg_tab_width_points + pos_tab_width_points)
	tab_cell_width = tab_width / tab_width_points
	overlapping_tab_width_points = round(Int, segment_widths[4] / tab_cell_width)
	left_tab_width_points = round(Int, tab_width_points-overlapping_tab_width_points)
	right_tab_width_points = round(Int, tab_width_points-overlapping_tab_width_points)

	segment_points = [
		round(Int, (segment_widths[1] / sum(segment_widths[[1, 3, 6]])) * remaining_points),
		left_tab_width_points,
		round(Int, (segment_widths[3] / sum(segment_widths[[1, 3, 6]])) * remaining_points),
		overlapping_tab_width_points,
		right_tab_width_points,
		remaining_points - round(Int, (segment_widths[1] / sum(segment_widths[[1, 3, 6]])) * remaining_points) - round(Int, (segment_widths[3] / sum(segment_widths[[1, 3, 6]])) * remaining_points),
	]

	width_sizes_per_cell = segment_widths ./ segment_points

	# --------------------------------------------------------
	# 6) Length segmentation (y-direction)
	# --------------------------------------------------------

	if tabs_on_same_side
		active_points = length_points
		active_length = electrode_length

		tab_strip_length        = max(neg_tab_length, pos_tab_length)
		tab_strip_length_points = max(neg_tab_length_points, pos_tab_length_points)

		if lowercase(same_side_y_side) == "bottom"
			# bottom: TAB STRIP → ACTIVE
			length_segments = [
				tab_strip_length_points,
				active_points,
			]
			length_sizes = [
				tab_strip_length,
				active_length,
			]
		else
			# top: ACTIVE → TAB STRIP
			length_segments = [
				active_points,
				tab_strip_length_points,
			]
			length_sizes = [
				active_length,
				tab_strip_length,
			]
		end
	else
		# Opposite-side behavior (unchanged)
		active_points = length_points
		active_length = electrode_length

		length_segments = [
			neg_tab_length_points,
			active_points,
			pos_tab_length_points,
		]
		length_sizes = [
			neg_tab_length,
			active_length,
			pos_tab_length,
		]
	end


	length_sizes_per_cell = length_sizes ./ length_segments

	# --------------------------------------------------------
	# 7) Build z-direction (thickness) segments
	# --------------------------------------------------------
	z_points_per_segment = Int[]
	z_thickness_per_segment = Float64[]

	if double_coated
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
			if layer < num_layers
				append!(z_points_per_segment, separator_points)
				append!(z_thickness_per_segment, separator_thickness)
			end
		end
		if extra_ne
			append!(z_points_per_segment, separator_points, neg_coating_points, neg_cc_points, neg_coating_points)
			append!(z_thickness_per_segment, separator_thickness, neg_coating_thickness, neg_cc_thickness, neg_coating_thickness)
		end
	else
		append!(z_points_per_segment, (neg_cc_points, neg_coating_points, separator_points, pos_coating_points, pos_cc_points))
		append!(z_thickness_per_segment, (neg_cc_thickness, neg_coating_thickness, separator_thickness, pos_coating_thickness, pos_cc_thickness))
	end

	z_sizes_per_cell = z_thickness_per_segment ./ z_points_per_segment

	# --------------------------------------------------------
	# 8) Expand per-cell sizes
	# --------------------------------------------------------
	cell_widths  = inverse_rle(width_sizes_per_cell, segment_points)
	cell_lengths = inverse_rle(length_sizes_per_cell, length_segments)
	cell_heights = inverse_rle(z_sizes_per_cell, z_points_per_segment)

	Nx = length(cell_widths)
	Ny = length(cell_lengths)
	Nz = length(cell_heights)

	mesh = CartesianMesh((Nx, Ny, Nz), (cell_widths, cell_lengths, cell_heights))
	raw_grid = convert_to_mrst_grid(UnstructuredMesh(mesh))

	# --------------------------------------------------------
	# 9) TAB CARVING
	# --------------------------------------------------------

	# Compute tab start indices (x-direction)
	left_tab_start_idx  = sum(segment_points[1:1]) + 1      # start of segment 2
	right_tab_start_idx = sum(segment_points[1:4]) + 1      # start of segment 5

	# Determine tab sides
	if tabs_on_same_side
		neg_y_side = same_side_y_side
		pos_y_side = same_side_y_side
	else
		neg_y_side = "bottom"
		pos_y_side = "top"
	end

	# ---------------------------------------------
	# Build y-row ranges for each tab (critical part)
	# ---------------------------------------------


	if tabs_on_same_side
		if lowercase(same_side_y_side) == "bottom"
			# Both start at row 1
			neg_rows = 1:neg_tab_length_points
			pos_rows = 1:pos_tab_length_points
		else
			# Both start at the electrode top boundary:
			strip_bottom = Ny - max(neg_tab_length_points, pos_tab_length_points) + 1

			neg_rows = (strip_bottom):(strip_bottom+neg_tab_length_points-1)

			pos_rows = (strip_bottom):(strip_bottom+pos_tab_length_points-1)
		end
	else
		# Original (opposite-side) behavior
		neg_rows = 1:neg_tab_length_points
		pos_rows = (Ny-pos_tab_length_points+1):Ny
	end

	# Compute the corridors using y-row ranges
	neg_tab_local = compute_tab_indices_local(
		segment_points, "NegativeElectrode", tabs_on_same_side,
		Nx, Ny, neg_tab_length_points, neg_y_side;
		row_range = neg_rows,
	)

	pos_tab_local = compute_tab_indices_local(
		segment_points, "PositiveElectrode", tabs_on_same_side,
		Nx, Ny, pos_tab_length_points, pos_y_side;
		row_range = pos_rows,
	)


	# ---------------------------------------------
	# Build endboxes (regions to be carved)
	# ---------------------------------------------

	neg_endbox = [(Nx*Ny*(i-1)+(neg_rows.start-1)*Nx+1):(Nx*Ny*(i-1)+neg_rows.stop*Nx)
				  for i in 1:Nz]

	pos_endbox = [(Nx*Ny*(i-1)+(pos_rows.start-1)*Nx+1):(Nx*Ny*(i-1)+pos_rows.stop*Nx)
				  for i in 1:Nz]

	# ---------------------------------------------
	# Map tab corridors into each z-layer
	# ---------------------------------------------

	total_segments = length(z_thickness_per_segment)

	neg_cc_segments = [s for s in 1:total_segments if z_thickness_per_segment[s] == neg_cc_thickness]
	pos_cc_segments = [s for s in 1:total_segments if z_thickness_per_segment[s] == pos_cc_thickness]

	cum_points = cumsum(z_points_per_segment)
	seg_lo = vcat(1, cum_points[1:(end-1)] .+ 1)
	seg_hi = cum_points

	neg_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in neg_cc_segments]...)
	pos_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in pos_cc_segments]...)

	neg_tab_cells = Int[]
	pos_tab_cells = Int[]

	for layer in neg_cc_layers
		offset = (layer - 1) * Nx * Ny
		append!(neg_tab_cells, offset .+ neg_tab_local)
	end

	for layer in pos_cc_layers
		offset = (layer - 1) * Nx * Ny
		append!(pos_tab_cells, offset .+ pos_tab_local)
	end

	# ---------------------------------------------
	# Remove endbox cells outside tab corridors
	# ---------------------------------------------

	endbox_all = vcat(vcat(neg_endbox...), vcat(pos_endbox...))
	keep_cells = union(neg_tab_cells, pos_tab_cells)
	cells_to_remove = sort!(setdiff(endbox_all, keep_cells))

	global_grid, = remove_cells(raw_grid, cells_to_remove)
	# --------------------------------------------------------
	# 10) Build sub-grids and couplings
	# --------------------------------------------------------
	grids, couplings = setup_pouch_cell_geometry(global_grid, z_thickness_per_segment, extra_ne, double_coated)
	grids, couplings = convert_geometry(grids, couplings)

	for (component, side_is_high) in [("NegativeCurrentCollector", false), ("PositiveCurrentCollector", true)]
		grid = grids[component]
		neighbors = get_neighborship(grid; internal = false)
		boundary_faces = findBoundary(grid, 2, side_is_high)
		couplings[component]["External"] = Dict("cells"=>neighbors[boundary_faces], "boundaryfaces"=>boundary_faces)
	end

	return grids, couplings
end


"""
	compute_tab_indices_local(segment_points, tab_type, tabs_on_same_side,
							  Nx, Ny, tab_l, y_side; row_range=nothing)

Returns linear x–y indices for a tab footprint.

`row_range` MUST be provided when tabs are on the same side.
Otherwise, traditional bottom/top anchoring is used.

Segment layout:
	1: left active
	2: left tab remainder
	3: middle active
	4: overlap (if any)
	5: right tab remainder
	6: right active
"""
function compute_tab_indices_local(
	segment_points,
	tab_type::String,
	tabs_on_same_side::Bool,
	Nx::Int, Ny::Int,
	tab_l::Int,
	y_side::String;
	row_range::Union{Nothing, UnitRange{Int}} = nothing,
)

	# ----------------------------
	# 1) Pick y-rows
	# ----------------------------
	rows =
		if tabs_on_same_side
			@assert row_range !== nothing "row_range must be provided when tabs_on_same_side == true"
			row_range
		else
			ys = lowercase(y_side)
			@assert 1 <= tab_l <= Ny "tab_l out of range"
			ys == "bottom" ? (1:tab_l) :
			ys == "top" ? ((Ny-tab_l+1):Ny) :
			error("y_side must be 'bottom' or 'top'")
		end

	# ----------------------------
	# 2) Pick x-columns (width)
	# ----------------------------
	@assert sum(segment_points) == Nx
	p = cumsum(vcat(0, segment_points))   # segment boundaries

	# helper: x-fastest indexing
	get_idx_for_run = function (col_start, col_stop)
		col_start = clamp(col_start, 1, Nx)
		col_stop  = clamp(col_stop, 1, Nx)
		col_stop < col_start && return Int[]
		vcat([(r-1)*Nx .+ (col_start:col_stop) for r in rows]...)
	end

	idxs = Int[]

	if segment_points[4] == 0
		# No overlap: NE = seg 2, PE = seg 5
		if tab_type == "NegativeElectrode"
			append!(idxs, get_idx_for_run(p[2] + 1, p[3]))   # segment 2
		else
			append!(idxs, get_idx_for_run(p[5] + 1, p[6]))   # segment 5
		end
	else
		# Overlap: segment 4 always included
		append!(idxs, get_idx_for_run(p[4] + 1, p[5]))       # overlap segment

		if tab_type == "NegativeElectrode"
			append!(idxs, get_idx_for_run(p[2] + 1, p[3]))   # NE remainder
		else
			append!(idxs, get_idx_for_run(p[5] + 1, p[6]))   # PE remainder
		end
	end

	return unique!(sort!(idxs))
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


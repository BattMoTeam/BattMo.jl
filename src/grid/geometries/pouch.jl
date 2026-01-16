export pouch_grid

#################################
# Multi layer pouch cell setup #
#################################


"""
Create a multilayer pouch cell grid with flexible tab placement.

Features:
- Double-coated multilayer stack (no outer collectors):
  Per layer: NE_coating | NE_CC | NE_coating | Separator | PE_coating | PE_CC | PE_coating | (interlayer Separator)
- Tabs can be on the same y-side or opposite sides (configurable).
- Each collector has its own tab position fraction (normalized to active width [0..1]).
- Tab grid points computed dynamically from physical tab dimensions.

Returns:
- `grids`: component grids for NegativeCurrentCollector, NegativeElectrode, Separator, PositiveElectrode, PositiveCurrentCollector, Electrolyte
- `couplings`: coupling information between components
"""
function pouch_grid(input)
	# -----------------------
	# Extract input parameters
	# -----------------------
	cell_params  = input.cell_parameters
	sim_settings = input.simulation_settings

	num_layers = cell_params["Cell"]["NumberOfLayers"]

	# --- Normalize a single fraction robustly to [0, 1] ---
	# Accepts:
	#   - [0, 1]  -> used as-is
	#   - (1, 100] -> treated as percent (e.g., 30 -> 0.30)
	#   - others   -> clamped to [0, 1]
	normalize_fraction = frac -> begin
		if !(isfinite(frac))
			return 0.5
		elseif 0.0 ≤ frac ≤ 1.0
			return frac
		elseif 1.0 < frac ≤ 100.0
			return clamp(frac/100.0, 0.0, 1.0)
		else
			return clamp(frac, 0.0, 1.0)
		end
	end

	# Tab placement settings
	tabs_on_same_side = get(cell_params["Cell"], "TabsOnSameSide", false)
	neg_frac_in       = get(cell_params["Cell"], "NegativeTabPositionFraction", 0.2)  # may be 0.2 or 20
	pos_frac_in       = get(cell_params["Cell"], "PositiveTabPositionFraction", 0.8)  # may be 0.8 or 80
	neg_tab_fraction  = normalize_fraction(neg_frac_in)
	pos_tab_fraction  = normalize_fraction(pos_frac_in)
	same_side_y_side  = Symbol(get(sim_settings, "TabsSameSideY", "high"))  # :high or :low when both on same side

	# Thickness and grid points for each material (z)
	neg_cc_thickness = cell_params["NegativeElectrode"]["CurrentCollector"]["Thickness"]
	neg_cc_points    = sim_settings["NegativeElectrodeCurrentCollectorGridPoints"]

	neg_coating_thickness = cell_params["NegativeElectrode"]["Coating"]["Thickness"]
	neg_coating_points    = sim_settings["NegativeElectrodeCoatingGridPoints"]

	pos_cc_thickness = cell_params["PositiveElectrode"]["CurrentCollector"]["Thickness"]
	pos_cc_points    = sim_settings["PositiveElectrodeCurrentCollectorGridPoints"]

	pos_coating_thickness = cell_params["PositiveElectrode"]["Coating"]["Thickness"]
	pos_coating_points    = sim_settings["PositiveElectrodeCoatingGridPoints"]

	separator_thickness = cell_params["Separator"]["Thickness"]
	separator_points    = sim_settings["SeparatorGridPoints"]

	# Electrode dimensions and grid points (x-y)
	electrode_width  = cell_params["Cell"]["ElectrodeWidth"]
	electrode_length = cell_params["Cell"]["ElectrodeLength"]
	width_points     = sim_settings["ElectrodeWidthGridPoints"]
	length_points    = sim_settings["ElectrodeLengthGridPoints"]

	# Tab physical dimensions
	neg_tab_width_mm  = cell_params["NegativeElectrode"]["CurrentCollector"]["TabWidth"]
	neg_tab_length_mm = cell_params["NegativeElectrode"]["CurrentCollector"]["TabLength"]

	pos_tab_width_mm  = cell_params["PositiveElectrode"]["CurrentCollector"]["TabWidth"]
	pos_tab_length_mm = cell_params["PositiveElectrode"]["CurrentCollector"]["TabLength"]

	# --- Compute tab grid points dynamically from physical dimensions ---
	neg_tab_width_pts  = max(1, round(Int, (neg_tab_width_mm / electrode_width) * width_points))
	neg_tab_length_pts = max(1, round(Int, (neg_tab_length_mm / electrode_length) * length_points))

	pos_tab_width_pts  = max(1, round(Int, (pos_tab_width_mm / electrode_width) * width_points))
	pos_tab_length_pts = max(1, round(Int, (pos_tab_length_mm / electrode_length) * length_points))

	# Split x and y into three regions: [negative tab | active area | positive tab]
	# (Only used for per-cell sizing; actual tab center positions are independent and normalized to active width.)
	width_segments  = [neg_tab_width_pts, width_points - (neg_tab_width_pts + pos_tab_width_pts), pos_tab_width_pts]
	length_segments = [neg_tab_length_pts, length_points - (neg_tab_length_pts + pos_tab_length_pts), pos_tab_length_pts]

	width_sizes_mm  = [neg_tab_width_mm, electrode_width - (neg_tab_width_mm + pos_tab_width_mm), pos_tab_width_mm]
	length_sizes_mm = [neg_tab_length_mm, electrode_length - (neg_tab_length_mm + pos_tab_length_mm), pos_tab_length_mm]

	# Sanity checks
	@assert width_points > 0 && length_points > 0
	@assert all(>=(0), width_segments) "Width segments negative. Adjust tab widths or grid points."
	@assert all(>=(0), length_segments) "Length segments negative. Adjust tab lengths or grid points."
	@assert all(>=(0.0), width_sizes_mm) "Width sizes negative. Adjust tab widths or electrode_width."
	@assert all(>=(0.0), length_sizes_mm) "Length sizes negative. Adjust tab lengths or electrode_length."
	@assert same_side_y_side in (:low, :high)

	# -----------------------------------------
	# Build z-direction segments (double-coated, no outer collectors)
	# Per layer: NE_co | NE_cc | NE_co | SEP | PE_co | PE_cc | PE_co | (interlayer SEP)
	# -----------------------------------------
	z_points_per_segment    = Int[]
	z_thickness_per_segment = Float64[]

	for layer in 1:num_layers
		append!(z_points_per_segment, (neg_coating_points, neg_cc_points, neg_coating_points, separator_points,
			pos_coating_points, pos_cc_points, pos_coating_points))
		append!(z_thickness_per_segment, (neg_coating_thickness, neg_cc_thickness, neg_coating_thickness, separator_thickness,
			pos_coating_thickness, pos_cc_thickness, pos_coating_thickness))
		if layer < num_layers
			append!(z_points_per_segment, separator_points)
			append!(z_thickness_per_segment, separator_thickness)
		end
	end

	z_segment_thicknesses = copy(z_thickness_per_segment)

	# Per-cell sizes
	width_sizes_per_cell  = width_sizes_mm ./ width_segments
	length_sizes_per_cell = length_sizes_mm ./ length_segments
	z_sizes_per_cell      = z_thickness_per_segment ./ z_points_per_segment

	# Expand to full per-cell arrays
	cell_widths  = inverse_rle(width_sizes_per_cell, width_segments)
	cell_lengths = inverse_rle(length_sizes_per_cell, length_segments)
	cell_heights = inverse_rle(z_sizes_per_cell, z_points_per_segment)

	Nx = length(cell_widths)
	Ny = length(cell_lengths)
	Nz = length(cell_heights)

	# Build mesh
	mesh     = CartesianMesh((Nx, Ny, Nz), (cell_widths, cell_lengths, cell_heights))
	raw_grid = convert_to_mrst_grid(UnstructuredMesh(mesh))

	# --------------------------------------------------------
	# Flexible TAB CARVING
	# --------------------------------------------------------
	# Helper: compute a tab corridor (local indices within a single x-y layer, 1..Nx*Ny),
	# with the fraction normalized to the *active width*:
	#   active_width_mm = electrode_width - (neg_tab_width_mm + pos_tab_width_mm)
	#   position_mm = neg_tab_width_mm + frac * active_width_mm   (0→just after neg-tab zone, 1→just before pos-tab zone)
	compute_tab_indices_local = function (Nx::Int, Ny::Int,
		tab_w_pts::Int, tab_l_pts::Int,
		frac::Float64; y_side::Symbol = :low,
		neg_tab_width_mm::Float64,
		pos_tab_width_mm::Float64,
		electrode_width_mm::Float64)
		# Normalize horizontal position across active width (mm)
		active_width_mm = electrode_width_mm - (neg_tab_width_mm + pos_tab_width_mm)
		@assert active_width_mm ≥ 0 "Active width is negative; tab widths exceed electrode width."

		position_mm = neg_tab_width_mm + frac * active_width_mm
		# Convert to grid column index
		col_center = clamp(round(Int, position_mm / electrode_width_mm * Nx), 1, Nx)
		col_start  = clamp(col_center - div(tab_w_pts, 2), 1, max(1, Nx - tab_w_pts + 1))
		col_stop   = min(col_start + tab_w_pts - 1, Nx)

		# Rows at chosen y-side
		rows = (y_side == :low) ? (1:tab_l_pts) : ((Ny-tab_l_pts+1):Ny)

		# Local linear indices in a single x-y layer
		vcat([(Nx * (r - 1) .+ (col_start:col_stop)) for r in rows]...)
	end

	# Endbox absolute indices for each z-layer (y-edge rows)
	pos_endbox_per_layer = [(Nx*(i*Ny-pos_tab_length_pts)+1):(Nx*Ny*i) for i in 1:Nz]  # y-high rows
	neg_endbox_per_layer = [(Nx*Ny*(i-1)+1):(Nx*(Ny*(i-1)+neg_tab_length_pts)) for i in 1:Nz]  # y-low rows

	# Segment indices for NE/PE current collectors
	total_segments = length(z_thickness_per_segment)
	@assert (total_segments + 1) % 8 == 0 "Expected double-coated pattern without outer collectors (S = 8n - 1)"
	@assert Int((total_segments + 1) ÷ 8) == num_layers

	neg_cc_segments = [(1 + 8*k) + 1 for k in 0:(num_layers-1)]  # base = 1 + 8k; NE_cc at base+1
	pos_cc_segments = [(1 + 8*k) + 5 for k in 0:(num_layers-1)]  # base = 1 + 8k; PE_cc at base+5

	# Map segment -> z-layer indices
	cum_points = cumsum(z_points_per_segment)
	seg_lo = vcat(1, cum_points[1:(end-1)] .+ 1)
	seg_hi = cum_points

	neg_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in neg_cc_segments]...)
	pos_cc_layers = vcat([seg_lo[s]:seg_hi[s] for s in pos_cc_segments]...)

	# Y-side selection
	neg_y_side = tabs_on_same_side ? same_side_y_side : :low
	pos_y_side = tabs_on_same_side ? same_side_y_side : :high

	# Precompute local tab corridors (layer-local indices) using *active-width normalized* fractions
	neg_tab_corridor_local = compute_tab_indices_local(
		Nx, Ny, neg_tab_width_pts, neg_tab_length_pts, neg_tab_fraction;
		y_side = neg_y_side, neg_tab_width_mm = neg_tab_width_mm, pos_tab_width_mm = pos_tab_width_mm, electrode_width_mm = electrode_width,
	)

	pos_tab_corridor_local = compute_tab_indices_local(
		Nx, Ny, pos_tab_width_pts, pos_tab_length_pts, pos_tab_fraction;
		y_side = pos_y_side, neg_tab_width_mm = neg_tab_width_mm, pos_tab_width_mm = pos_tab_width_mm, electrode_width_mm = electrode_width,
	)

	# Build absolute tab cells by adding z-layer offset, then intersect with the endbox rows
	neg_tab_cells = Int[]
	pos_tab_cells = Int[]

	for layer in neg_cc_layers
		layer_offset = (layer - 1) * Nx * Ny
		corridor_abs = layer_offset .+ neg_tab_corridor_local
		keep_cells   = intersect(neg_endbox_per_layer[layer], corridor_abs)
		append!(neg_tab_cells, keep_cells)
	end

	for layer in pos_cc_layers
		layer_offset = (layer - 1) * Nx * Ny
		corridor_abs = layer_offset .+ pos_tab_corridor_local
		keep_cells   = intersect(pos_endbox_per_layer[layer], corridor_abs)
		append!(pos_tab_cells, keep_cells)
	end

	# Remove endbox cells but keep the tab corridors
	pos_endbox_all = vcat(pos_endbox_per_layer...)
	neg_endbox_all = vcat(neg_endbox_per_layer...)

	pos_cells_to_remove = setdiff(pos_endbox_all, pos_tab_cells)
	neg_cells_to_remove = setdiff(neg_endbox_all, neg_tab_cells)

	global_grid, = remove_cells(raw_grid, vcat(pos_cells_to_remove, neg_cells_to_remove))

	# --------------------------------------------------------
	# Build component grids and couplings
	# --------------------------------------------------------
	grids, couplings = setup_pouch_cell_geometry(global_grid, z_segment_thicknesses)
	grids, couplings = convert_geometry(grids, couplings)

	# External couplings for outer faces
	for (component, side) in [("NegativeCurrentCollector", false), ("PositiveCurrentCollector", true)]
		grid = grids[component]
		neighbors = get_neighborship(grid; internal = false)
		boundary_faces = findBoundary(grid, 2, side)
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


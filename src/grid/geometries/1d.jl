export one_dimensional_grid

##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(input)

	grids       = Dict()
	global_maps = Dict()

	cell_parameters = input.cell_parameters
	grid_settings = input.simulation_settings["GridResolution"]

	include_current_collectors = haskey(input.model_settings, "CurrentCollectors")

	faceArea = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

	function get_cell_parameter_vals(var)
		neval = cell_parameters["NegativeElectrode"]["ElectrodeCoating"][var]
		sepval = cell_parameters["Separator"][var]
		peval = cell_parameters["PositiveElectrode"]["ElectrodeCoating"][var]
		if include_current_collectors
			ne_ccval = cell_parameters["NegativeElectrode"]["CurrentCollector"][var]
			pe_ccval = cell_parameters["PositiveElectrode"]["CurrentCollector"][var]
			out = [ne_ccval, neval, sepval, peval, pe_ccval]
		else
			out = [neval, sepval, peval]
		end
		return out
	end

	function get_grid_settings_vals()
		neval = grid_settings["NegativeElectrodeCoating"]
		sepval = grid_settings["Separator"]
		peval = grid_settings["PositiveElectrodeCoating"]
		if include_current_collectors
			ne_ccval = grid_settings["NegativeElectrodeCurrentCollector"]
			pe_ccval = grid_settings["PositiveElectrodeCurrentCollector"]
			out = [ne_ccval, neval, sepval, peval, pe_ccval]
		else
			out = [neval, sepval, peval]
		end
		return out
	end

	vals = Dict(
		"thickness" => get_cell_parameter_vals("Thickness"),
		"N" => Int.(get_grid_settings_vals()),
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
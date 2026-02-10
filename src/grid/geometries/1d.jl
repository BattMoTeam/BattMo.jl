export one_dimensional_grid

##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(model, input)

	grids       = Dict()
	global_maps = Dict()

	cell_parameters = input.cell_parameters
	simulation_settings = input.simulation_settings

	include_current_collectors = haskey(input.model_settings, "CurrentCollectors")

	faceArea = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

	function get_cell_parameter_vals(var)
		neval = cell_parameters["NegativeElectrode"]["Coating"][var]
		sepval = cell_parameters["Separator"][var]
		peval = cell_parameters["PositiveElectrode"]["Coating"][var]
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
		neval = simulation_settings["NegativeElectrodeCoatingGridPoints"]
		sepval = simulation_settings["SeparatorGridPoints"]
		peval = simulation_settings["PositiveElectrodeCoatingGridPoints"]
		if include_current_collectors
			ne_ccval = simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"]
			pe_ccval = simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"]
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

		elyte_comp_start = 2

	else

		elyte_comp_start = 1

	end

	components = get_component_list(model;
		include_current_collectors,
		include_electrolyte = false,
		include_separator = true)

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
		inds = cinds[icomponent]:(cinds[icomponent+1]-1)
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

	grids, couplings = convert_geometry(model, grids, couplings; include_current_collectors = include_current_collectors)

	"""Add  external coupling to the coupling structure.
	   Function can be used both with and without current collector."""
	if include_current_collectors
		boundaryComponents = Dict("left" => "NegativeElectrodeCurrentCollector",
			"right" => "PositiveElectrodeCurrentCollector")
	else
		boundaryComponents = Dict("left" => "NegativeElectrodeActiveMaterial",
			"right" => "PositiveElectrodeActiveMaterial")
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

	return grids, couplings, global_maps

end

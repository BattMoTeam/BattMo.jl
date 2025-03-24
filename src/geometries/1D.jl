
export one_dimensional_grid
##############################
# one dimensional grid setup #
##############################

function one_dimensional_grid(geomparams::ParameterSet)

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

	L = StatsBase.inverse_rle(xs ./ ns, ns)

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
		boundaryComponents = Dict("left"  => "NegativeCurrentCollector",
			"right" => "PositiveCurrentCollector")
	else
		boundaryComponents = Dict("left"  => "NegativeElectrode",
			"right" => "PositiveElectrode")
	end

	"""get x-coordinate of the boundary faces"""
	function getcoord(grid, i)
		centroid, = Jutul.compute_centroid_and_measure(grid, BoundaryFaces(), i)
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

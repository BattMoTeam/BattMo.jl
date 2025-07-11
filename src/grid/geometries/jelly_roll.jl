export jelly_roll_grid

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

	dx = mapreduce((dx, N) -> repeat([dx], N), vcat, dxs ./ Ns, Ns)

	spacing = [0; cumsum(dx)]
	spacing = spacing / spacing[end]

	thickness = sum(dxs)

	depths = [0; cumsum(repeat([height / nz], nz))]

	components = ["PositiveCurrentCollector",
		"PositiveElectrode",
		"Separator",
		"Electrolyte",
		"NegativeElectrode",
		"NegativeCurrentCollector"]

	component_indices                             = Dict()
	component_indices["PositiveElectrode"]        = [1, 3]
	component_indices["PositiveCurrentCollector"] = [2]
	component_indices["Separator"]                = [4, 8]
	component_indices["NegativeElectrode"]        = [5, 7]
	component_indices["NegativeCurrentCollector"] = [6]
	component_indices["Electrolyte"]              = reduce(vcat, [component_indices["PositiveElectrode"],
	component_indices["Separator"],
	component_indices["NegativeElectrode"]])
	spacingtags                                   = Dict()
	for component in components
		inds = Bool[]
		for i in eachindex(Ns)
			append!(inds, fill(i in component_indices[component], Ns[i]))
		end
		spacingtags[component] = findall(inds)
	end

	C = rinner
	A = thickness / (2 * pi)

	nrot = Int(round((router - rinner) / (2 * pi * A)))

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
		allinds = collect(1:parentGrid["cells"]["num"])
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

		c  = geo.boundary_centroids[1:2, :]
		n  = geo.boundary_normals[1:2, :]
		nc = [norm(col) for col in eachslice(c, dims = 2)]

		vectbcface = findall(((1.0 ./ nc) .* vec(sum(c .* n, dims = 1))) .< -(1 - 0.01))

		zc = geo.boundary_centroids[3, vectbcface]

		nz = inputparams["Geometry"]["numberOfDiscretizationCellsVertical"]

		if component == "NegativeCurrentCollector"
			vectbcface = vectbcface[abs.(zc .- maximum(zc)).<=0.01/nz*(maximum(zc)-minimum(zc))]
		else
			vectbcface = vectbcface[abs.(zc .- minimum(zc)).<=0.01/nz*(maximum(zc)-minimum(zc))]
		end

		# we sort by radius, so that the cells are ordered along the spiral in increasing order of radius

		vectbcface = sort(vectbcface, by = x -> norm(geo.boundary_centroids[1:2, x]))

		# We use the horizontal face centroids to compute the spiral length which we store in the structure spiral_lengths

		c = geo.boundary_centroids[1:2, vectbcface]
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
		tab_intervals = [spiral_length * fraction .+ [-tab_width / 2, tab_width / 2] for fraction in tab_fractions]

		# We collect the faces (still vertical faces at top of current collector) in the tab_vert_faces structure.
		tab_vert_faces = []

		for interval in tab_intervals
			inds = findall(l -> ((l > interval[1]) && (l < interval[2])), spiral_lengths)
			if isempty(inds)
				inds = findfirst(l -> (l > interval[1]), spiral_lengths)
			end
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
				for iface in im.pos[cell]:im.pos[cell+1]-1
					f = im.vals[iface]
					n = geo.boundary_normals[:, f]
					if abs(n[1]) + abs(n[2]) < 1e-3 * abs(n[3])
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
			horzfaces = findall(n -> abs(n[1]) + abs(n[2]) < 0.01 * n[3], eachslice(ns, dims = 2))
		elseif component == "PositiveCurrentCollector"
			horzfaces = findall(n -> abs(n[1]) + abs(n[2]) < -0.01 * n[3], eachslice(ns, dims = 2))
		end

		# We setup angle and radius of the top (bottom) faces.
		angle_horzfaces  = [atan(c[2], c[1]) for c in eachslice(geo.boundary_centroids[1:2, horzfaces], dims = 2)]
		radius_horzfaces = [norm(c) for c in eachslice(geo.boundary_centroids[1:2, horzfaces], dims = 2)]

		""" Given a face in the first row of current collector, we collect the other cells in the radial direction. The
		centroids of those cells should have the same angle and a radius higher as the first row face and within the
		thickness of the current collector """
		function get_tab_radial_faces(first_tab_face)
			c = geo.boundary_centroids[1:2, first_tab_face]
			angle = atan(c[2], c[1])
			radius = norm(c)
			tabhorzfaces = []
			for (i, (angle_topface, radius_topface)) in enumerate(zip(angle_horzfaces, radius_horzfaces))
				if (abs(angle_topface - angle) < (0.1 * 2 * pi / inputparams["Geometry"]["numberOfDiscretizationCellsAngular"])) && (radius_topface >= radius) &&
				   (radius_topface <= (radius + inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"]))
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
		for bf in 1:number_of_boundary_faces(g)
			N = geo.boundary_normals[:, bf]
			Nz = N[3]
			if ((abs(N[1]) + abs(N[2]) < 0.01 * abs(Nz))
				&&
				(((Nz > 0) && (component == "NegativeCurrentCollector"))) || ((Nz < 0) && (component == "PositiveCurrentCollector")))
				push!(bc_faces, bf)
				push!(bc_cells, g.boundary_faces.neighbors[bf])
			end
		end

		coupling = Dict("cells" => bc_cells, "boundaryfaces" => bc_faces)

	end

	return coupling

end


function spiral_grid(geomparams::InputGeometryParams)

	Ns = [3, 4, 2, 6, 1]
	ls = [1.0, 2.0, 2.1, 3.2, 1.1]
	dxs = ls ./ Ns

	dx = mapreduce((dx, N) -> repeat([dx], N), vcat, dxs, Ns)

	spacing = [0; cumsum(dx)]
	spacing = spacing / spacing[end]

end
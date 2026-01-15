export
	find_coupling,
	find_common,
	findBoundary,
	convert_geometry,
	get_grids





#####################
# utility functions #
#####################

"""
   find coupling cells and faces between two grid maps
"""
function find_coupling(maps1, maps2, modelname = "placeholder")
	Coupling = Dict()
	Coupling["model"] = modelname
	Coupling["cells"] = find_common(maps1[1][:cellmap], maps2[1][:cellmap])
	Coupling["faces"] = find_common(maps1[1][:facemap], maps2[1][:facemap])
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
	Arguments:
	- components  : vector of strings that gives the name of the component to be coupled
	- grids       : dictionnay of grids
	- global_maps : maps from the subgrid to the global grid
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
						lnodes = Set(rawfaces["nodes"][lnodePos[1]:(lnodePos[2]-1)])
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

""" retrieve the grids from a model"""
function get_grids(model::MultiModel{:IntercalationBattery})

	has_cc = include_current_collectors(model)

	components = [:NegativeElectrodeCurrentCollector, :NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial, :PositiveElectrodeCurrentCollector]
	names = ["NegativeCurrentCollector",
		"NegativeElectrode",
		"Electrolyte",
		"PositiveElectrode",
		"PositiveCurrentCollector"]

	if !has_cc
		components = components[2:4]
		names = names[2:4]
	end

	grids = Dict()

	for (name, component) in zip(names, components)

		grids[name] = physical_representation(model[component]).representation

	end

	return grids
end







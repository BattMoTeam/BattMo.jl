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
	Coupling["cells"] = find_common(maps1[1], maps2[1])
	Coupling["faces"] = find_common(maps1[2], maps2[2])
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
Convert MRST-format grids (raw dictionaries) to Jutul UnstructuredMesh format.
Handles external face couplings by mapping MRST face indices to Jutul boundary face indices.
Works for single-layer and multilayer pouch cells because grids are already aggregated by component.
"""
function convert_geometry(grids, couplings; include_current_collectors = true)

	# Component list matches setup_pouch_cell_geometry
	if include_current_collectors
		components = [
			"NegativeCurrentCollector",
			"NegativeElectrode",
			"Separator",
			"PositiveElectrode",
			"PositiveCurrentCollector",
			"Electrolyte",
		]
	else
		components = [
			"NegativeElectrode",
			"Separator",
			"PositiveElectrode",
			"Electrolyte",
		]
	end

	# Convert each MRST grid to Jutul UnstructuredMesh
	ugrids = Dict{String, Any}()
	for component in components
		ugrids[component] = UnstructuredMesh(grids[component])
	end

	# Deep copy couplings for modification
	ucouplings = deepcopy(couplings)

	# Map MRST face indices to Jutul boundary face indices
	for component in components
		component_couplings = ucouplings[component]
		grid = grids[component]
		ugrid = ugrids[component]

		for (other_component, coupling) in component_couplings
			if isempty(coupling)
				continue
			end

			# Only process if coupling has faces
			if get(coupling, "face_type", false)
				faces = coupling["faces"]
				cells = coupling["cells"]

				for fi in eachindex(faces)
					face = faces[fi]
					cell = cells[fi]

					# Candidate boundary faces for this cell
					candidates = ugrid.boundary_faces.cells_to_faces[cell]

					# MRST raw face nodes
					rawfaces = grid["faces"]
					lnodePos = rawfaces["nodePos"][face:(face+1)]
					lnodes = Set(rawfaces["nodes"][lnodePos[1]:(lnodePos[2]-1)])

					# Find matching boundary face in Jutul mesh
					count = 0
					for lfi in candidates
						fnodes = Set(ugrid.boundary_faces.faces_to_nodes[lfi])
						if fnodes == lnodes
							faces[fi] = lfi
							count += 1
						end
					end
					@assert count == 1 "Boundary face mapping failed for component $component"
				end
			else
				@assert isempty(coupling["faces"]) "Coupling without face_type should have no faces"
			end
		end
	end

	# Convert global grid if present
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







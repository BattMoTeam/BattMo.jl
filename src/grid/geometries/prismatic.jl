export prismatic_grid

"""
Create a wound 3D prismatic-cell grid.

The prismatic implementation reuses the jelly-roll internal geometry used for
cylindrical cells and then deforms the x-y coordinates into a rounded
rectangular cross-section. This represents a wound electrode stack packaged in a
prismatic form factor.
"""
function prismatic_grid(input)
	grids, couplings = jelly_roll_grid(input)

	cell = input.cell_parameters["Cell"]
	dims = get_jelly_roll_dimensions(input.cell_parameters)
	outer_radius = dims.outer_radius
	case_width = cell["CaseWidth"]
	case_thickness = cell["CaseThickness"]

	deformed_grids = Dict{String, Any}()
	for (name, grid) in grids
		if grid isa UnstructuredMesh
			deformed_grids[name] = deform_wound_grid_to_prismatic(
				grid,
				outer_radius,
				case_width,
				case_thickness,
			)
		else
			deformed_grids[name] = grid
		end
	end

	return deformed_grids, couplings
end

function deform_wound_grid_to_prismatic(
	grid::UnstructuredMesh,
	outer_radius::Real,
	case_width::Real,
	case_thickness::Real;
	exponent::Real = 6.0,
)
	a = 0.5 * case_width
	b = 0.5 * case_thickness

	@assert a > 0.0 "CaseWidth must be positive."
	@assert b > 0.0 "CaseThickness must be positive."
	@assert outer_radius > 0.0 "OuterRadius must be positive."

	function superellipse_radius(theta)
		ct = abs(cos(theta))
		st = abs(sin(theta))
		return ((ct / a)^exponent + (st / b)^exponent)^(-1 / exponent)
	end

	new_node_points = map(grid.node_points) do pt
		x = pt[1]
		y = pt[2]
		r = hypot(x, y)
		if iszero(r)
			return pt
		end
		theta = atan(y, x)
		target_radius = superellipse_radius(theta)
		scale = target_radius / outer_radius
		return SVector(x * scale, y * scale, pt[3])
	end

	return UnstructuredMesh(
		grid.faces.cells_to_faces,
		grid.boundary_faces.cells_to_faces,
		grid.faces.faces_to_nodes,
		grid.boundary_faces.faces_to_nodes,
		new_node_points,
		grid.faces.neighbors,
		grid.boundary_faces.neighbors;
		cell_map = grid.cell_map,
		face_map = grid.face_map,
		boundary_map = grid.boundary_map,
		node_map = grid.node_map,
		structure = grid.structure,
		z_is_depth = grid.z_is_depth,
	)
end

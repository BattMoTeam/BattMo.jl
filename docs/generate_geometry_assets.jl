using BattMo
using GLMakie
using Jutul

const ASSET_DIR = joinpath(@__DIR__, "src", "assets")
mkpath(ASSET_DIR)

"""
Generate geometry figures for the documentation using the same plotting helpers
that users see in the examples: `plot_mesh` and `plot_mesh_edges`.

This script requires a GLMakie-capable environment. In a headless Linux setup,
run it under a virtual display such as Xvfb.
"""

function prepare_hidden_screen(fig; resolution = (1200, 800))
	screen = display(GLMakie.Screen(
			visible = false,
			renderloop = _ -> nothing,
			start_renderloop = false,
			resolution = resolution,
		), fig)
	return screen
end

function save_and_close(path, fig; resolution = (1200, 800))
	screen = prepare_hidden_screen(fig; resolution)
	try
		save(path, fig)
	finally
		GLMakie.destroy!(screen)
		GLMakie.closeall()
	end
end

function mesh_legend(fig, labels, colors)
	Legend(fig[1, 2], [PolyElement(color = c) for c in colors], labels)
end

function save_p2d_geometry()
	# Keep the lightweight static 1D schematic asset generation outside this script.
	# The GLMakie/Jutul mesh plots are mainly useful for the 3D geometries.
	return nothing
end

function save_p4d_pouch_geometry()
	println("Generating geometry_p4d_pouch.png")
	cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
	cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
	model_settings = load_model_settings(; from_default_set = "p4d_pouch")
	simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

	cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.20
	cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.80
	cell_parameters["Cell"]["TabsOnSameSide"] = false
	cell_parameters["Cell"]["TabWidth"] = 20e-3
	cell_parameters["Cell"]["TabLength"] = 12e-3
	cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 18e-6
	cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 20e-6

	simulation_settings["ElectrodeWidthGridPoints"] = 8
	simulation_settings["ElectrodeLengthGridPoints"] = 8

	sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)

	components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
	colors = [:gray, :green, :dodgerblue, :black]

	for (i, component) in enumerate(components)
		if i == 1
			global fig_mesh, ax_mesh = plot_mesh(sim.grids[component];
				color = colors[i],
				label = component)
		else
			plot_mesh!(ax_mesh, sim.grids[component];
				color = colors[i],
				label = component)
		end
	end

	for (i, component) in enumerate(components)
		plot_mesh_edges!(ax_mesh, sim.grids[component];
			color = (:white, 0.6),
			linewidth = 0.75)
	end

	# ax_mesh.aspect = :data
	ax_mesh.azimuth[] = 5.2
	ax_mesh.elevation[] = 0.45
	ax_mesh.title = "P4D Pouch Geometry"
	mesh_legend(fig_mesh, components, colors)

	save_and_close(joinpath(ASSET_DIR, "geometry_p4d_pouch.png"), fig_mesh)
end

function save_p4d_cylindrical_geometry()
	println("Generating geometry_p4d_cylindrical.png")
	cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
	cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
	model_settings = load_model_settings(; from_default_set = "p4d_cylindrical")
	simulation_settings = load_simulation_settings(; from_default_set = "p4d_cylindrical")

	cell_parameters["Cell"]["OuterRadius"] = 0.010
	cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 50e-6
	cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 50e-6
	cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.5 / 3, 0.5, 0.5 + 0.5 / 3]
	cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabFractions"] = [0.5 / 3, 0.5, 0.5 + 0.5 / 3]
	cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"] = 0.002
	cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"] = 0.002

	simulation_settings["AngularGridPoints"] = 20
	simulation_settings["HeightGridPoints"] = 2

	sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)

	components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
	colors = [:gray, :green, :dodgerblue, :black]

	for (i, component) in enumerate(components)
		if i == 1
			global fig_edges, ax_edges = plot_mesh_edges(sim.grids[component];
				color = colors[i],
				label = component)
		else
			plot_mesh_edges!(ax_edges, sim.grids[component];
				color = colors[i],
				label = component)
		end
	end

	for component in ["NegativeCurrentCollector", "PositiveCurrentCollector"]
		plot_mesh!(ax_edges, sim.grids[component];
			boundaryfaces = sim.couplings[component]["External"]["boundaryfaces"],
			color = :red)
	end

	ax_edges.aspect = :data
	ax_edges.azimuth[] = 4.0
	ax_edges.elevation[] = 1.56
	ax_edges.title = "P4D Cylindrical Geometry"
	mesh_legend(fig_edges, components, colors)

	save_and_close(joinpath(ASSET_DIR, "geometry_p4d_cylindrical.png"), fig_edges)
end

function main()
	save_p2d_geometry()
	save_p4d_pouch_geometry()
	save_p4d_cylindrical_geometry()
end

main()

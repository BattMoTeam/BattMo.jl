# # 3D pouch cell geometry and plotting
#
# This example shows how to:
# - modify the pouch-cell geometry before running a simulation
# - inspect the generated 3D grids and tab locations
# - plot different output fields on the component meshes
# - launch the interactive 3D output viewer

using BattMo, GLMakie, Jutul

# ## Load default parameter sets

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")
nothing #hide

# ## Modify the pouch geometry
#
# The pouch geometry is controlled by a combination of cell parameters and
# simulation settings. Some useful quantities to experiment with are:
# - `TabsOnSameSide`
# - `TabPositionFraction`
# - `TabWidth` and `TabLength`
# - current collector thickness
# - in-plane grid resolution

cycling_protocol["DRate"] = 1

# Move the tabs so that the current collectors connect at different x-positions.
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.20
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.80

# Toggle whether the tabs are on the same side of the pouch or opposite sides.
cell_parameters["Cell"]["TabsOnSameSide"] = true

# Increase the tab dimensions to make them easier to see in the geometry plots.
cell_parameters["Cell"]["TabWidth"] = 20e-3
cell_parameters["Cell"]["TabLength"] = 12e-3

# Thicker current collectors are also easier to visualize.
cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 18e-6
cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 20e-6

# A slightly coarser in-plane grid keeps the example fairly quick to set up.
simulation_settings["ElectrodeWidthGridPoints"] = 8
simulation_settings["ElectrodeLengthGridPoints"] = 8
nothing #hide

# ## Create the simulation object

model = LithiumIonBattery(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

grids = sim.grids
couplings = sim.couplings
nothing #hide

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :dodgerblue, :black]
nothing #hide

# ## Plot the component meshes

for (i, component) in enumerate(components)
	if i == 1
		global fig_mesh, ax_mesh = plot_mesh(grids[component];
			color = colors[i],
			label = component)
	else
		plot_mesh!(ax_mesh, grids[component];
			color = colors[i],
			label = component)
	end
end

Legend(fig_mesh[1, 2], [PolyElement(color = c) for c in colors], components)
ax_mesh.aspect = :data
ax_mesh.azimuth[] = 5.2
ax_mesh.elevation[] = 0.45
display(GLMakie.Screen(), fig_mesh)

# ## Plot mesh edges and highlight the tabs
#
# The external couplings on the current collectors correspond to the tab faces.
# We plot those in red on top of the mesh edges.

for (i, component) in enumerate(components)
	if i == 1
		global fig_edges, ax_edges = plot_mesh_edges(grids[component];
			color = colors[i],
			label = component)
	else
		plot_mesh_edges!(ax_edges, grids[component];
			color = colors[i],
			label = component)
	end
end

for component in ["NegativeCurrentCollector", "PositiveCurrentCollector"]
	plot_mesh!(ax_edges, grids[component];
		boundaryfaces = couplings[component]["External"]["boundaryfaces"],
		color = :red)
end

Legend(fig_edges[1, 2], [PolyElement(color = c) for c in colors], components)
ax_edges.aspect = :data
ax_edges.azimuth[] = 5.2
ax_edges.elevation[] = 0.45
display(GLMakie.Screen(), fig_edges)

# ## Run the simulation

output = solve(sim)
nothing #hide

# ## Plot different fields on the 3D meshes
#
# The BattMo output now stores component-wise positions, so the state fields can
# be plotted directly against the corresponding component geometry.

# Potential in the negative current collector
fig_phi, ax_phi = plot_cell_data(
	output.states["NegativeElectrode"]["CurrentCollector"]["Position"],
	output.states["NegativeElectrode"]["CurrentCollector"]["Potential"][end, :];
	colormap = :viridis,
)
ax_phi.aspect = :data
ax_phi.title = "Negative current collector potential"
display(GLMakie.Screen(), fig_phi)

# Surface concentration in the positive electrode active material
fig_cs, ax_cs = plot_cell_data(
	output.states["PositiveElectrode"]["ActiveMaterial"]["Position"],
	output.states["PositiveElectrode"]["ActiveMaterial"]["SurfaceConcentration"][end, :];
	colormap = :plasma,
)
ax_cs.aspect = :data
ax_cs.title = "Positive electrode surface concentration"
display(GLMakie.Screen(), fig_cs)

# Mesh edges can be overlaid on top of a cell-data plot.
plot_mesh_edges!(ax_cs, output.states["PositiveElectrode"]["ActiveMaterial"]["Position"];
	color = :black,
	linewidth = 0.5)
fig_cs

# ## Interactive 3D viewer
#
# Finally, we open the interactive multi-component viewer.

plot_interactive_3d(output; colormap = :curl)

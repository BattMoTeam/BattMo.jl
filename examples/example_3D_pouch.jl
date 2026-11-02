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
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.2
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.8

# Toggle whether the tabs are on the same side of the pouch or opposite sides.
cell_parameters["Cell"]["TabsOnSameSide"] = true

# Increase the tab dimensions to make them easier to see in the geometry plots.
cell_parameters["Cell"]["TabWidth"] = 20.0e-3
cell_parameters["Cell"]["TabLength"] = 12.0e-3

# Thicker current collectors are also easier to visualize.
cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 18.0e-6
cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 20.0e-6

# A slightly coarser in-plane grid keeps the example fairly quick to set up.
simulation_settings["ElectrodeWidthGridPoints"] = 12
simulation_settings["ElectrodeLengthGridPoints"] = 8
nothing #hide

# ## Create the simulation object

model = LithiumIonBattery(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

grids = sim.grids
couplings = sim.couplings
nothing #hide

components = ["NegativeElectrodeCurrentCollector", "NegativeElectrodeActiveMaterial", "Separator", "PositiveElectrodeActiveMaterial", "PositiveElectrodeCurrentCollector"]
colors = component_color.(components)
nothing #hide

# ## Plot the component meshes

# Create figures explicitly because Jutul's non-mutating plot helpers display them immediately.
fig_mesh = Figure(size = (1600, 900))
ax_mesh = Axis3(fig_mesh[1, 1])
for (i, component) in enumerate(components)
    plot_mesh!(
        ax_mesh, grids[component];
        color = colors[i],
        label = component,
    )
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

fig_edges = Figure(size = (1600, 900))
ax_edges = Axis3(fig_edges[1, 1])
for (i, component) in enumerate(components)
    plot_mesh_edges!(
        ax_edges, grids[component];
        color = colors[i],
        label = component,
    )
end

for component in ["NegativeElectrodeCurrentCollector", "PositiveElectrodeCurrentCollector"]
    plot_mesh!(
        ax_edges, grids[component];
        boundaryfaces = couplings[component]["External"]["boundaryfaces"],
        color = :red,
    )
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
fig_phi = Figure(size = (1600, 900))
ax_phi = Axis3(fig_phi[1, 1])
plot_phi = plot_cell_data!(
    ax_phi,
    output.states["NegativeElectrode"]["CurrentCollector"]["Position"],
    output.states["NegativeElectrode"]["CurrentCollector"]["Potential"][end, :];
    colormap = :viridis,
)
Colorbar(fig_phi[2, 1], plot_phi; vertical = false)
ax_phi.aspect = :data
ax_phi.title = "Negative current collector potential"

display(GLMakie.Screen(), fig_phi)

# Surface concentration in the positive electrode active material
fig_cs = Figure(size = (1600, 900))
ax_cs = Axis3(fig_cs[1, 1])
plot_cs = plot_cell_data!(
    ax_cs,
    output.states["PositiveElectrode"]["ActiveMaterial"]["Position"],
    output.states["PositiveElectrode"]["ActiveMaterial"]["SurfaceConcentration"][end, :];
    colormap = :plasma,
)
Colorbar(fig_cs[2, 1], plot_cs; vertical = false)
ax_cs.aspect = :data
ax_cs.title = "Positive electrode surface concentration"

# Mesh edges can be overlaid on top of a cell-data plot.
plot_mesh_edges!(
    ax_cs, output.states["PositiveElectrode"]["ActiveMaterial"]["Position"];
    color = :black,
    linewidth = 0.5,
)

display(GLMakie.Screen(), fig_cs)

# ## Double coated electrodes and Multi-layer pouch geometry
# We can also create a multi-layer pouch geometry by modifying the `Cell` parameters. The number of layers is controlled by `NumberOfLayersInParallel`, and for a single layer simulation we can also choose to have double coated electrodes by setting `DoubleCoatedElectrodes` to `true`.

# Let's plot the mesh for a double-coated single-layer pouch cell.
cell_parameters["Cell"]["DoubleCoatedElectrodes"] = true

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
grids = sim.grids
couplings = sim.couplings
nothing #hide

fig_edges_d = Figure(size = (1600, 900))
ax_edges_d = Axis3(fig_edges_d[1, 1])
for (i, component) in enumerate(components)
    plot_mesh!(
        ax_edges_d, grids[component];
        color = colors[i],
        label = component,
    )
end

for component in ["NegativeElectrodeCurrentCollector", "PositiveElectrodeCurrentCollector"]
    plot_mesh!(
        ax_edges_d, grids[component];
        boundaryfaces = couplings[component]["External"]["boundaryfaces"],
        color = :red,
    )
end

Legend(fig_edges_d[1, 2], [PolyElement(color = c) for c in colors], components)
ax_edges_d.azimuth[] = 5.2
ax_edges_d.elevation[] = 0.45

display(GLMakie.Screen(), fig_edges_d)

# Let's plot the mesh for a multi-layer pouch cell.
cell_parameters["Cell"]["NumberOfLayersInParallel"] = 2

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
grids = sim.grids
couplings = sim.couplings
nothing #hide

fig_edges_m = Figure(size = (1600, 900))
ax_edges_m = Axis3(fig_edges_m[1, 1])
for (i, component) in enumerate(components)
    plot_mesh!(
        ax_edges_m, grids[component];
        color = colors[i],
        label = component,
    )
end

for component in ["NegativeElectrodeCurrentCollector", "PositiveElectrodeCurrentCollector"]
    plot_mesh!(
        ax_edges_m, grids[component];
        boundaryfaces = couplings[component]["External"]["boundaryfaces"],
        color = :red,
    )
end

Legend(fig_edges_m[1, 2], [PolyElement(color = c) for c in colors], components)
ax_edges_m.azimuth[] = 5.2
ax_edges_m.elevation[] = 0.45

display(GLMakie.Screen(), fig_edges_m)


# ## Interactive 3D viewer
#
# We can view the output in an interactive 3D viewer, which allows us to explore the different fields and components in more detail. The viewer can be launched with the `plot_interactive_3d` function, which takes the simulation output as input.
output = solve(sim)
plot_interactive_3d(output; colormap = :curl)

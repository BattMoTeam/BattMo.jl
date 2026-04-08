# # 3D wound prismatic cell geometry and plotting
#
# This example demonstrates how to set up, run and visualize a wound prismatic
# battery model. The internal geometry is a jelly roll, like the cylindrical
# model, but it is exposed through the `P4D Prismatic` framework so the setup
# can represent a wound cell packaged in a prismatic form factor.

using BattMo, Jutul, GLMakie

# ## Load parameter sets

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_prismatic")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_prismatic")
nothing #hide

# ## Adjust the geometry

# A more compact winding length and thicker current collectors make the wound
# structure easier to inspect visually.
cell_parameters["Cell"]["Case"] = "Prismatic"
cell_parameters["Cell"]["ElectrodeWidth"] = 0.065
cell_parameters["Cell"]["ElectrodeLength"] = 0.5
cell_parameters["Cell"]["InnerRadius"] = 2e-3
cell_parameters["Cell"]["CaseWidth"] = 0.03
cell_parameters["Cell"]["CaseThickness"] = 0.010
cell_parameters["NegativeElectrode"]["CurrentCollector"]["Thickness"] = 50.0e-6
cell_parameters["PositiveElectrode"]["CurrentCollector"]["Thickness"] = 50.0e-6

# Tabs are specified as fractions of the total spiral length of each current
# collector, which is the natural coordinate for wound-cell tab placement.
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabFractions"] = [0.2, 0.5, 0.8]
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabFractions"] = [0.2, 0.5, 0.8]
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabWidth"] = 0.002
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabWidth"] = 0.002

simulation_settings["AngularGridPoints"] = 30
nothing #hide

# ## Create the simulation object

model = LithiumIonBattery(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

grids = sim.grids
couplings = sim.couplings
nothing #hide

# ## Visualize the wound component meshes

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide

for (i, component) in enumerate(components)
	if i == 1
		global fig, ax = plot_mesh(grids[component], color = colors[i])
	else
		plot_mesh!(ax, grids[component], color = colors[i])
	end
	plot_mesh_edges!(ax, grids[component], color = :black, linewidth = 0.6)
end
ax.aspect = :data
ax.azimuth[] = 5.0
ax.elevation[] = 0.35
display(GLMakie.Screen(), fig)
fig #hide

# ## Highlight the tab couplings

for component in ["NegativeCurrentCollector", "PositiveCurrentCollector"]
	plot_mesh!(
		ax, grids[component];
		boundaryfaces = couplings[component]["External"]["boundaryfaces"],
		color = :red,
	)
end

ax.aspect = :data
ax.azimuth[] = 5.0
ax.elevation[] = 0.35
display(GLMakie.Screen(), fig)
fig #hide

# # ## Run a compact simulation
# output = solve(sim; info_level = -1)
# nothing #hide

# # ## Visualize the simulation output

# plot_dashboard(output; plot_type = "simple")

# plot_interactive_3d(output)

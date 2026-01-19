# # Verification of the pouch geometry

# ### Import packages

using BattMo, GLMakie, Jutul

# ## Load input parameters and settings

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

cell_parameters["Cell"]["NumberOfLayers"] = 2
cell_parameters["Cell"]["TabsOnSameSide"] = false
cell_parameters["NegativeElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.2
cell_parameters["PositiveElectrode"]["CurrentCollector"]["TabPositionFraction"] = 0.8

simulation_settings["ElectrodeWidthGridPoints"] = 11


model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);


# ## Plot geometry
grids     = sim.grids
couplings = sim.couplings


components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide



for (i, component) in enumerate(components)
	if i == 1
		global fig, ax = plot_mesh(grids[component],
			color = colors[i])
		# ax.aspect = :data
	else
		plot_mesh!(ax,
			grids[component],
			color = colors[i])
	end
end

# ## Solve the simulation

output = solve(sim)

# ## Plot the 

plot_interactive_3d(output; colormap = :curl)
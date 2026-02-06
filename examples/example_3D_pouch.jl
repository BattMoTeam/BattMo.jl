using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

cycling_protocol["DRate"] = 1


model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

grids     = sim.grids
couplings = sim.couplings


components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide

# We plot the geometry

for (i, component) in enumerate(components)
	if i == 1
		global fig1, ax1 = plot_mesh(grids[component],
			color = colors[i],
			label = string(component))
		# ax.aspect = :data
	else
		plot_mesh!(ax1,
			grids[component],
			color = colors[i],
			label = string(component))
	end
end
legend_elements = [
	PolyElement(color = colors[i]) for i in eachindex(components)
]

Legend(fig1[1, 2], legend_elements, components)

display(GLMakie.Screen(), fig1)

# We plot the grid

for (i, component) in enumerate(components)
	if i == 1
		global fig2, ax2 = plot_mesh_edges(grids[component],
			color = colors[i],
			label = string(component))
		ax2.aspect = :data
	else
		plot_mesh_edges!(ax2,
			grids[component],
			color = colors[i],
			label = string(component))
	end
end
legend_elements = [
	PolyElement(color = colors[i]) for i in eachindex(components)
]

Legend(fig2[1, 2], legend_elements, components)
display(GLMakie.Screen(), fig2)



output = solve(sim)

plot_interactive_3d(output; colormap = :curl)


using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")

cell_parameters["Cell"]["NumberOfLayers"] = 4

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol);

grids     = sim.grids
couplings = sim.couplings


components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide

# We plot the components

for (i, component) in enumerate(components)
	if i == 1
		global fig, ax = plot_mesh(grids[component],
			color = colors[i])
	else
		plot_mesh!(ax,
			grids[component],
			color = colors[i])
	end
end


# components = [
# 	"NegativeCurrentCollector",
# 	"PositiveCurrentCollector",
# ]

# for component in components
# 	global fig2, ax2 = plot_mesh(grids[component];
# 		boundaryfaces = couplings[component]["External"]["boundaryfaces"],
# 		color = :red)
# 	# plot_mesh(ax, grids[component];
# 	# 	boundaryfaces = couplings[component]["External"]["boundaryfaces"],
# 	# 	color = :red)
# end

# fig #hide

# ax.azimuth[] = 4.0
# ax.elevation[] = 1.56


# output = solve(sim)

# plot_interactive_3d(output; colormap = :curl)



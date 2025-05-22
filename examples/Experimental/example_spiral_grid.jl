using BattMo, Jutul, GLMakie

# Load geometry parameters
inputparams = read_battmo_formatted_input(joinpath(pkgdir(BattMo),
                                                   "examples",
                                                   "Experimental",
                                                   "jsoninputs",
                                                   "4680-geometry.json"))

grids, couplings = jelly_roll_grid(inputparams)

fig, ax = plot_mesh(grids["NegativeElectrode"], color = :green)

plot_mesh!(ax, grids["Separator"]; color = :yellow)
plot_mesh!(ax, grids["PositiveElectrode"]; color = :blue)
plot_mesh!(ax, grids["PositiveCurrentCollector"]; color = :red)
plot_mesh!(ax, grids["NegativeCurrentCollector"]; color = :black)

fig

if false
    fig, ax = plot_mesh(grids["NegativeCurrentCollector"])

    plot_mesh!(ax,
               grids["NegativeCurrentCollector"],
               boundaryfaces = couplings["NegativeCurrentCollector"]["External"]["boundaryfaces"],
               color = :red,
               alpha = 0.5)

    plot_mesh!(ax, grids["PositiveCurrentCollector"])

    plot_mesh!(ax,
               grids["PositiveCurrentCollector"],
               boundaryfaces = couplings["PositiveCurrentCollector"]["External"]["boundaryfaces"],
               color = :blue,
               alpha = 0.5)

    # fig, ax = Jutul.plot_mesh(grids["Electrolyte"])
    # Jutul.plot_mesh_edges!(ax, grids["Electrolyte"])
end


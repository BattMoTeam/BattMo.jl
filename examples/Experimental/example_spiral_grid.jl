using BattMo, Jutul, GLMakie

# Load geometry parameters
inputparams = read_battmo_formatted_input(joinpath(pkgdir(BattMo),
                                                   "examples",
                                                   "Experimental",
                                                   "jsoninputs",
                                                   "4680-geometry.json"))

grids, couplings = jelly_roll_grid(inputparams)

# fig, ax = plot_mesh(grids["Electrolyte"]; color = :green)
# plot_mesh!(ax, grids["Electrolyte"];  cells = couplings["Electrolyte"]["NegativeElectrode"]["cells"], color = :yellow)
# plot_mesh!(ax, grids["Electrolyte"];  cells = couplings["Electrolyte"]["PositiveElectrode"]["cells"], color = :blue)

# fig, ax = plot_mesh(grids["NegativeElectrode"]; color = :green)
# plot_mesh!(ax, grids["NegativeElectrode"];  cells = couplings["NegativeElectrode"]["Electrolyte"]["cells"], color = :yellow)

# fig, ax = plot_mesh(grids["NegativeElectrode"]; color = :green)
# plot_mesh!(ax, grids["NegativeElectrode"]; boundaryfaces  = couplings["NegativeElectrode"]["NegativeCurrentCollector"]["faces"], color = :blue)
# plot_mesh!(ax, grids["NegativeCurrentCollector"];  color = :yellow)

# fig, ax = plot_mesh(grids["NegativeCurrentCollector"]; color = :black)
# plot_mesh!(ax,
#            grids["NegativeCurrentCollector"];
#            boundaryfaces  = couplings["NegativeCurrentCollector"]["NegativeElectrode"]["faces"], color = :yellow)
# plot_mesh!(ax, grids["NegativeElectrode"];  color = :blue, alpha = 0.3)

fig, ax = plot_mesh(grids["PositiveCurrentCollector"]; color = :red)
plot_mesh!(ax,
           grids["PositiveCurrentCollector"];
           boundaryfaces  = couplings["PositiveCurrentCollector"]["PositiveElectrode"]["faces"], color = :yellow)
# plot_mesh!(ax, grids["PositiveElectrode"];  color = :magenta, alpha = 0.3)


# fig, ax = plot_mesh(grids["Electrolyte"]; color = :green)
# plot_mesh!(ax, grids["PositiveCurrentCollector"]; color = :red)
# plot_mesh!(ax, grids["PositiveElectrode"]; color = :magenta)
# plot_mesh!(ax, grids["NegativeCurrentCollector"]; color = :black)
# plot_mesh!(ax, grids["NegativeElectrode"]; color = :blue)

fig

if false
    plot_mesh!(ax,
               grids["NegativeCurrentCollector"],
               boundaryfaces = couplings["NegativeCurrentCollector"]["External"]["boundaryfaces"],
               color = :red,
               alpha = 0.5)
    plot_mesh!(ax,
               grids["PositiveCurrentCollector"],
               boundaryfaces = couplings["PositiveCurrentCollector"]["External"]["boundaryfaces"],
               color = :blue,
               alpha = 0.5)
end


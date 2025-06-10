using BattMo, Jutul, GLMakie

case = "4680"

if case == "4680"
    
    # Load geometry parameters
    inputparams = load_battmo_formatted_input(joinpath(pkgdir(BattMo),
                                                       "examples",
                                                       "Experimental",
                                                       "jsoninputs",
                                                       "4680-geometry.json"))

    # inputparams["Geometry"]["numberOfDiscretizationCellsVertical"]    = 2
    # inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"] = 60e-6
    # inputparams["PositiveElectrode"]["CurrentCollector"]["thickness"] = 60e-6
    # inputparams["Geometry"]["numberOfDiscretizationCellsAngular"]     = 30
    
    grids, couplings = jelly_roll_grid(inputparams)
    
elseif case =="pouch"
    
    # Load geometry parameters
    inputparams = load_battmo_formatted_input(joinpath(pkgdir(BattMo),
                                                       "examples",
                                                       "Experimental",
                                                       "jsoninputs",
                                                       "geometry-3d-demo.json"))

    grids, couplings = pouch_grid(inputparams)

else
    
    error("case not recognized")
    
end


let ax, components, colors

    components = [
        "NegativeElectrode",
        "PositiveElectrode",
        "NegativeCurrentCollector",
        "PositiveCurrentCollector"
    ]

    colors = [
        :gray,
        :green,
        :blue,
        :black
    ]

    for (i, component) in enumerate(components)
        if i == 1
            global fig
            fig, ax = plot_mesh(grids[component],
                                color = colors[i])
        else
            plot_mesh!(ax,
                       grids[component],
                       color = colors[i])
        end
    end

    components = [
        "NegativeCurrentCollector",
        "PositiveCurrentCollector"
    ]

    for component in components
        plot_mesh!(ax, grids[component],
                   boundaryfaces = couplings[component]["External"]["boundaryfaces"],
                   color = :red)
    end

end


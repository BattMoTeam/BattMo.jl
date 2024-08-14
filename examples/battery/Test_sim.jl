using Jutul, BattMo, Plots, GLMakie
using StatsBase

include("jutul_grid_utils.jl")





    
H_mother, maps... = basic_grid_example_p4d2()
plot_grid_test(UnstructuredMesh(H_mother))

paramsz =  [2, 3, 3, 3, 2] .* [10, 100, 50, 80, 10] .* 1e-6


grids = setup_geometry(H_mother, paramsz)

ugrids = convert_geometry(grids)
##

##
# set boundary and coupling to control
if include_cc
    g = ugrids["PositiveCurrentCollector"]
    faces,val = findBoundary(g,1,false);
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("PositiveCurrentCollector" => Dict("cells" => cells, "faces" => faces))

    g = ugrids["NegativeCurrentCollector"]
    faces,val = findBoundary(g,1,false);
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeCurrentCollector" => Dict("cells" => faces, "faces" => cells))

    ugrids["Couplings"]["Control"] = coupling_control
    ugrids["Boundary"] = boundary
else
    ##
    do_plot = true
    fig = Figure()
    ax = Axis3(fig[1,1])
    g = ugrids["PositiveElectrode"]

    faces,val = findBoundary(g,3,true);
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("PositiveElectrode" => Dict("cells" => cells, "faces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :red)
        plot_mesh!(ax, g, faces =faces, color = :black)
    end
    g = ugrids["NegativeElectrode"]
    faces,val = findBoundary(g,3,false);
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeElectrode" => Dict("cells" => faces, "faces" => cells))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
        plot_mesh!(ax, g, faces =faces, color = :black)
    end
    ugrids["Couplings"]["Control"] = coupling_control
    ugrids["Boundary"] = boundary
    g = ugrids["Separator"]
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :blue)
    end
    ## 
end



include_cc =false
if(use_p2d)
name = "p2d_40_cccv"
name = "p2d_40_no_cc"
name = "p2d_40_jl_chen2020"
else
end
use_p2d = true
##
fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
init_org = JSONFile(fn)
##
init = deepcopy(init_org)
case = init.object
case["include_current_collectors"] = include_cc
case["NegativeElectrode"]["CurrentCollector"]["density"] = 1000
case["PositiveElectrode"]["CurrentCollector"]["density"] = 1000

init.object["Geometry"]["case"] = "Grid"
init.object["Grids"] = ugrids 
init.object["Grids"]["faceArea"] = 1.0
init.object["Control"]["CRate"] = 0.001
states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);








using Jutul, BattMo, GLMakie#, Plots, GLMakie
using StatsBase
using Infiltrator
GLMakie.closeall()
GLMakie.activate!()
include_cc = false
use_p2d =true

includet("jutul_grid_utils.jl")





    
H_mother, cellmap, facemap, nodemap, paramsz = basic_grid_example_p4d2(nx=1,ny=1,nz=10);
#plot_grid_test(UnstructuredMesh(H_mother))

#paramsz =  [2, 3, 3, 3, 2] .* [10, 100, 50, 80, 10] .* 1e-6
#paramsz =  [1, 1, 1, 1, 1] .* [10, 100, 50, 80, 10] .* 1e-6

grids = setup_geometry(H_mother, paramsz);

ugrids = convert_geometry(grids);
##

##
# set boundary and coupling to control
if include_cc
    g = ugrids["PositiveCurrentCollector"]
    faces,val = findBoundary(g,1,false);
    faces = Vector{Int64}(faces)
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("PositiveCurrentCollector" => Dict("cells" => cells, "boundaryfaces" => faces))

    g = ugrids["NegativeCurrentCollector"]
    faces,val = findBoundary(g,1,false);
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeCurrentCollector" => Dict("cells" => cells, "boundaryfaces" => faces))

    ugrids["Couplings"]["Control"] = coupling_control
    ugrids["Boundary"] = boundary
else
    ##
    do_plot = true
    fig = Figure()#size=(600, 650))
    ax = Axis3(fig[1,1])
    g = ugrids["PositiveElectrode"]

    faces,val = findBoundary(g,3,true);
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("PositiveElectrode" => Dict("cells" => cells, "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :red)
        Jutul.plot_mesh_edges!(ax, g)
        plot_mesh!(ax, g, boundaryfaces =faces, color = :black, alpha = 0.3)
    end
    g = ugrids["NegativeElectrode"]
    faces,val = findBoundary(g,3,false);
    faces = Vector{Int64}(faces)
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeElectrode" => Dict("cells" => cells, "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
        Jutul.plot_mesh_edges!(ax, g)
        plot_mesh!(ax, g, boundaryfaces =faces, color = :black)
    end
    ugrids["Couplings"]["Control"] = coupling_control
    ugrids["Boundary"] = boundary
    g = ugrids["Separator"]
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :blue)
        Jutul.plot_mesh_edges!(ax, g)
    end
    ## 
end
display(GLMakie.Screen(; resolution=(1000, 500), focus_on_show=true),fig)
##




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
init.object["Control"]["CRate"] = 0.1
init.object["Control"]["DRate"] = 0.1108*5e1
init.object["Control"]["rampupTime"] = 1e1/init.object["Control"]["DRate"]
if !include_cc
    init.object["Geometry"]["NegativeElectrode"] = Dict()
    init.object["Geometry"]["PostitiveElectrode"] = Dict()
end
states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);

#
t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
#
# p1 = Plots.plot(t, E;
#                 label     = "",
#                 size      = (1000, 800),
#                 title     = "Voltage",
#                 xlabel    = "Time / s",
#                 ylabel    = "Voltage / V",
#                 markershape = :cross,
#                 markercolor = :black,
#                 markersize = 1,
#                 linewidth = 4,
#                 xtickfont = font(pointsize = 15),
#                 ytickfont = font(pointsize = 15))

# p2 = Plots.plot(t, I;
#                 label     = "",
#                 size      = (1000, 800),
#                 title     = "Current",
#                 xlabel    = "Time / s",
#                 ylabel    = "Current / A",
#                 markershape = :cross,
#                 markercolor = :black,
#                 markersize = 1,
#                 linewidth = 4,
#                 xtickfont = font(pointsize = 15),
#                 ytickfont = font(pointsize = 15))

#                 println("Volatage ", state[:Control][:Phi])

# Plots.plot(p1, p2, layout = (2, 1))



##
mystep = 1
state = states[mystep]
names = ["Electrolyte","NegativeElectrode","PositiveElectrode"]
syms = [:Elyte,:NeAm,:PeAm]
V=state[:Control][:Phi]
println("Current ", state[:Control][:Phi])
println("Current ", state[:Control][:Current])
global myfirst = true
flines = Figure(size = (600, 650))
#axlines = Axis(flines[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
axlines = Axis(flines[1, 1])
for ind in 2:2
#ind = 1
    name = names[ind]
    sym = syms[ind]
    g = init.object["Grids"][name]

    nc = number_of_cells(g)
    z = zeros(nc)
    go = tpfv_geometry(g)
    z = go.cell_centroids[end, :]##
    val = state[sym][:Phi]
    #if(myfirst)
    GLMakie.lines!(axlines, z, val)
    
    if(ind==3)
        ind1,minz = findBoundary(g,3, true)#
        ind2,maxz = findBoundary(g,3, false)
        #minz = minimum(z)
        #maxz = maximum(z)
        vals = Vector{Float64}([V[1], V[1]])
        pos = Vector{Float64}([minz,maxz])
        #GLMakie.lines!(axlines, pos, vals)  
    end
    if(ind==2)
        ind1,minz = findBoundary(g,3, true)#minimum(z)
        ind2,maxz = findBoundary(g,3, false)#maximum(z)
        vals = Vector{Float64}([0, 0])
        pos = Vector{Float64}([minz,maxz])
        GLMakie.lines!(axlines, pos, vals) 
    end

    #end
    #fig = Figure()
    #ax = axis(fig[1,1])
    # if(myfirst)
    #     first = false
    # fig = Plots.plot(z,val)
    # else
    #     Plots.plot!(z,val)
    # end
end
#
display(GLMakie.Screen(),flines)
##
f = Figure(size = (600, 650))
ax1 = Axis(f[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
ax2 = Axis(f[1, 2], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
lines!(ax2,t,I)
lines!(ax1,t,E)
#Label(f[1,1], "Volatage")
display(GLMakie.Screen(),f)


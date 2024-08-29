using Jutul, BattMo, GLMakie
using Plots
using StatsBase
using Infiltrator
GLMakie.closeall()
#GLMakie.activate!()
include_cc = true
use_p2d = true
do_plot = true


fac = 1 # discretisation factor


## Create the pouch_grid
ugrids = pouch_grid(nx = 4*fac, 
                    ny = 4*fac, 
                    nz = 4, 
                    tab_cell_nx = 3, 
                    tab_cell_ny = 2)



if do_plot
    fig = Figure(size = (1600, 900))
    ax  = Axis3(fig[1, 1], zreversed = false)
    for grid in ugrids
        if isa(grid, UnstructuredMesh)
            plot_mesh(ax, grid)
            Jutul.plot_mesh_edges!(ax, grid)
        end
    end
end

# set boundary and coupling to control

if include_cc
    ##
    fig = Figure()#size = (600, 650))
    ax = Axis3(fig[1, 1])
    g = ugrids["PositiveCurrentCollector"]
    faces, val = findBoundary(g, 2, true); 
    faces = Vector{Int64}(faces)
    #faces = faces[1:2]
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("cells" => cells, "boundaryfaces" => faces)
    #coupling_control2 = Dict("PositiveCurrentCollector" => Dict("cells" => ones(size(cells)), "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.2, color = :green)
        Jutul.plot_mesh_edges!(ax, g)
        #display(GLMakie.Screen(; resolution = (1000, 500), focus_on_show = true), fig)
        #plot_mesh!(ax, g, boundaryfaces = faces, color = :red, alpha = 0.3)
        #nf = number_of_faces(g)
        #plot_mesh!(ax, g, cells = cells, color = :red, alpha = 0.3)
        #plot_mesh!(ax, g, faces = (faces .+ = nf), color = :black)
        bfaces = deepcopy(faces)
        plot_mesh!(ax, g, boundaryfaces = bfaces, color = :black, alpha = 0.2)
        Jutul.plot_mesh_edges!(ax, g, boundaryfaces = bfaces, color = :red)
    end
    ##

    g = ugrids["NegativeCurrentCollector"]
    faces, val = findBoundary(g, 2, false); 
    faces = Vector{Int64}(faces)
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeCurrentCollector" => Dict("cells" => cells, "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
        Jutul.plot_mesh_edges!(ax, g)
        bfaces = deepcopy(faces)
        plot_mesh!(ax, g, boundaryfaces = bfaces, color = :black, alphta = 0.2)
        Jutul.plot_mesh_edges!(ax, g, boundaryfaces = bfaces, color = :red)
    end

    #ugrids["Couplings"]["Control"] = coupling_control
    ugrids["Couplings"]["PositiveCurrentCollector"]["Control"] = coupling_control
    ugrids["Boundary"] = boundary
    
    if do_plot
        gridnames = ["NegativeElectrode", "PositiveElectrode", "Separator"]
        for (ind, gname) in enumerate(gridnames)
            g = ugrids[gname]
            plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :gray)
            Jutul.plot_mesh_edges!(ax, g)
        end
    end
else
    ##
    do_plot = true
    fig = Figure()#size = (600, 650))
    ax = Axis3(fig[1, 1])
    g = ugrids["PositiveElectrode"]

    faces, val = findBoundary(g, 3, true); 
    cells = g.boundary_faces.neighbors[faces]
    coupling_control = Dict("PositiveElectrode" => Dict("cells" => cells, "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :red)
        Jutul.plot_mesh_edges!(ax, g)
        plot_mesh!(ax, g, boundaryfaces = faces, color = :black, alpha = 0.3)
    end
    g = ugrids["NegativeElectrode"]
    faces, val = findBoundary(g, 3, false); 
    faces = Vector{Int64}(faces)
    cells = g.boundary_faces.neighbors[faces]
    boundary = Dict("NegativeElectrode" => Dict("cells" => cells, "boundaryfaces" => faces))
    if do_plot
        plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
        Jutul.plot_mesh_edges!(ax, g)
        plot_mesh!(ax, g, boundaryfaces = faces, color = :black)
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
if do_plot
    display(GLMakie.Screen(; resolution = (1000, 500), focus_on_show = true), fig)
end
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
#cond = 1e5
#init.object["PositiveElectrode"]["CurrentCollector"]["electronicConductivity"] = cond
#init.object["NegativeElectrode"]["CurrentCollector"]["electronicConductivity"] = cond
init.object["Geometry"]["case"] = "Grid"
init.object["Grids"] = ugrids 
init.object["Grids"]["faceArea"] = 1.0
init.object["Control"]["CRate"] = 0.1
init.object["Control"]["DRate"] = 0.1108*1e-1
init.object["Control"]["rampupTime"] = 1e2/init.object["Control"]["DRate"]
if !include_cc
    init.object["Geometry"]["NegativeElectrode"] = Dict()
    init.object["Geometry"]["PostitiveElectrode"] = Dict()
end
#geomparams = BAttMo.setup_geomparams_grid(init.object["Grids"], include_cc)
if false
    states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false); 
else
    ##
    sim, forces, state0, parameters, init, model = BattMo.setup_sim(init; use_p2d = use_p2d, use_groups = false, general_ad = false, max_step = nothing)

    #Set up config and timesteps
    timesteps = BattMo.setup_timesteps(init; max_step = nothing)
    cfg = BattMo.setup_config(sim, model, :direct, false)

    # Perform simulation
    cfg[:info_level] = 3
    state0[:Control][:Phi][1] = 4.2
    state0[:Control][:Current][1] = 0
    states, reports = Jutul.simulate(state0, sim, timesteps, forces = forces, config = cfg)
    ##
end

##
t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

if(false)
    p1 = Plots.plot(t, E; 
                    label = "", 
                    size = (1000, 800), 
                    title = "Voltage", 
                    xlabel = "Time / s", 
                    ylabel = "Voltage / V", 
                    markershape = :cross, 
                    markercolor = :black, 
                    markersize = 1, 
                    linewidth = 4, 
                    xtickfont = font(pointsize = 15), 
                    ytickfont = font(pointsize = 15))

    p2 = Plots.plot(t, I; 
                    label = "", 
                    size = (1000, 800), 
                    title = "Current", 
                    xlabel = "Time / s", 
                    ylabel = "Current / A", 
                    markershape = :cross, 
                    markercolor = :black, 
                    markersize = 1, 
                    linewidth = 4, 
                    xtickfont = font(pointsize = 15), 
                    ytickfont = font(pointsize = 15))

    println("Volatage ", state[:Control][:Phi])

    Plots.plot(p1, p2, layout = (2, 1))
end
##


##
mystep = Int64(floor(size(states, 1)/2))
state = states[mystep]
if(include_cc)
    names = ["Electrolyte", "NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
    syms = [:Elyte, :NeAm, :PeAm, :NeCc, :PeCc]
else
    names = ["Electrolyte", "NegativeElectrode", "PositiveElectrode"]
    syms = [:Elyte, :NeAm, :PeAm]
end
V = state[:Control][:Phi]
println("Current ", state[:Control][:Phi])
println("Current ", state[:Control][:Current])
global myfirst = true
flines = Figure(size = (600, 650))
#axlines = Axis(flines[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
axlines = Axis(flines[1, 1])
for ind in 1:5
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
    add_left = false
    add_right = false
    if include_cc
        add_left = (ind == 4)
        add_right = (ind == 5)
    else
        add_left = (ind == 2)
        add_right = (ind == 3)
    end

    if add_right
        ind1, minz = findBoundary(g, 3, true)#
        ind2, maxz = findBoundary(g, 3, false)
        #minz = minimum(z)
        #maxz = maximum(z)
        vals = Vector{Float64}([V[1], V[1]])
        pos = Vector{Float64}([minz, maxz])
        GLMakie.lines!(axlines, pos, vals)  
    end
    
    if add_left
        ind1, minz = findBoundary(g, 3, true)#minimum(z)
        ind2, maxz = findBoundary(g, 3, false)#maximum(z)
        vals = Vector{Float64}([0, 0])
        pos = Vector{Float64}([minz, maxz])
        GLMakie.lines!(axlines, pos, vals) 
    end

    #end
    #fig = Figure()
    #ax = axis(fig[1, 1])
    # if(myfirst)
    #     first = false
    # fig = Plots.plot(z, val)
    # else
    #     Plots.plot!(z, val)
    # end
end
#name = names[ind]
#sym = syms[ind]
if do_plot
    display(GLMakie.Screen(), flines)
end
##
if do_plot
    f = Figure(size = (600, 650))
    ax1 = Axis(f[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
    ax2 = Axis(f[1, 2], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
    lines!(ax2, t, I)
    lines!(ax1, t, E)
    #Label(f[1, 1], "Volatage")
    display(GLMakie.Screen(), f)
end


##
if do_plot
    f3D = Figure(size = (600, 650))
    ax3d = Axis3(f3D[1, 1])
    ind = 5
    for ind in 2:5
        name = names[ind]
        sym = syms[ind]
        g = init.object["Grids"][name]
        phi = state[sym][:Phi]
        #Jutul.plot_cell_data(g, phi)
        Jutul.plot_cell_data!(ax3d, g, phi .- mean(phi))
    end
    #GLMakie.Colorbar(f3D, limits = (0, 10), colormap = :viridis, flipaxis = false)
    #scale!(ax3d.scene, 3, 3, 3)
    display(GLMakie.Screen(), f3D)
end
##
#nf = number_of_faces(g)
#for i in 1:nf
#    Jutul.plot_mesh!(g; faces = i)
#    display(GLMakie.Screen(), f3D)
#end

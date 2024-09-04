using Jutul, BattMo, GLMakie
using Plots
using StatsBase
using Infiltrator
GLMakie.closeall()

##########################
# setup input parameters #
##########################

name = "p2d_40_jl_chen2020"

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = readBattMoJsonInputFile(fn)

inputparams = mergeInputParams(inputparams_geometry, inputparams)

############################
# setup and run simulation #
############################

output = run_battery(inputparams);

########################
# plot discharge curve #
########################

states = output[:states]
model  = output[:extra][:model]

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

p1 = Plots.plot(t, E;
                label     = "",
                size      = (1000, 800),
                title     = "Voltage",
                xlabel    = "Time / s",
                ylabel    = "Voltage / V",
                markershape = :cross,
                markercolor = :black,
                markersize = 1,
                linewidth = 4,
                xtickfont = font(pointsize = 15),
                ytickfont = font(pointsize = 15))


p2 = Plots.plot(t, I;
                label     = "",
                size      = (1000, 800),
                title     = "Current",
                xlabel    = "Time / s",
                ylabel    = "Current / A",
                markershape = :cross,
                markercolor = :black,
                markersize = 1,
                linewidth = 4,
                xtickfont = font(pointsize = 15),
                ytickfont = font(pointsize = 15))


Plots.plot(p1, p2, layout = (2, 1))

############################################
# plot potential on grid at last time step #
############################################

state = states[end]
f3D = Figure(size = (600, 650))
ax3d = Axis3(f3D[1, 1])

components = [:NeCc, :NeAm, :PeAm, :PeCc]
for component in components
    g = model[component].domain.representation
    phi = state[component][:Phi]
    Jutul.plot_cell_data!(ax3d, g, phi .- mean(phi))
end
display(GLMakie.Screen(), f3D)

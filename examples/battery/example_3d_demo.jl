using Jutul, BattMo, GLMakie
using Plots
using StatsBase
using Infiltrator
GLMakie.closeall()

name = "p2d_40_jl_chen2020"

fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = readBattMoJsonInputFile(fn)

inputparams = mergeInputParams(inputparams, inputparams_geometry)

sim, forces, state0, parameters, init, model = BattMo.setup_sim(inputparams;
                                                                use_groups = false,
                                                                general_ad = false,
                                                                max_step   = nothing)

#Set up config and timesteps
timesteps = BattMo.setup_timesteps(init; max_step = nothing)
cfg = BattMo.setup_config(sim, model, :direct, false)

# Perform simulation
cfg[:info_level] = 3
state0[:Control][:Phi][1] = 4.2
state0[:Control][:Current][1] = 0

states, reports = Jutul.simulate(state0, sim, timesteps, forces = forces, config = cfg)

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

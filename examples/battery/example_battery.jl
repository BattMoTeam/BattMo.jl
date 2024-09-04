#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#

# ENV["JULIA_STACKTRACE_MINIMAL"] = true

using Jutul, BattMo, Plots
using MAT

ENV["JULIA_DEBUG"] = 0;

use_p2d = true

if use_p2d
    # name = "p2d_40"
    name = "p2d_40_no_cc"
    # name = "p2d_40_cccv"
    # name = "p2d_40_jl_chen2020"
    # name = "3d_demo_case"
else
    name = "p1d_40"
    #name = "3d_demo_case"
end

function load_reference_solution(name)
    fn = string(dirname(pathof(BattMo)), "/../test/data/", name, ".mat")
    refdict = MAT.matread(fn)
    return refdict
end

# sim, forces, state0, parameters, exported, model = BattMo.setup_sim(name, use_p2d = use_p2d)

do_json = true

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
    inputparams = readBattMoJsonInputFile(fn)
    config_kwargs = (info_level = 10, )
    function hook(simulator,
                  model,
                  state0,
                  forces,
                  timesteps,
                  cfg)
        # cfg[:max_timestep_cuts] = 1
        # cfg[:max_nonlinear_iterations] = 10
    end
    output = run_battery(inputparams;
                         use_p2d = use_p2d,
                         hook = hook,
                         config_kwargs = config_kwargs,
                         extra_timing = false);

    states = output[:states]
    
    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]
    
else
    
    fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", name, ".mat")
    inputparams = readBattMoMatlabInputFile(fn)
    inputparams.dict["use_state_ref"] = true
    config_kwargs = (info_level = 10,)

    function hook(simulator,
                  model,
                  state0,
                  forces,
                  timesteps,
                  cfg)

        names = [:Elyte,
                 :NeAm,
                 :PeCc,
                 :Control,
                 :NeCc,
                 :PeAm]           

        for name in names
            cfg[:tolerances][name][:default] = 1e-8
        end
        
    end

    output = run_battery(inputparams;
                         use_p2d = use_p2d,
                         hook = hook,
                         config_kwargs = config_kwargs,
                         max_step = nothing);
    states = output[:states]
    
    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]

    nsteps = size(states, 1)
    
    statesref = extra[:inputparams].dict["states"]
    timeref   = t
    Eref      = [state["Control"]["E"] for state in statesref[1 : nsteps]]
    Iref      = [state["Control"]["I"] for state in statesref[1 : nsteps]]
    
end

p1 = plot(t, E;
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

if !do_json
    plot!(p1, t, Eref;
          linewidth = 2,
          markershape = :cross,
          markercolor = :black,
          markersize = 1)
end

p2 = plot(t, I;
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

if !do_json
    plot!(p2, t, Iref;
          linewidth = 2,
          markershape = :cross,
          markercolor = :black,
          markersize = 1)
end

plot(p1, p2, layout = (2, 1))


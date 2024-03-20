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
    # name = "3d_demo_case"
else
    # name = "p1d_40"
    name = "3d_demo_case"
end

function load_reference_solution(name)
    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    refdict = MAT.matread(fn)
    return refdict
end

# sim, forces, state0, parameters, exported, model = BattMo.setup_sim(name, use_p2d = use_p2d)

do_json = false

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
    init = JSONFile(fn)
    states, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);

    nsteps = size(states)
    timesteps = extra[:timesteps]
    
    t = cumsum(timesteps)
    E = [state[:Control][:Phi][1] for state in states]
    t = t[1 : length(E)]    

    # refdict = load_reference_solution(name)
    # statesref  = refdict["states"]

    # timeref = [state["time"] for state in statesref]
    # Eref    = [state["Control"]["E"] for state in statesref]


else
    
    states, reports, extra, exported = run_battery(name; use_p2d = use_p2d, info_level = 0, max_step = nothing);

    nsteps = size(states, 1)

    timesteps = extra[:timesteps]
    t = cumsum(timesteps[1 : nsteps])
    E = [state[:Control][:Phi][1] for state in states]
    t = t[1 : length(E)]
    
    statesref = extra[:init].object["states"]
    timeref   = t
    Eref      = [state["Control"]["E"] for state in statesref[1 : nsteps]]

end

plt = plot(t, E;
           title     = "Discharge Voltage",
           size      = (1000, 800),
           label     = "BattMo.jl",
           xlabel    = "Time / s",
           ylabel    = "Voltage / V",
           linewidth = 4,
           xtickfont = font(pointsize = 15),
           ytickfont = font(pointsize = 15))

# plot!(timeref, Eref, label = "BattMo.m", linewidth = 2)
display(plt)


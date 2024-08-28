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

use_p2d = false

if use_p2d
    name = "p2d_40"
    #name = "p2d_40_no_cc"
    #name = "p2d_40_cccv"
    name = "p2d_40_jl_chen2020"
    #name = "3d_demo_case"
else
    name = "p2d_40"
    name = "p2d_40_jl_chen2020"
    #name = "p1d_40"
    #name = "3d_demo_case"
end

function load_reference_solution(name)
    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    refdict = MAT.matread(fn)
    return refdict
end

# sim, forces, state0, parameters, exported, model = BattMo.setup_sim(name, use_p2d = use_p2d)

do_json = true

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
    init = JSONFile(fn)
    include_cc = init.object["include_current_collectors"]
    if !use_p2d
        init.object["PositiveElectrode"]["Coating"]["ActiveMaterial"]["InterDiffusionCoefficient"]= 0
        init.object["NegativeElectrode"]["Coating"]["ActiveMaterial"]["InterDiffusionCoefficient"]= 0
    end
    if include_cc
        case = init.object
        case["NegativeElectrode"]["CurrentCollector"]["density"] = 1000
        case["PositiveElectrode"]["CurrentCollector"]["density"] = 1000
    end
#    model = setup_battery_model(init, use_groups = false, use_p2d    = use_p2d)
    states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);

    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]
    
else
    
    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    init = MatlabFile(fn)

    states, reports, extra, exported = run_battery(init; use_p2d = use_p2d, info_level = 0, max_step = nothing);

    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]
    
    statesref = extra[:init].object["states"]
    timeref   = t
    Eref      = [state["Control"]["E"] for state in statesref[1 : nsteps]]

end

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

model = BattMo.setup_battery_model(init, use_groups = false, use_p2d    = use_p2d)
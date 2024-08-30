#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#

# ENV["JULIA_STACKTRACE_MINIMAL"] = true

using Jutul, BattMo, Plots
using MAT, Flux, BSON

ENV["JULIA_DEBUG"] = 0;

use_p2d = true

train_ML_model = false

if train_ML_model
    include("train_OCP_ML_models.jl")
    train_model_neg_electrode()
    train_model_pos_electrode()
end

name = "p2d_40_cccv"
fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
init = JSONFile(fn)

init.object["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"] = Dict(
    "type" => "function",
    "functionname" => "computeOCP_ML_negative_electrode",
    "argumentlist" => ["concentration", "temperature", "cmax"]
)

init.object["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"] = Dict(
    "type" => "function",
    "functionname" => "computeOCP_ML_positive_electrode",
    "argumentlist" => ["concentration", "temperature", "cmax"]
)

states, cellSpecifications, reports, extra = run_battery(init; 
    use_p2d = use_p2d, 
    info_level = 0, 
    extra_timing = false
);

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


using Jutul, BattMo, Plots
using MAT

ENV["JULIA_DEBUG"] = 0;

use_p2d = true


# name = "p2d_40"
# name = "p2d_40_no_cc"
name = "p2d_40_cccv"
# name = "p2d_40_jl_chen2020"
# name = "3d_demo_case"

##
fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
init_org = JSONFile(fn)
##
init = deepcopy(init_org)
case = init.object

function makeGeometry(case)
L = 0;
N = 0;
geometry = Dict();
coupling = Dict()
bcomponents = ["Separator"]#,"NegativeElectrode","PositiveElectrode"]
for component in bcomponents
    Lloc = case[component]["thickness"];
    Nloc = case[component]["N"]
    
    delete!(case[component],"N")
    delete!(case[component],"thickness")
    coupling[component] = (N+1):(N+Nloc)
    N = N + Nloc
    L = L + Lloc
    geometry[component] =  CartesianMesh(Tuple(Nloc), Tuple(Lloc))
end
bcomponents = ["NegativeElectrode","PositiveElectrode"]
for component in bcomponents
    Lloc = case[component]["Coating"]["thickness"];
    Nloc = case[component]["Coating"]["N"]
    delete!(case[component]["Coating"],"N")
    delete!(case[component]["Coating"],"thickness")
    coupling[component] = (N+1):(N+Nloc)
    N = N + Nloc
    L = L + Lloc
    geometry[component] =  CartesianMesh(Tuple(Nloc), Tuple(Lloc))   
end
geometry["Electrolyte"] = CartesianMesh(Tuple(N), Tuple(L))
geometry["Global"] = geometry["Electrolyte"]
geometry["Couplings"] = Dict()
geometry["Couplings"]["Electrolyte"] = coupling 
return geometry
end

 
geometry=makeGeometry(case)

coupling = Dict()
#cupling["NegativeElectrode"]

#coupling =



   
init.object["Geometry"]["case"] = "Grid"
init.object["Grids"] = geometry 
init.object["Grids"]["faceArea"] = init.object["Geometry"]["faceArea"]
##
states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);
##
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
using Jutul, BattMo, Plots
using MAT

ENV["JULIA_DEBUG"] = 0;

use_p2d = true


# name = "p2d_40"
# name = "p2d_40_no_cc"
include_cc = false

if (use_p2d)
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
function makeGeometry(case, include_cc)
	#case = deepcopy(case_inn)
	L = 0
	N = 0
	geometry = Dict()
	coupling = Dict()
	geometry["Couplings"] = Dict()

	bcomponents = ["Separator"]#,"NegativeElectrode","PositiveElectrode"]
	for component in bcomponents
		Lloc = case[component]["thickness"]
		Nloc = case[component]["N"]

		delete!(case[component], "N")
		delete!(case[component], "thickness")
		coupling[component] = Dict("cells" => (N+1):(N+Nloc))
		N = N + Nloc
		L = L + Lloc
		geometry[component] = CartesianMesh(Tuple(Nloc), Tuple(Lloc))
	end
	bcomponents = ["NegativeElectrode", "PositiveElectrode"]

	Nam = case["PositiveElectrode"]["Coating"]["N"]
	for component in bcomponents
		Lloc = case[component]["Coating"]["thickness"]
		Nloc = case[component]["Coating"]["N"]
		delete!(case[component]["Coating"], "N")
		delete!(case[component]["Coating"], "thickness")
		coupling[component] = Dict("cells" => (N+1):(N+Nloc))
		N = N + Nloc
		L = L + Lloc
		geometry[component] = CartesianMesh(Tuple(Nloc), Tuple(Lloc))
	end
	geometry["Electrolyte"] = CartesianMesh(Tuple(N), Tuple(L))
	geometry["Global"] = geometry["Electrolyte"]
	geometry["Couplings"] = Dict()
	geometry["Couplings"]["Electrolyte"] = coupling

	if include_cc
		bcomponents = ["NegativeElectrode", "PositiveElectrode"]
		newnames = ["NegativeCurrentCollector", "PositiveCurrentCollector"]
		for (ind, component) in enumerate(bcomponents)
			cc = init.object[component]["CurrentCollector"]
			Nloc = cc["N"]
			Lloc = cc["thickness"]
			N = N + Nloc
			L = L + Lloc
			geometry[newnames[ind]] = CartesianMesh(Tuple(Nloc), Tuple(Lloc))
		end

		Npcc = init.object["PositiveElectrode"]["CurrentCollector"]["N"]
		coupling_control = Dict("PositiveCurrentCollector" => Dict("cells" => Npcc, "faces" => 2))
		geometry["Couplings"]["Control"] = coupling_control
		geometry["Boundary"] = Dict("NegativeCurrentCollector" => Dict("cells" => 1, "faces" => 1))
	else
		coupling_control = Dict("PositiveElectrode" => Dict("cells" => Nam, "faces" => 2))

		#coupling_control["NegativeElectrode"] = Dict("cells" => 1, "faces" => 1)

		geometry["Couplings"]["Control"] = coupling_control

		geometry["Boundary"] = Dict("NegativeElectrode" => Dict("cells" => 1, "faces" => 1))
	end


	return geometry
end

case["NegativeElectrode"]["CurrentCollector"]["density"] = 1000
case["PositiveElectrode"]["CurrentCollector"]["density"] = 1000
geometry = makeGeometry(case, include_cc)

coupling = Dict()
#cupling["NegativeElectrode"]

#coupling =




init.object["Geometry"]["case"] = "Grid"
init.object["Grids"] = geometry
init.object["Grids"]["faceArea"] = init.object["Geometry"]["faceArea"]
##
states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false);
##
t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]



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


Plots.plot(p1, p2, layout = (2, 1))
##
#fig = Figure()
#ax = Axis3(fig[1,1])
plot_mesh!(ax, g, transparency = true, alpha = 0.3)
#plot_mesh!(ax, g, faces =faces, color = :red)
fig

##
t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
##
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


Plots.plot(p1, p2, layout = (2, 1))

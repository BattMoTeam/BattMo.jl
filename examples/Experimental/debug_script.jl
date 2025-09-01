using Jutul, BattMo, Plots
using MAT

fn = "/home/xavier/Julia/BattMo/examples/battery/battmo_formatted_input.json"
init = JSONFile(fn)

# init.object["TimeStepping"]["numberOfTimeSteps"] = 400
init.object["Control"]["numberOfCycles"] = 50

states, reports, extra = run_battery(init; info_level = 0, max_timestep_cuts = 10)

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Voltage][1] for state in states]
plt = plot(t, E;
	title     = "Discharge Voltage",
	size      = (1000, 800),
	label     = "BattMo.jl",
	xlabel    = "Time / s",
	ylabel    = "Voltage / V",
	linewidth = 4,
	xtickfont = font(pointsize = 15),
	ytickfont = font(pointsize = 15))
display(plt)


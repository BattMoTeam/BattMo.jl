using BattMo, GLMakie

####################
# setup simulation #
####################

function getinput(name)
    return read_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

# load geometry parameters
inputparams_geometry = getinput("4680-geometry.json")
# inputparams_geometry = getinput("geometry-1d.json")
# inputparams_geometry = getinput("geometry-3d-demo.json")
# load material parameters
inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# load control parameters
inputparams_control = getinput("cc_discharge_control.json")

inputparams = merge_input_params([inputparams_geometry, inputparams_material, inputparams_control])


##################
# run simulation #
##################

output = run_battery(inputparams)

############
# plotting #
############

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	          t,
	          E;
	          linewidth = 4,
	          markersize = 10,
	          marker = :cross,
	          markercolor = :black
              )

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	          t,
	          I;
	          linewidth = 4,
	          markersize = 10,
	          marker = :cross,
	          markercolor = :black
              )

f



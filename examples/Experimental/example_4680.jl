using BattMo, GLMakie

inputparams = load_battmo_formatted_input(joinpath(pkgdir(BattMo), "test", "data", "jsonfiles", "4680_example.json"))

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



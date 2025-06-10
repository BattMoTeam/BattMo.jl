using BattMo, GLMakie

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/4680_case.mat")
inputparams = load_matlab_battmo_input(fn)

function myhook(;simulator, model, state0, forces, timesteps, cfg)
    cfg[:info_level] = 10
end

    
output = run_battery(inputparams; max_step = nothing, hook = myhook)

## ploting

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

# ax = Axis(f[1, 2],
# 	title = "Current",
# 	xlabel = "Time / s",
# 	ylabel = "Current / A",
# 	xlabelsize = 25,
# 	ylabelsize = 25,
# 	xticklabelsize = 25,
# 	yticklabelsize = 25,
# )

# scatterlines!(ax,
# 	          t,
# 	          I;
# 	          linewidth = 4,
# 	          markersize = 10,
# 	          marker = :cross,
# 	          markercolor = :black
#               )

refstates = vec(output[:extra][:inputparams]["states"])
t = [state["time"][1] for state in refstates]
E = [state["Control"]["E"] for state in refstates]

scatterlines!(ax,
	          t,
	          E;
	          linewidth = 4,
	          markersize = 10,
	          marker = :cross,
	          markercolor = :blue,
              label = "matlab"
              )
Legend(f[1, 2], ax)

f


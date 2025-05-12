using BattMo, GLMakie, Jutul

model_setup = LithiumIonBattery()

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCycling")


sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output = solve(sim)

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[1, 2], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f


current_func = get_1d_interpolator(t, I, cap_endpoints = false)

sim_current = Simulation(model_setup, cell_parameters, current_func)




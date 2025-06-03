using BattMo, GLMakie

include("example_functions/current_function.jl")

model_setup = LithiumIonBattery()
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")
simulation_settings["TimeStepDuration"] = 1


cycling_protocol = load_cycling_protocol(; from_default_set = "user_defined_current_function")

cycling_protocol["TotalTime"] = 1800

sim_current = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);

output2 = solve(sim_current);


states2 = output2[:states]

t = [state[:Control][:Controller].time for state in states2]
E = [state[:Control][:Phi][1] for state in states2]
I = [state[:Control][:Current][1] for state in states2]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[2, 1], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

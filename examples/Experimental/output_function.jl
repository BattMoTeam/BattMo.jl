using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
model_settings = load_model_settings(; from_default_set = "P2D")

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim;)

time_series = get_output_time_series(output, ["Voltage", "Current"])
states = get_output_states(output, ["PeAmPotential", "NeAmPotential"])
metrics = get_output_metrics(output, ["DischargeEnergy", "DischargeCapacity"])

@info metrics.CycleNumber
@info metrics.DischargeEnergy
@info metrics.DischargeCapacity

t = time_series[:Time]
I = time_series[:Current]
E = time_series[:Voltage]


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


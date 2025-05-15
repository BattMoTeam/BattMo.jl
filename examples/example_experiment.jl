using BattMo, GLMakie

cycling_protocol = load_cycling_protocol(; from_default_set = "experiment")
cycling_protocol["Experiment"] = [
	"Rest for 4000 s",
	"Discharge at 500 mA until 3.0 V",
	"Hold at 3.0 V until 1e-4 A",
	"Charge at 1 A until 4.0 V",
	"Rest for 1 hour"]

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol)

output = solve(sim; info_level = 1)

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]


# Now we can use GLMakie to create a plot. Lets first plot the cell voltage.

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
	markercolor = :black,
)

f # hide

# And the cell current.

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / V",
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
	markercolor = :black,
)
f
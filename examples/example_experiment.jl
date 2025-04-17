using BattMo

experiment = Experiment([
	"Rest for 4000 s",
	"Discharge at 1 mA until 3.0 V",
	"Hold at 3.0 V until 1e-4 A",
	"Charge at 1 A until 4.0 V",
	"Rest for 1 hour",
]);

cycling_protocol = convert_experiment_to_battmo_control_input(experiment)

@info cycling_protocol

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", "p2d_40", ".json")
inputparams = load_battmo_formatted_input(fn)
inputparams.all["Control"] = cycling_protocol["Control"]

@info inputparams

ouput = run_battery(inputparams)


states = output[:states]

t = [state[:Control][:ControllerCV].time for state in states]
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
# # Cycling a battery 40 times with a constant current constant voltage (CCCV) control

using BattMo, GLMakie
# We use the setup provided in the [p2d_40.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152) file. In particular, see the data under the `Control` key.
file_path_cell = parameter_file_path("cell_parameters", "Chen2020_calibrated.json")
file_path_model = parameter_file_path("model_settings", "P2D.json")
file_path_cycling = parameter_file_path("cycling_protocols", "CCCycling.json")
file_path_simulation = parameter_file_path("simulation_settings", "P2D.json")

cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
model_settings = load_model_settings(; from_file_path = file_path_model)
simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)

model_setup = LithiumIonBattery(; model_settings);

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim; info_level = 1)

nothing # hide

states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide

# ## Plot the results
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
	markercolor = :black)

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

f




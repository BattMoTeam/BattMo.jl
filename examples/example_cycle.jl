# # Cycling a battery 40 times with a constant current constant voltage (CCCV) control

using BattMo, GLMakie
# We use the setup provided in the [p2d_40.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152) file. In particular, see the data under the `Control` key.
file_path_cell = string(
    dirname(pathof(BattMo)),
    "/../test/data/jsonfiles/cell_parameters/",
    "cell_parameter_set_3D_demoCase.json",
)
file_path_model = string(
    dirname(pathof(BattMo)),
    "/../test/data/jsonfiles/model_settings/",
    "model_settings_P2D.json",
)
file_path_cycling = string(
    dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCCV.json"
)
file_path_simulation = string(
    dirname(pathof(BattMo)),
    "/../test/data/jsonfiles/simulation_settings/",
    "simulation_settings_P2D.json",
)

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
model_settings = read_model_settings(file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)

########################################

model = LithiumIonBatteryModel(; model_settings);

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim)

nothing # hide

states = output[:states]

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide

# ## Plot the results
f = Figure(; size=(1000, 400))

ax = Axis(
    f[1, 1];
    title="Voltage",
    xlabel="Time / s",
    ylabel="Voltage / V",
    xlabelsize=25,
    ylabelsize=25,
    xticklabelsize=25,
    yticklabelsize=25,
)

scatterlines!(ax, t, E; linewidth=4, markersize=10, marker=:cross, markercolor=:black)

ax = Axis(
    f[1, 2];
    title="Current",
    xlabel="Time / s",
    ylabel="Current / A",
    xlabelsize=25,
    ylabelsize=25,
    xticklabelsize=25,
    yticklabelsize=25,
)

scatterlines!(ax, t, I; linewidth=4, markersize=10, marker=:cross, markercolor=:black)

f

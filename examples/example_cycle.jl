# # Cycling a battery 40 times with a constant current constant voltage (CCCV) control

using BattMo, GLMakie
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))
# We use the setup provided in the [p2d_40.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152) file. In particular, see the data under the `Control` key.
file_path_cell = parameter_file_path("cell_parameters", "Chayambuka2022.json")
file_path_model = parameter_file_path("model_settings", "P2D.json")
file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")
file_path_simulation = parameter_file_path("simulation_settings", "P2D.json")

cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
model_settings = load_model_settings(; from_file_path = file_path_model)
simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)

model = SodiumIonBattery(; model_settings);

# cycling_protocol["TotalNumberOfCycles"] = 3
cycling_protocol["DRate"] = 2
cycling_protocol["CRate"] = 1
cycling_protocol["InitialStateOfCharge"] = 0.99

sim = Simulation(model, cell_parameters, cycling_protocol);


output = solve(sim; info_level = 1)

nothing # hide

# ## Plot the results
plot_dashboard(output, plot_type = "simple")


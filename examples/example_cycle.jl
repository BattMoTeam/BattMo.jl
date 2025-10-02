# # Cycling a battery 40 times with a constant current constant voltage (CCCV) control

using BattMo, GLMakie

# We use the setup provided in the [p2d_40.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152) file. In particular, see the data under the `Control` key.
file_path_cell = parameter_file_path("cell_parameters", "Xu2015.json")
file_path_cycling = parameter_file_path("cycling_protocols", "CCDischarge.json")


cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)


model = LithiumIonBattery();

cycling_protocol["TotalNumberOfCycles"] = 40

sim = Simulation(model, cell_parameters, cycling_protocol);


output = solve(sim;)

nothing # hide

# ## Plot the results
plot_dashboard(output, plot_type = "simple")


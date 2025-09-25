# # Advanced Dict UI

using BattMo, GLMakie

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
file_path = joinpath(battmo_base, "test/data/matlab_files/p2d_40.mat")

simulation_input = load_matlab_input(file_path)

output = run_simulation(simulation_input)

plot_dashboard(output; plot_type = "contour")

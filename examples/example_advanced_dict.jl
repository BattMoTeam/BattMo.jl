# # Advanced Dict UI

using BattMo, GLMakie

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
file_path = joinpath(battmo_base, "test/data/jsonfiles/p2d_40_jl_chen2020.json")

simulation_input = load_advanced_dict_input(file_path)

output = run_simulation(simulation_input; base_model = "LithiumIonBattery")

plot_dashboard(output; plot_type = "contour")





using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_file_path = joinpath(@__DIR__,"mj1p4d3.json"))
#cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
#cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(@__DIR__,"custom_discharge2.json"))
#model_settings = load_model_settings(; from_default_set = "P4D_pouch")
model_settings = load_model_settings(;from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
simulation_settings = load_simulation_settings(; from_file_path = joinpath(@__DIR__,"model2.json"))
#simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch



model_setup = LithiumIonBattery(; model_settings)


sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);


output = get_simulation_input(sim)
grids     = output[:grids]
couplings = output[:couplings]


components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]


for (i, component) in enumerate(components)
    if i == 1
        global fig, ax = plot_mesh(grids[component],
                            color = colors[i])
    else
        plot_mesh!(ax,
                   grids[component],
                   color = colors[i])
    end
end


output = solve(sim; accept_invalid = true)


@show keys(output)
@show haskey(output, :states)
@show length(output.states)

plot_interactive_3d(output; colormap = :curl)
using BattMo, GLMakie

cell_parameters     = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol    = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings      = load_model_settings(; from_default_set = "P4D_cylindrical")
simulation_settings = load_simulation_settings(; from_default_set = "P4D_cylindrical")

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);


function hook(simulator,
			  model,
			  state0,
			  forces,
			  timesteps,
			  cfg)
    
    cfg[:info_level] = 10
    
end

output = solve(sim; hook)


plot_3D_results(output; colormap = :curl)

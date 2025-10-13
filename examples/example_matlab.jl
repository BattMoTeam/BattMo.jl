using BattMo, Jutul, GLMakie

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/p2d_40.mat")
inputparams = load_matlab_input(fn)

output = BattMo.get_simulation_input(inputparams::MatlabInput)

simulator  = output[:simulator]
model      = output[:model]
parameters = output[:parameters]
state0     = output[:state0]
timesteps  = output[:timesteps]
forces     = output[:forces]

# Setup solver configuration

cfg = simulator_config(simulator)
cfg[:info_level] = 10

use_model_scaling = true
if use_model_scaling
	scalings = BattMo.get_matlab_scalings(model, parameters)
	tol_default = 1e-5
	for scaling in scalings
		model_label = scaling[:model_label]
		equation_label = scaling[:equation_label]
		value = scaling[:value]
		cfg[:tolerances][model_label][equation_label] = value * tol_default
	end
else
	for key in submodels_symbols(model)
		cfg[:tolerances][key][:default] = 1e-5
	end
end

states, = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:ElectricPotential][1] for state in states]

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

f


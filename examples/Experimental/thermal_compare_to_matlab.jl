using BattMo, GLMakie, MAT, Jutul, Statistics


###############################################
# MATLAB data

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/runOnlyThermal.mat")

file = matopen(fn)
data = read(file)
close(file)

t_matlab = data["time"][:, 1]
E_matlab = data["E"][:, 1]

T_max_matlab = []
for i in range(1, length(t_matlab))
	T_matlab = data["states_thermal"][i]["T"]

	push!(T_max_matlab, maximum(T_matlab[i]))
end


###################################################
# Julia data

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
inputparams_material = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = load_advanced_dict_input(fn)

inputparams = merge_input_params([inputparams_material, inputparams_geometry])

# Add control parameters
fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
inputparams_control = load_advanced_dict_input(fn)
inputparams_control["Control"]["lowerCutoffVoltage"] = 3.6

inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

# Add thermal parameters
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = load_advanced_dict_input(fn)

inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

# Add Thermal Model
inputparams["use_thermal"] = true

output = run_simulation(inputparams; accept_invalid = true);

E = output.time_series["Voltage"]


input = (
	model_settings      = output.simulation.model.settings,
	cell_parameters     = output.simulation.cell_parameters,
	cycling_protocol    = output.simulation.cycling_protocol,
	simulation_settings = output.simulation.settings,
)

model      = output.model
multimodel = model.multimodel
states     = output.jutul_output.states
parameters = output.simulation.parameters
grids      = output.simulation.grids
maps       = output.simulation.global_maps
timesteps  = output.simulation.time_steps[1:length(states)]


thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)

forces = []
sources = []
for (i, state) in enumerate(states)
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source!(thermal_model, model, state, maps)
	push!(forces, (value = src,))
	push!(sources, stepsources)
end

nc = number_of_cells(thermal_model.domain)
T0 = 298*ones(nc)

thermal_state0 = setup_state(thermal_model, Dict(:Temperature => T0))

thermal_sim = Simulator(thermal_model;
	state0     = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)
thermal_states, = simulate(thermal_sim, timesteps; info_level = -1, forces = forces)

t = output.time_series["Time"]
T = thermal_states
T_max = [maximum(state[:Temperature]) for state in thermal_states]

#########################################################
# Comparison plot

f1 = Figure(size = (1000, 400))
ax1 = Axis(f1[1, 1],
	title = "Maximum Temperature",
	xlabel = "Time / s",
	ylabel = "Temperature / \u00B0C",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_ = scatterlines!(ax1,
	t_matlab,
	T_max_matlab .- 273.15;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_ = scatterlines!(ax1,
	t,
	T_max .- 273.15;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f1[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f1)

f2 = Figure(size = (1000, 400))
ax2 = Axis(f2[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_ = scatterlines!(ax2,
	t_matlab,
	E_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_ = scatterlines!(ax2,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f2[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f2)

using Jutul, BattMo, GLMakie, Statistics


##



fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
inputparams_material = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = load_advanced_dict_input(fn)

inputparams = merge_input_params([inputparams_material, inputparams_geometry])

fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
inputparams_control = load_advanced_dict_input(fn)
inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = load_advanced_dict_input(fn)
inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)



# Adjust input parameters to match the MATLAB simulation

function getnested(d, keys::Tuple)
	for k in keys
		d = d[k]
	end
	return d
end

function setnested!(d, keys::Tuple, value)
	lastkey = last(keys)
	parent = getnested(d, keys[1:(end-1)])
	parent[lastkey] = value
end


locations = [
	("NegativeElectrode", "Coating", "ActiveMaterial", "specificHeatCapacity"),
	("PositiveElectrode", "Coating", "ActiveMaterial", "specificHeatCapacity"),
	("NegativeElectrode", "CurrentCollector", "specificHeatCapacity"),
	("PositiveElectrode", "CurrentCollector", "specificHeatCapacity"),
	("Electrolyte", "specificHeatCapacity"),
]

for loc in locations
	oldval = getnested(inputparams.all, loc)
	setnested!(inputparams.all, loc, oldval * 5e-2)
end



inputparams["Control"]["lowerCutoffVoltage"] = 3.6
# inputparams["Geometry"]["Nh"] = 16  # needs to be electrode Nh + 2 * tab Nh from MATLAB geometry
# inputparams["Geometry"]["height"] = 2e-2 + 2*1e-3# needs to be electrode height + 2 * tab height from MATLAB geometry
inputparams["PositiveElectrode"]["CurrentCollector"]["thickness"] = 80e-6 # in order to match the MATLAB geometry.
inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"] = 100e-6# in order to match the MATLAB geometry.


# Run simulation

output_old = run_simulation(inputparams; accept_invalid = true)

##
tstates = output_old.jutul_output.states
elyte_temp = map(s -> maximum(s[:Electrolyte][:Temperature]), tstates)
pam_temp = map(s -> maximum(s[:PositiveElectrodeActiveMaterial][:Temperature]), tstates)
nam_temp = map(s -> maximum(s[:NegativeElectrodeActiveMaterial][:Temperature]), tstates)

fig, ax, plt = lines(elyte_temp, label = "Electrolyte temperature (coupled)")
lines!(ax, pam_temp, label = "Positive electrode temperature (coupled)")
lines!(ax, nam_temp, label = "Negative electrode temperature (coupled)")
axislegend()
fig

plot_interactive_3d(output_old)




############# BattMo.jl format

## Setup input parameters
cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")

##
# Decoupled thermal simulation
####

model_settings["ThermalModel"] = "Decoupled"
model_settings["TemperatureDependence"] = "Arrhenius"

cycling_protocol["InitialTemperature"] = 298.15
cycling_protocol["ExternalTemperature"] = 298.15

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim);


##
time_series = output.time_series;
states = output.states;

t = time_series["Time"];
E = time_series["Voltage"];
I = time_series["Current"];

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / h",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t ./ 3600,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

display(GLMakie.Screen(), f)

plot_interactive_3d(output)

##
# jutul_states = output.jutul_output.states;
# thermal_model = sim.decoupled_thermal.model;
# thermal_states = [state[:ThermalModel] for state in jutul_states];



# Plot maximum temperature in the cell over time

T = vec(maximum(output.states["ThermalModel"]["Temperature"], dims = 2))

f2 = Figure(size = (1000, 400))

ax = Axis(f2[1, 1],
	title = "Maximum temperature in the cell",
	xlabel = "Time / h",
	ylabel = "Temperature / K",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t ./ 3600, # convert time to hours
	T;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	# label = "Julia",
)

display(GLMakie.Screen(), f2)


##
# Sequential thermal simulation
####

model_settings = load_model_settings(; from_default_set = "p4d_pouch")
model_settings["ThermalModel"] = "Sequential"
model_settings["TemperatureDependence"] = "Arrhenius"

s = Simulation(model, cell_parameters, cycling_protocol);

# for k in [:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial, :Electrolyte]
# 	push!(s.simulator.model.models[k].output_variables, :Temperature)
# end
##
result_sequential = solve(s);


##
tstates = output_old.jutul_output.states
elyte_temp = map(s -> maximum(s[:Electrolyte][:Temperature]), tstates)
pam_temp = map(s -> maximum(s[:PositiveElectrodeActiveMaterial][:Temperature]), tstates)
nam_temp = map(s -> maximum(s[:NegativeElectrodeActiveMaterial][:Temperature]), tstates)

fig, ax, plt = lines(T, label = "Maximum temperature (decoupled)")
lines!(ax, elyte_temp, label = "Electrolyte temperature (coupled)")
lines!(ax, pam_temp, label = "Positive electrode temperature (coupled)")
lines!(ax, nam_temp, label = "Negative electrode temperature (coupled)")
axislegend()
fig

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

inputparams["use_thermal"] = true

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

output_old = run_simulation(inputparams; accept_invalid = true);

##
# T = vec(maximum(output_old.states["ThermalModel"]["Temperature"], dims = 2))
tstates = output_old.jutul_output.states
elyte_temp = map(s -> maximum(s[:Electrolyte][:Temperature]), tstates)
pam_temp = map(s -> maximum(s[:PositiveElectrodeActiveMaterial][:Temperature]), tstates)
nam_temp = map(s -> maximum(s[:NegativeElectrodeActiveMaterial][:Temperature]), tstates)

fig, ax, plt = lines(elyte_temp, label = "Electrolyte temperature (coupled)")

# lines!(T, label = "Maximum temperature (decoupled)")
lines!(ax, pam_temp, label = "Positive electrode temperature (coupled)")
lines!(ax, nam_temp, label = "Negative electrode temperature (coupled)")
axislegend()
fig

plot_interactive_3d(output_old)

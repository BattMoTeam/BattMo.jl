using BattMo


function getinput(name)
    return read_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

# load geometry parameters
# inputparams_geometry = getinput("4680-geometry.json")
inputparams_geometry = getinput("geometry1d.json")
# load material parameters
inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# load control parameters
inputparams_control = getinput("cc_discharge_control.json")

a = [inputparams_geometry, inputparams_material, inputparams_control]

inputparams = merge_input_params(a)
inputparams["include_current_collectors"] = false
inputparams["include_current_collectors"] = false
inputparams["TimeStepping"] = Dict("useRampup" => true)

run_battery(inputparams)


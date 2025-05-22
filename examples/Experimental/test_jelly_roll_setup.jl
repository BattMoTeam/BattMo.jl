using BattMo, Jutul, GLMakie

function getinput(name)
    return read_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

# load geometry parameters
inputparams_geometry = getinput("4680-geometry.json")
# load material parameters
inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# load control parameters
inputparams_control = getinput("cc_discharge_control.json")

inputparams = merge_input_params([inputparams_geometry, inputparams_material, inputparams_control])

grids = jelly_roll_grid(inputparams)
nothing

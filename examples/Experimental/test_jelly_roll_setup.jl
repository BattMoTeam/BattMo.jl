using BattMo, Jutul, GLMakie

"local helper function to load data"
function getinput(name)
    return read_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

# Load geometrical parameters
inputparams_geometry = getinput("4680-geometry.json")
# Load material parameters
inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# Load control parameters
inputparams_control = getinput("cc_discharge_control.json")

inputparams = merge_input_params([inputparams_geometry, inputparams_material, inputparams_control])

output = get_simulation_input(deepcopy(inputparams))

simulator = output[:simulator]
model     = output[:model]
state0    = output[:state0]
forces    = output[:forces]
timesteps = output[:timesteps]
cfg       = output[:cfg]

cfg[:info_level] = 10

states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

nothing

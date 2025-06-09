using BattMo, GLMakie

function getinput(name)
    return load_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

############################
# load geometry parameters #
############################

inputparams_geometry = getinput("4680-geometry.json")

# set_input_params!(inputparams_geometry, ["Geometry", "numberOfDiscretizationCellsAngular"], 4, handleMismatch = :warn)
# set_input_params!(inputparams_geometry, ["Geometry", "outerRadius"], 4e-3, handleMismatch = :warn)
# set_input_params!(inputparams_geometry, ["NegativeElectrode", "CurrentCollector", "tabparams", "usetab"] , false, handleMismatch = :warn)
# set_input_params!(inputparams_geometry, ["PositiveElectrode", "CurrentCollector", "tabparams", "usetab"] , false, handleMismatch = :warn)
# inputparams_geometry = getinput("geometry-1d.json")
# inputparams_geometry = getinput("geometry-3d-demo.json")

############################
# load material parameters #
############################

inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")

###########################
# load control parameters #
###########################

inputparams_control = getinput("cc_discharge_control.json")

##########################
# load solver parameters #
##########################

inputparams_solver = getinput("solver_setup.json")
set_input_params!(inputparams_solver, ["NonLinearSolver", "LinearSolver", "method"], "direct", handleMismatch = :warn)
####################
# merge parameters #
####################

inputparams = merge_input_params([inputparams_geometry,
                                  inputparams_material,
                                  inputparams_control,
                                  inputparams_solver])

inputparams["Control"]["DRate"]       = 0.001
inputparams["Control"]["useCVswitch"] = false

##################
# run simulation #
##################

function hook(simulator,
			  model,
			  state0,
			  forces,
			  timesteps,
			  cfg)
    
    cfg[:info_level] = 2
    
end

output = run_battery(inputparams; hook)
states = output[:states]

############
# plotting #
############


t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

fig = Figure(size = (1000, 400))

ax = Axis(fig[1, 1],
	title = "Voltage",
	xlabel = "Time / hour",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	          t/3600,
	          E;
	          linewidth = 4,
	          markersize = 10,
	          marker = :cross,
	          markercolor = :black
              )

ax = Axis(fig[1, 2],
	title = "Current",
	xlabel = "Time / hour",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	          t/3600,
	          I;
	          linewidth = 4,
	          markersize = 10,
	          marker = :cross,
	          markercolor = :black
              )

fig



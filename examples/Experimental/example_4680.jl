using BattMo, GLMakie

function getinput(name)
    return load_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

############################
# load geometry parameters #
############################

# inputparams_geometry = getinput("4680-geometry.json")
inputparams_geometry = getinput("geometry-1d.json")
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

inputparams_solver = getinput("linear_solver_setup.json")

####################
# merge parameters #
####################

inputparams = merge_input_params([inputparams_geometry,
                                  inputparams_material,
                                  inputparams_control,
                                  inputparams_solver])

inputparams["Control"]["DRate"]       = 1
inputparams["Control"]["useCVswitch"] = false

##################
# run simulation #
##################

use_iterative_solver = false

if use_iterative_solver
    
    model_kwargs = (context = Jutul.DefaultContext(),)
    output = get_simulation_input(inputparams; model_kwargs)

    simulator = output[:simulator]
    model     = output[:model]
    state0    = output[:state0]
    forces    = output[:forces]
    timesteps = output[:timesteps]
    cfg       = output[:cfg]

    #cfg[:linear_solver]
    cfg[:info_level] = 10

    solver  = :fgmres
    fac     = 1e-3  # NEEDED  1e-4 ok for 3D case 1e-7 need for 1D case
    rtol    = 1e-4 * fac  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
    atol    = 1e-5 * fac # seems important
    max_it  = 100
    verbose = 10

    # We combine two preconditioners. One working on a subset of variables and equations (we call it block-preconditioner)
    # and the other for the full system

    # We first setup the block preconditioners. They are given as a list and applied separatly. Preferably, they
    # should be orthogonal
    varpreconds = Vector{BattMo.VariablePrecond}()
    push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Phi, :charge_conservation, nothing))
    #push!(varpreconds,BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(),:Cp,:mass_conservation, [:PeAm,:NeAm]))
    #push!(varpreconds,BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben),:C,:mass_conservation, [:Elyte]))

    # We setup the global preconditioner
    g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)

    params = Dict()
    # Type of method used for the block preconditioners. Here "block" means separatly (other options can be found
    # BatteryGeneralPreconditione)
    params["method"] = "block"
    # Option for post- and pre-solve of the control system. 
    params["post_solve_control"] = true
    params["pre_solve_control"]  = true

    # We setup the preconditioner, which combines both the block and global preconditioners
    prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)
    #prec = Jutul.ILUZeroPreconditioner()

    cfg[:linear_solver] = GenericKrylov(solver, verbose = verbose,
	                                    preconditioner = prec,
	                                    relative_tolerance = rtol,
	                                    absolute_tolerance = atol * 1e-20,## may skip linear iterations all to getter.
	                                    max_iterations = max_it)
    cfg[:extra_timing] = true

    # Perform simulation
    states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

else
    
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
    
end
############
# plotting #
############


t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

fig = Figure(size = (1000, 400))

ax = Axis(fig[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
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
	xlabel = "Time / s",
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



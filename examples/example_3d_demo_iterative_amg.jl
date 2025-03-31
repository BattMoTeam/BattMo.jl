using Jutul, BattMo, GLMakie
using StatsBase
using Plots
using AlgebraicMultigrid
using Preconditioners
using Preferences

# Useful for development to avoid running when precompiling fails
set_preferences!(BattMo, "precompile_workload" => false; force = true)
set_preferences!(Jutul, "precompile_workload" => false; force = true)

##########################
# setup input parameters #
##########################

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020.json")
file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P4D_pouch.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")
file_path_simulation = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simulation_settings/", "simulation_settings_P4D_pouch.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
model_settings = read_model_settings(file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)


model = LithiumIon(; model_settings)


simple = false
if (!simple)

	facx  = 2
	facy  = facx
	facz  = 2
	fac2p = 1

	simulation_settings.dict["GridPoints"]["ElectrodeLength"] *= facy
	simulation_settings.dict["GridPoints"]["ElectrodeWidth"] *= facy
	simulation_settings.dict["GridPoints"]["Separator"] *= facz
	simulation_settings.dict["GridPoints"]["PositiveElectrodeActiveMaterial"] *= facz
	simulation_settings.dict["GridPoints"]["NegativeElectrodeActiveMaterial"] *= facz
	simulation_settings.dict["GridPoints"]["NegativeElectrodeCurrentCollectorTabLength"] *= facy
	simulation_settings.dict["GridPoints"]["NegativeElectrodeCurrentCollectorTabWidth"] *= facx
	simulation_settings.dict["GridPoints"]["PositiveElectrodeCurrentCollectorTabLength"] *= facy
	simulation_settings.dict["GridPoints"]["PositiveElectrodeCurrentCollectorTabWidth"] *= facx
	simulation_settings.dict["GridPoints"]["NegativeElectrodeCurrentCollector"] *= facz
	simulation_settings.dict["GridPoints"]["PositiveElectrodeCurrentCollector"] *= facz

else
	file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P2D.json")
	file_path_simulation = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simulation_settings/", "simulation_settings_P2D.json")

	model_settings = read_model_settings(file_path_model)
	simulation_settings = read_simulation_settings(file_path_simulation)

	model_settings["UseCurrentCollectors"] = false
end

inputparams = convert_parameter_sets_to_battmo_input(model_settings, cell_parameters, cycling_protocol, simulation_settings)

############################
# setup and run simulation #
############################

model_kwargs = (context = Jutul.DefaultContext(),)
output = setup_simulation(inputparams; model_kwargs)

simulator = output[:simulator]
model     = output[:model]
state0    = output[:state0]
forces    = output[:forces]
timesteps = output[:timesteps]
cfg       = output[:cfg]

#cfg[:linear_solver]
cfg[:info_level] = 10

solver  = :fgmres
fac     = 1e-3  #NEEDED  1e-4 ok for 3D case 1e-7 need for 1D case
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

########################
# plot discharge curve #
########################

#states = output[:states]
#model  = output[:extra][:model]

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black)

display(f)


############################################
# plot potential on grid at last time step #
############################################

do_plot = true

if (do_plot)

	state = states[10]

	setups = ((:PeCc, :PeAm, "positive"),
		(:NeCc, :NeAm, "negative"))


	for setup in setups

		f3D = Figure(size = (600, 650))
		ax3d = Axis3(f3D[1, 1];
			title = "Potential in $(setup[3]) electrode (coating and active material)")

		am = setup[1]
		cc = setup[2]

		maxPhi = maximum([maximum(state[cc][:Phi]), maximum(state[am][:Phi])])
		minPhi = minimum([minimum(state[cc][:Phi]), minimum(state[am][:Phi])])

		colorrange = [0, maxPhi - minPhi]

		components = [am, cc]
		for component in components
			g = model[component].domain.representation
			phi = state[component][:Phi]
			Jutul.plot_cell_data!(ax3d, g, phi .- minPhi; colormap = :viridis, colorrange = colorrange)
		end

		cbar = GLMakie.Colorbar(f3D[1, 2];
			colormap = :viridis,
			colorrange = colorrange .+ minPhi,
			label = "potential")
		display(GLMakie.Screen(), f3D)

	end

	setups = ((:PeAm, "positive"),
		(:NeAm, "negative"))

	for setup in setups

		f3D = Figure(size = (600, 650))
		ax3d = Axis3(f3D[1, 1];
			title = "Surface concentration in $(setup[2]) electrode")

		component = setup[1]

		cs = state[component][:Cs]
		maxcs = maximum(cs)
		mincs = minimum(cs)

		colorrange = [0, maxcs - mincs]

		g = model[component].domain.representation
		Jutul.plot_cell_data!(ax3d, g, cs .- mincs;
			colormap = :viridis,
			colorrange = colorrange)

		cbar = GLMakie.Colorbar(f3D[1, 2];
			colormap = :viridis,
			colorrange = colorrange .+ mincs,
			label = "concentration")
		display(GLMakie.Screen(), f3D)

	end


	setups = ((:C, "concentration"),
		(:Phi, "potential"))

	for setup in setups

		f3D = Figure(size = (600, 650))
		ax3d = Axis3(f3D[1, 1];
			title = "$(setup[2]) in electrolyte")

		var = setup[1]

		val = state[:Elyte][var]
		maxval = maximum(val)
		minval = minimum(val)

		colorrange = [0, maxval - minval]

		g = model[:Elyte].domain.representation
		Jutul.plot_cell_data!(ax3d, g, val .- minval;
			colormap = :viridis,
			colorrange = colorrange)

		cbar = GLMakie.Colorbar(f3D[1, 2];
			colormap = :viridis,
			colorrange = colorrange .+ minval,
			label = "$(setup[2])")
		display(GLMakie.Screen(), f3D)

	end

end

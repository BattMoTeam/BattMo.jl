using Jutul, BattMo, GLMakie
using StatsBase
using AlgebraicMultigrid
using Preconditioners
using Preferences

##########################
# setup input parameters #
##########################

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p4d_pouch")

############################
# setup simulation #
############################

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol);

############################
# setup solver             #
############################

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
push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :ElectricPotential, :charge_conservation, nothing))
#push!(varpreconds,BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(),:ParticleConcentration,:mass_conservation, [:PositiveElectrodeActiveMaterial,:NegativeElectrodeActiveMaterial]))
#push!(varpreconds,BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben),:Concentration,:mass_conservation, [:Electrolyte]))

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

linear_solver = GenericKrylov(solver, verbose = verbose,
	preconditioner = prec,
	relative_tolerance = rtol,
	absolute_tolerance = atol * 1e-20,## may skip linear iterations all to getter.
	max_iterations = max_it)



############################
# solve simulation #
############################


output = BattMo.solve(sim;
	info_level = 10,
	linear_solver = linear_solver,
	extra_timing = true,
)

# plot_interactive_3d(output; colormap = :curl)


########################
# plot discharge curve #
########################

states = output.jutul_output.states
multimodel = output.jutul_output.multimodel

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:ElectricPotential][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

# plot_dashboard(output)


grids     = sim.grids
couplings = sim.couplings

components = ["NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
colors = [:gray, :green, :blue, :black]

for (i, component) in enumerate(components)
	if i == 1
		global fig, ax = plot_mesh(grids[component],
			color = colors[i])
	else
		plot_mesh!(ax,
			grids[component],
			color = colors[i])
	end
end

components = [
	"NegativeCurrentCollector",
	"PositiveCurrentCollector",
]

for component in components
	plot_mesh!(ax, grids[component];
		boundaryfaces = couplings[component]["External"]["boundaryfaces"],
		color = :red)
end

############################################
# plot potential on grid at last time step #
############################################

# do_plot = true

# if (do_plot)

# 	state = states[10]

# 	setups = ((:PositiveElectrodeCurrentCollector, :PositiveElectrodeActiveMaterial, "positive"),
# 		(:NegativeElectrodeCurrentCollector, :NegativeElectrodeActiveMaterial, "negative"))


# 	for setup in setups

# 		f3D = Figure(size = (600, 650))
# 		ax3d = Axis3(f3D[1, 1];
# 			title = "Potential in $(setup[3]) electrode (coating and active material)")

# 		am = setup[1]
# 		cc = setup[2]

# 		maxVoltage = maximum([maximum(state[cc][:ElectricPotential]), maximum(state[am][:ElectricPotential])])
# 		minVoltage = minimum([minimum(state[cc][:ElectricPotential]), minimum(state[am][:ElectricPotential])])

# 		colorrange = [0, maxVoltage - minVoltage]

# 		components = [am, cc]
# 		for component in components
# 			g = multimodel[component].domain.representation
# 			phi = state[component][:ElectricPotential]
# 			Jutul.plot_cell_data!(ax3d, g, phi .- minVoltage; colormap = :viridis, colorrange = colorrange)
# 		end

# 		cbar = GLMakie.Colorbar(f3D[1, 2];
# 			colormap = :viridis,
# 			colorrange = colorrange .+ minVoltage,
# 			label = "potential")
# 		display(GLMakie.Screen(), f3D)

# 	end

# 	setups = ((:PositiveElectrodeActiveMaterial, "positive"),
# 		(:NegativeElectrodeActiveMaterial, "negative"))

# 	for setup in setups

# 		f3D = Figure(size = (600, 650))
# 		ax3d = Axis3(f3D[1, 1];
# 			title = "Surface concentration in $(setup[2]) electrode")

# 		component = setup[1]

# 		cs = state[component][:SurfaceConcentration]
# 		maxcs = maximum(cs)
# 		mincs = minimum(cs)

# 		colorrange = [0, maxcs - mincs]

# 		g = multimodel[component].domain.representation
# 		Jutul.plot_cell_data!(ax3d, g, cs .- mincs;
# 			colormap = :viridis,
# 			colorrange = colorrange)

# 		cbar = GLMakie.Colorbar(f3D[1, 2];
# 			colormap = :viridis,
# 			colorrange = colorrange .+ mincs,
# 			label = "concentration")
# 		display(GLMakie.Screen(), f3D)

# 	end


# 	setups = ((:ElectrolyteConcentration, "concentration"),
# 		(:ElectricPotential, "potential"))

# 	for setup in setups

# 		f3D = Figure(size = (600, 650))
# 		ax3d = Axis3(f3D[1, 1];
# 			title = "$(setup[2]) in electrolyte")

# 		var = setup[1]

# 		val = state[:Electrolyte][var]
# 		maxval = maximum(val)
# 		minval = minimum(val)

# 		colorrange = [0, maxval - minval]

# 		g = multimodel[:Electrolyte].domain.representation
# 		Jutul.plot_cell_data!(ax3d, g, val .- minval;
# 			colormap = :viridis,
# 			colorrange = colorrange)

# 		cbar = GLMakie.Colorbar(f3D[1, 2];
# 			colormap = :viridis,
# 			colorrange = colorrange .+ minval,
# 			label = "$(setup[2])")
# 		display(GLMakie.Screen(), f3D)

# 	end

# end

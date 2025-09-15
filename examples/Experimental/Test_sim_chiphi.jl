using Jutul, BattMo, GLMakie#, Plots, GLMakie
using HYPRE
using Plots
using StatsBase
using AlgebraicMultigrid
using Preconditioners
using Preferences
#revise(; throw=true)
set_preferences!(BattMo, "precompile_workload" => false; force = true)
set_preferences!(Jutul, "precompile_workload" => false; force = true)
#
GLMakie.closeall()
#GLMakie.activate!()
include_cc = true
use_p2d = false

includet("jutul_grid_utils.jl")
includet("../../src/solver_as_preconditioner.jl")
includet("../../src/solver_as_preconditioner_system.jl")
includet("../../src/precondgenneral.jl")
do_plot = true


nz_fac = 1#2
fac = 1#3*2    
H_mother, cellmap, facemap, nodemap, paramsz = basic_grid_example_p4d2(nx = fac, ny = fac * 2, nz = 10 * nz_fac, tab_cell_nx = 3, tab_cell_ny = 3);
#H_mother, cellmap, facemap, nodemap, paramsz = basic_grid_example_p4d2(nx=2,ny=2,nz=5,tab_cell_nx=0,tab_cell_ny=0);
#H_mother, cellmap, facemap, nodemap, paramsz = basic_grid_example_p4d2(nx=1,ny=1,nz=1,tab_cell_nx=0,tab_cell_ny=0, test=true);
#plot_grid_test(UnstructuredMesh(H_mother))

#paramsz =  [2, 3, 3, 3, 2] .* [10, 100, 50, 80, 10] .* 1e-6
#paramsz =  [1, 1, 1, 1, 1] .* [10, 100, 50, 80, 10] .* 1e-6

grids = setup_geometry(H_mother, paramsz);
if do_plot && false
	plot_grid_test(grids["Global"])
end
##
ugrids = convert_geometry(grids);
##

##
# set boundary and coupling to control
if include_cc
	##
	fig = Figure(size = (500, 650), position = (10, 100))
	ax = Axis3(fig[1, 1])
	g = ugrids["PositiveCurrentCollector"]
	faces, val = findBoundary(g, 2, true)
	faces = Vector{Int64}(faces)
	#faces = faces[1:2]
	cells = g.boundary_faces.neighbors[faces]
	coupling_control = Dict("cells" => cells, "boundaryfaces" => faces)
	#coupling_control2 = Dict("PositiveCurrentCollector" => Dict("cells" => ones(size(cells)), "boundaryfaces" => faces))
	if do_plot
		plot_mesh!(ax, g, transparency = true, alpha = 0.2, color = :green)
		Jutul.plot_mesh_edges!(ax, g)
		#display(GLMakie.Screen(; resolution=(1000, 500), focus_on_show=true),fig)
		#plot_mesh!(ax, g, boundaryfaces =faces, color = :red, alpha = 0.3)
		#nf = number_of_faces(g)
		#plot_mesh!(ax, g, cells =cells, color = :red, alpha = 0.3)
		#plot_mesh!(ax, g, faces = (faces .+=nf) , color = :black)
		bfaces = deepcopy(faces)
		plot_mesh!(ax, g, boundaryfaces = bfaces, color = :black, alpha = 0.2)
		Jutul.plot_mesh_edges!(ax, g, boundaryfaces = bfaces, color = :red)
	end
	##

	g = ugrids["NegativeCurrentCollector"]
	faces, val = findBoundary(g, 2, false)
	faces = Vector{Int64}(faces)
	cells = g.boundary_faces.neighbors[faces]
	boundary = Dict("NegativeCurrentCollector" => Dict("cells" => cells, "boundaryfaces" => faces))
	if do_plot
		plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
		Jutul.plot_mesh_edges!(ax, g)
		bfaces = deepcopy(faces)
		plot_mesh!(ax, g, boundaryfaces = bfaces, color = :black, alphta = 0.2)
		Jutul.plot_mesh_edges!(ax, g, boundaryfaces = bfaces, color = :red)
	end

	#ugrids["Couplings"]["Control"] = coupling_control
	ugrids["Couplings"]["PositiveCurrentCollector"]["Control"] = coupling_control
	ugrids["Boundary"] = boundary

	if do_plot
		gridnames = ["NegativeElectrode", "PositiveElectrode", "Separator"]
		for (ind, gname) in enumerate(gridnames)
			g = ugrids[gname]
			plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :gray)
			Jutul.plot_mesh_edges!(ax, g)
		end
	end
else
	##
	do_plot = true
	fig = Figure()#size=(600, 650))
	ax = Axis3(fig[1, 1])
	g = ugrids["PositiveElectrode"]

	faces, val = findBoundary(g, 3, true)
	cells = g.boundary_faces.neighbors[faces]
	coupling_control = Dict("cells" => cells, "boundaryfaces" => faces)
	if do_plot
		plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :red)
		Jutul.plot_mesh_edges!(ax, g)
		plot_mesh!(ax, g, boundaryfaces = faces, color = :black, alpha = 0.3)
	end
	g = ugrids["NegativeElectrode"]
	faces, val = findBoundary(g, 3, false)
	faces = Vector{Int64}(faces)
	cells = g.boundary_faces.neighbors[faces]
	boundary = Dict("NegativeElectrode" => Dict("cells" => cells, "boundaryfaces" => faces))
	if do_plot
		plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :green)
		Jutul.plot_mesh_edges!(ax, g)
		plot_mesh!(ax, g, boundaryfaces = faces, color = :black)
	end
	ugrids["Couplings"]["PositiveElectrode"]["Control"] = coupling_control
	#ugrids["Couplings"]["Control"] = coupling_control
	ugrids["Boundary"] = boundary
	g = ugrids["Separator"]
	if do_plot
		plot_mesh!(ax, g, transparency = true, alpha = 0.3, color = :blue)
		Jutul.plot_mesh_edges!(ax, g)
	end
	## 
end
if do_plot
	display(GLMakie.Screen(; resolution = (1000, 500), focus_on_show = true), fig)
end
##




if (use_p2d)
	name = "p2d_40"
	name = "p2d_40_cccv"
	name = "p2d_40_no_cc"
	name = "p2d_40_jl_chen2020"
else
	name = "p2d_40_jl_chen2020"
	#name = "p1d_40"
end

##
fn = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", name, ".json")
init_org = JSONFile(fn)
##
init = deepcopy(init_org)
case = init.object
case["include_current_collectors"] = include_cc
if include_cc
	case["NegativeElectrode"]["CurrentCollector"]["density"] = 1000
	case["PositiveElectrode"]["CurrentCollector"]["density"] = 1000
end
cond = 1e4
init.object["PositiveElectrode"]["CurrentCollector"]["electronicConductivity"] = cond
init.object["NegativeElectrode"]["CurrentCollector"]["electronicConductivity"] = cond
init.object["Geometry"]["case"] = "Grid"
init.object["Grids"] = ugrids
init.object["Grids"]["faceArea"] = 1.0
init.object["Control"]["CRate"] = 0.1
init.object["Control"]["DRate"] = 0.1108
init.object["Control"]["rampupTime"] = 1e1 / init.object["Control"]["DRate"]
if !use_p2d
	init.object["PositiveElectrode"]["Coating"]["ActiveMaterial"]["InterDiffusionCoefficient"] = 0
	init.object["NegativeElectrode"]["Coating"]["ActiveMaterial"]["InterDiffusionCoefficient"] = 0
end
if !include_cc
	init.object["Geometry"]["NegativeElectr1.0ode"] = Dict()
	init.object["Geometry"]["PostitiveElectrode"] = Dict()
end
#geomparams = BAttMo.setup_geomparams_grid(init.object["Grids"],include_cc)
if false
	states, cellSpecifications, reports, extra = run_battery(init; use_p2d = use_p2d, info_level = 0, extra_timing = false)
else
	##
	#sim, forces, state0, parameters, init, model = BattMo.setup_sim(init; use_p2d=use_p2d, use_groups=false, general_ad=false, max_step = nothing)
	#model, state0, parameters = BattMo.setup_model(init, use_groups = false, use_p2d    = use_p2d)
	#context = Jutul.ParallelCSRContext(1)
	context = Jutul.DefaultContext()
	model = BattMo.setup_battery_model(init, use_groups = false, use_p2d = use_p2d, context = context)
	parameters = BattMo.setup_battery_parameters(init, model)
	state0 = BattMo.setup_battery_initial_state(init, model)
	BattMo.setup_coupling_grid!(init, model, parameters)
	BattMo.setup_policy!(model[:Control].system.policy, init, parameters)

	minE = init.object["Control"]["lowerCutoffVoltage"]
	@. state0[:Control][:Voltage] = minE * 1.5


	forces = setup_forces(model)

	sim = Simulator(model; state0 = state0, parameters = parameters, copy_state = true)
	#Set up config and timesteps
	timesteps = BattMo.setup_timesteps(init; max_step = nothing)
	timesteps = timesteps[1:1]
	# linear solver :ilu0,:cphi :chi_ilu :amg
	cfg = BattMo.setup_config(sim, model, :cphi_ilu_ilu, false)
	cfg = BattMo.setup_config(sim, model, :cphi, false)
	#cfg = BattMo.setup_config(sim, model, :ilu0, false)
	#cfg = BattMo.setup_config(sim, model, :il5u, false)
	#cfg = BattMo.setup_config(sim, model, :direct, false)
	# Perform simulation
	cfg[:info_level] = 10
	cfg[:tolerances][:Electrolyte][:mass_conservation] = 1e-3
	cfg[:tolerances][:PositiveElectrodeActiveMaterial][:mass_conservation] = 1e-3
	cfg[:tolerances][:NegativeElectrodeActiveMaterial][:mass_conservation] = 1e-3
	cfg[:tolerances][:Control][:default] = 1e-5
	#cfg[:tolerances][:PositiveElectrodeActiveMaterial][:solid_diffusion_bc] = 1e-20
	if true
		solver = :fgmres
		fac = 1e-4
		fac_s = 1e3
		fac_p = 1e1
		rtol = 1e-7  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
		atol = 1e-9 # seems important
		max_it = 100
		verbose = 1
		prec_org_s = Jutul.ILUZeroPreconditioner()
		#prec_org_s = Jutul.AMGPreconditioner(:ruge_stuben)
		#prec_org_p = Jutul.ILUZeroPreconditioner()
		prec_org_p = Jutul.AMGPreconditioner(:ruge_stuben)
		#prec_org_p  = Jutul.TrivialPreconditioner()
		#prec_org_p = Jutul.BoomerAMGPreconditioner()
		ksolver_s = GenericKrylov(solver, verbose = 0,
		preconditioner = prec_org_s,
		relative_tolerance = rtol * fac_s,
		absolute_tolerance = atol * fac_s * 1e-22,
		max_iterations = max_it,
		min_iterations = 4)
		max_it    = 30
		ksolver_p = GenericKrylov(solver, verbose = 0,
		preconditioner = prec_org_p,
		relative_tolerance = rtol * fac_p,
		absolute_tolerance = atol * fac_p * 1e-22,
		max_iterations = max_it,
		min_iterations = 4)
		# p_prec = Jutul.AMGPreconditioner(:ruge_stuben)
		#s_prec = Jutul.AMGPreconditioner(:ruge_stuben)
		p_prec = Jutul.ILUZeroPreconditioner()
		s_prec = Jutul.ILUZeroPreconditioner()
		s_prec = LUPreconditioner()
		p_prec = LUPreconditioner()
		psolver = LUSolver()
		ssolver = LUSolver()
		s_prec = SolverAsPreconditionerSystem(ksolver_s)
		p_prec = SolverAsPreconditionerSystem(ksolver_p)
		#s_prec = Jutul.TrivialPreconditioner()
		#p_prec = Jutul.TrivialPreconditioner()
		#g_prec = SolverAsPreconditionerSystem(ksolver_p)
		if true
			prec_org_s = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_s  = GenericKrylov(solver, verbose = 0,
			preconditioner = prec_org_s,
			relative_tolerance = 1e-5,
			absolute_tolerance = atol * fac_s * 1e-22,
			max_iterations = max_it,
			min_iterations = 4)
			prec_org_p = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_p  = GenericKrylov(solver, verbose = 0,
			preconditioner = prec_org_p,
			relative_tolerance = 1e-6,
			absolute_tolerance = atol * fac_p * 1e-22,
			max_iterations = max_it,
			min_iterations = 4)
			s_prec     = SolverAsPreconditionerSystem(ksolver_s)
			p_prec     = SolverAsPreconditionerSystem(ksolver_p)
			#p_prec = Jutul.AMGPreconditioner(:ruge_stuben)
			#s_prec = Jutul.AMGPreconditioner(:ruge_stuben)# also ok?
			#s_prec = Jutul.ILUZeroPreconditioner() # seems to be sufficent?
			#p_prec = Jutul.ILUZeroPreconditioner() # 
			#s_prec = Jutul.TrivialPreconditioner()
			g_prec = Jutul.TrivialPreconditioner()
			#p_prec = Jutul.TrivialPreconditioner()
			#g_prec = Jutul.ILUZeroPreconditioner()
		else
			#s_prec = Jutul.TrivialPreconditioner()
			#p_prec = Jutul.TrivialPreconditioner()
			# ksolver_p  = GenericKrylov(solver, verbose = 0,
			#                        preconditioner = prec_org_p, 
			#                        relative_tolerance = 1e-6,
			#                        absolute_tolerance = atol*fac_p*1e-22,
			#                        max_iterations = max_it,
			#                        min_iterations = 4)      
			# p_prec = SolverAsPreconditionerSystem(ksolver_p)
			#s_prec = Jutul.AMGPreconditioner(:ruge_stuben)

			#s_prec = Jutul.ILUZeroPreconditioner()
			p_prec = Jutul.AMGPreconditioner(:ruge_stuben)
			s_prec = Jutul.TrivialPreconditioner()
			g_prec = Jutul.ILUZeroPreconditioner()
		end

		#g_prec = Jutul.TrivialPreconditioner()
		#g_prec = Jutul.ILUZeroPreconditioner()
		#s_prec = LUPreconditioner()
		#p_prec = LUPreconditioner()
		prec = BattMo.BatteryCVoltagePreconditioner(s_prec, p_prec, g_prec)

		if false
			varpreconds = Vector{BattMo.VariablePrecond}()
			#push!(varpreconds,BattMo.VariablePrecond(p_prec,:Voltage,:charge_conservation, nothing))
			#push!(varpreconds,BattMo.VariablePrecond(s_prec,:Concentration,:mass_conservation, nothing))
			push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Voltage, :charge_conservation, nothing))
			g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)
		else
			prec_org_s = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_s  = GenericKrylov(solver, verbose = 0,
			preconditioner = prec_org_s,
			relative_tolerance = 1e-5,
			absolute_tolerance = atol * fac_s * 1e-22,
			max_iterations = max_it,
			min_iterations = 4)
			prec_org_p = Jutul.AMGPreconditioner(:ruge_stuben)
			ksolver_p  = GenericKrylov(solver, verbose = 0,
			preconditioner = prec_org_p,
			relative_tolerance = 1e-6,
			absolute_tolerance = atol * fac_p * 1e-22,
			max_iterations = max_it,
			min_iterations = 4)
			s_prec     = SolverAsPreconditionerSystem(ksolver_s)
			p_prec     = SolverAsPreconditionerSystem(ksolver_p)
			#s_prec = Jutul.TrivialPreconditioner()
			#p_prec = Jutul.AMGPreconditioner(:ruge_stuben)
			#p_prec = Jutul.TrivialPreconditioner()
			#p_prec = Jutul.ILUZeroPreconditioner()
			#s_prec = Jutul.ILUZeroPreconditioner()
			s_preccond = BattMo.VariablePrecond(s_prec, :Concentration, :mass_conservation, nothing)
			p_preccond = BattMo.VariablePrecond(p_prec, :Voltage, :charge_conservation, nothing)
			varpreconds = Vector{BattMo.VariablePrecond}()
			#push!(varpreconds, p_preccond)
			#push!(varpreconds, s_preccond)
			push!(varpreconds, deepcopy(p_preccond))
			push!(varpreconds, deepcopy(s_preccond))
			#push!(varpreconds,BattMo.VariablePrecond(s_prec,:Concentration,:mass_conservation, nothing))
			g_varprecond = BattMo.VariablePrecond(Jutul.TrivialPreconditioner(), :Global, :Global, nothing)
			#g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(),:Global,:Global,nothing)
		end
		#g_varprecond = BattMo.VariablePrecond(Jutul.TrivialPreconditioner(),:Global,:Global,nothing)
		cfg[:max_nonlinear_iterations] = 2
		#cfg[:failure_cuts_timestep] =false
		cfg[:max_timestep_cuts] = 1
		params = Dict()
		params["method"] = "block"
		params["post_solve_control"] = true
		params["pre_solve_control"] = true

		#prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)
		#prec = Jutul.ILUZeroPreconditioner()

		#psolver = LUSolver() 
		#prec = SolverAsPreconditionerSystem(psolver)
		#prec = s_prec
		#prec = SolverAsPreconditionerSystem(ksolver)
		#prec = Jutul.ILUZeroPreconditioner()
		solver = :fgmres
		solver = :fgmres
		fac = 1e-5
		rtol = 1e-4 * fac  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
		atol = 1e-5 * fac # seems important
		max_it = 100
		verbose = 1
		cfg[:linear_solver] = GenericKrylov(solver, verbose = verbose,
			preconditioner = prec,
			relative_tolerance = rtol,
			absolute_tolerance = atol,
			max_iterations = max_it)
		#cfg[:linear_solver]  = LUSolver()

		cfg[:extra_timing] = false
	end

	state0[:Control][:Voltage][1] = 4.2
	state0[:Control][:Current][1] = 0
	discharging = BattMo.cc_discharge1
	state0[:Control][:Controller] = BattMo.SimpleControllerCV{Float64}(0.0, 0.0, false, discharging)
	cfg[:failure_cuts_timestep] = false
	states, reports = Jutul.simulate(state0, sim, timesteps, forces = forces, config = cfg)
	##
end

##
t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Voltage][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

if (false)
	p1 = Plots.plot(t, E;
		label = "",
		size = (1000, 800),
		title = "Voltage",
		xlabel = "Time / s",
		ylabel = "Voltage / V",
		markershape = :cross,
		markercolor = :black,
		markersize = 1,
		linewidth = 4,
		xtickfont = font(pointsize = 15),
		ytickfont = font(pointsize = 15))

	p2 = Plots.plot(t, I;
		label = "",
		size = (1000, 800),
		title = "Current",
		xlabel = "Time / s",
		ylabel = "Current / A",
		markershape = :cross,
		markercolor = :black,
		markersize = 1,
		linewidth = 4,
		xtickfont = font(pointsize = 15),
		ytickfont = font(pointsize = 15))

	println("Volatage ", state[:Control][:Voltage])

	Plots.plot(p1, p2, layout = (2, 1))
end
##


##
mystep = Int64(floor(size(states, 1) / 2))
state = states[mystep]
if (include_cc)
	names = ["Electrolyte", "NegativeElectrode", "PositiveElectrode", "NegativeCurrentCollector", "PositiveCurrentCollector"]
	syms = [:Electrolyte, :NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial, :NegativeElectrodeCurrentCollector, :PositiveElectrodeCurrentCollector]
else
	names = ["Electrolyte", "NegativeElectrode", "PositiveElectrode"]
	syms = [:Electrolyte, :NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial]
end
V = state[:Control][:Voltage]
println("Current ", state[:Control][:Voltage])
println("Current ", state[:Control][:Current])
global myfirst = true

axlines = Axis(fig[1, 2], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
#axlines = Axis(flines[1, 1])
if (include_cc)
	indend = 5
else
	indend = 3
end
flines = Figure(size = (600, 650))
flines_c = Figure(size = (600, 650))
for ind in 1:3
	#ind = 1
	axlinesall = Axis(flines[1, ind], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
	axlinesall_c = Axis(flines_c[1, ind], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
	name = names[ind]
	sym = syms[ind]
	g = init.object["Grids"][name]

	nc = number_of_cells(g)
	z = zeros(nc)
	go = tpfv_geometry(g)
	z = go.cell_centroids[end, :]##
	val = state[sym][:Voltage]
	#if(myfirst)
	GLMakie.lines!(axlinesall, z, val)
	if (ind < 2)
		valc = state[sym][:Concentration]
		GLMakie.lines!(axlinesall_c, z, valc)
	end
	if (ind == 2 || ind == 3)
		valc = []
		if BattMo.discretisation_type(model[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion
			valc = state[sym][:Concentration]
		else
			valc = state[sym][:SurfaceConcentration]
		end
		GLMakie.lines!(axlinesall_c, z, valc)
	end
	add_left = false
	add_right = false
	if include_cc
		add_left = (ind == 4)
		add_right = (ind == 5)
	else
		add_left = (ind == 2)
		add_right = (ind == 3)
	end

	if add_right
		ind1, minz = findBoundary(g, 3, true)#
		ind2, maxz = findBoundary(g, 3, false)
		#minz = minimum(z)
		#maxz = maximum(z)
		vals = Vector{Float64}([V[1], V[1]])
		pos = Vector{Float64}([minz, maxz])
		GLMakie.lines!(axlines, pos, vals)
		GLMakie.lines!(axlinesall, pos, vals)
	end
	if add_left
		ind1, minz = findBoundary(g, 3, true)#minimum(z)
		ind2, maxz = findBoundary(g, 3, false)#maximum(z)
		vals = Vector{Float64}([0, 0])
		pos = Vector{Float64}([minz, maxz])
		GLMakie.lines!(axlines, pos, vals)
		GLMakie.lines!(axlinesall, pos, vals)
	end

	#end
	#fig = Figure()
	#ax = axis(fig[1,1])
	# if(myfirst)
	#     first = false
	# fig = Plots.plot(z,val)
	# else
	#     Plots.plot!(z,val)
	# end
end
#name = names[ind]
#sym = syms[ind]
if do_plot
	display(GLMakie.Screen(), flines)
	display(GLMakie.Screen(), flines_c)
end
##
if do_plot
	#f = Figure(size = (600, 650))
	ax1 = Axis(fig[2, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
	ax2 = Axis(fig[2, 2], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
	lines!(ax2, t, I)
	lines!(ax1, t, E)
	#Label(f[1,1], "Volatage")
	#display(GLMakie.Screen(),fig)
end


##
if do_plot && true
	f3D = Figure(size = (600, 650))
	ax3d = Axis3(f3D[1, 1])
	if include_cc
		ind = 5


		for ind in 5:5
			name = names[ind]
			sym = syms[ind]
			g = init.object["Grids"][name]
			phi = state[sym][:Voltage]
			#Jutul.plot_cell_data(g,phi)
			Jutul.plot_cell_data!(ax3d, g, phi .- mean(phi))
			#Jutul.plot_cell_data!(ax3d,g,phi)
		end
		#GLMakie.Colorbar(f3D,limits = (0, 10), colormap = :viridis,flipaxis = false)
		#scale!(ax3d.scene, 3, 3, 3)
		display(GLMakie.Screen(), f3D)
	end
end
##
#nf = number_of_faces(g)
#for i in 1:nf
#    Jutul.plot_mesh!(g;faces = i)
#    display(GLMakie.Screen(),f3D)
#end

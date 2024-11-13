using Jutul, BattMo, GLMakie
using StatsBase
using Plots
using Infiltrator
using AlgebraicMultigrid
using Preconditioners
using Preferences

# Useful for development to avoid running when precompiling fails
set_preferences!(BattMo, "precompile_workload" => false; force=true)
set_preferences!(Jutul, "precompile_workload" => false; force=true)

##########################
# setup input parameters #
##########################

name = "p2d_40_jl_chen2020"

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)


simple = true
if(!simple)
    
    facx  = 1
    facy  = facx
    facz  = 1
    fac2p = 1

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
    inputparams_geometry = readBattMoJsonInputFile(fn)
    inputparams_geometry.dict["Geometry"]["Nh"] *=facy 
    inputparams_geometry.dict["Geometry"]["Nw"] *=facx
    inputparams_geometry.dict["Separator"]["N"] *= facz
    inputparams_geometry.dict["PositiveElectrode"]["Coating"]["N"] *= facz
    inputparams_geometry.dict["NegativeElectrode"]["Coating"]["N"] *= facz
    inputparams_geometry.dict["PositiveElectrode"]["CurrentCollector"]["tab"]["Nh"] *= facy
    inputparams_geometry.dict["PositiveElectrode"]["CurrentCollector"]["tab"]["Nw"] *= facx
    inputparams_geometry.dict["NegativeElectrode"]["CurrentCollector"]["tab"]["Nh"] *= facy
    inputparams_geometry.dict["NegativeElectrode"]["CurrentCollector"]["tab"]["Nw"] *= facx
    inputparams_geometry.dict["NegativeElectrode"]["CurrentCollector"]["N"] *=facz
    inputparams_geometry.dict["PositiveElectrode"]["CurrentCollector"]["N"] *=facz
else
    #fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/1D_geometry.json")
    inputparams_geometry_org = readBattMoJsonInputFile(fn)
end

inputparams_geometry = deepcopy(inputparams_geometry_org)

inputparams_geometry.dict["include_current_collectors"] = false
inputparams = mergeInputParams(deepcopy(inputparams_geometry), inputparams)


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

fac = 1e8
cfg[:tolerances][:PeAm][:solid_diffusion_bc] = 1e-25*fac
cfg[:tolerances][:NeAm][:solid_diffusion_bc] = 1e-25*fac
cfg[:tolerances][:NeAm][:mass_conservation] = 1e-25*fac
cfg[:tolerances][:PeAm][:mass_conservation] = 1e-25*fac
solver = :fgmres
fac = 1e-3  #NEEDED  1e-4 ok for 3D case 1e-7 need for 1D case
rtol = 1e-4*fac  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
atol = 1e-5*fac # seems important
max_it = 100
verbose = 10

varpreconds = Vector{BattMo.VariablePrecond}()

push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben),:Phi,:charge_conservation, nothing))
#push!(varpreconds,BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(),:Cp,:mass_conservation, [:PeAm,:NeAm]))
#push!(varpreconds,BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben),:C,:mass_conservation, [:Elyte]))
g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(),:Global,:Global,nothing)

params = Dict()
params["method"]             = "block"
params["post_solve_control"] = true
params["pre_solve_control"]  = true

prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)
#prec = Jutul.ILUZeroPreconditioner()

cfg[:linear_solver]  = GenericKrylov(solver, verbose = verbose,
                                     preconditioner = prec, 
                                     relative_tolerance = rtol,
                                     absolute_tolerance = atol*1e-20,## may skip linear iterations all to getter.
                                     max_iterations = max_it)
cfg[:extra_timing]   = true               

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
          title     = "Voltage",
          xlabel    = "Time / s",
          ylabel    = "Voltage / V",
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
          title     = "Current",
          xlabel    = "Time / s",
          ylabel    = "Current / A",
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25
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
do_plot = false
if(do_plot)
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

# # 3D battery example
using Jutul, BattMo, GLMakie, Statistics

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = readBattMoJsonInputFile(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = readBattMoJsonInputFile(fn)

inputparams = mergeInputParams(inputparams_geometry, inputparams_thermal)

inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
inputparams["ThermalModel"]["source"]                          = 1e4
inputparams["ThermalModel"]["conductivity"]                    = 12

# model, parameters = BattMo.setup_thermal_model(inputparams)
model, parameters = BattMo.setup_thermal_model(Val(:simple), inputparams; N = 30, Nz = 30)

nc = number_of_cells(model.domain)
T0 = zeros(nc)

state0 = setup_state(model, Dict(:Temperature => T0))

sim = Simulator(model;
                state0     = state0,
                parameters = parameters,
                copy_state = true)

N         = 10
tend      = 1e10
timesteps = tend*collect(1/N : 1/N : 1)

nt = length(timesteps)

vols = parameters[:Volume]

source = (value = 1e8*ones(nc, 1).*vols,)
forces = fill(source, nt)
states, = simulate(sim, timesteps; info_level = -1, forces = forces)

doplot = true

if doplot

    try
        GLMakie.closeall()
    catch
        
    end
    
    f3D = Figure(size = (600, 650))
    ax3d = Axis3(f3D[1, 1];
                 title = "Temperature")

    g = model.domain.representation

    z = g[:cell_centroids][3, :]

    T = states[end][:Temperature]
    # T = state0[:Temperature]

    f = Figure(size = (1000, 400))

    ax = Axis(f[1, 1],
              xlabelsize = 25,
              ylabelsize = 25,
              xticklabelsize = 25,
              yticklabelsize = 25)

    scatterlines!(ax,
                  z,
                  T;
                  linewidth = 4,
                  markersize = 10,
                  marker = :cross, 
                  markercolor = :black,
                  )
    display(GLMakie.Screen(), f)

    println("max: $(maximum(T))")
    println("min: $(minimum(T))")

    # GLMakie.closeall()
    Jutul.plot_cell_data!(ax3d, g, T)
    display(GLMakie.Screen(), f3D)
    # plot_interactive(model, states)
    # return
    
end

##########################
# Example with SEI layer #
##########################

using Jutul, BattMo, GLMakie

name = "bolay"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)
config_kwargs = (info_level = 0, )

function hook(simulator,
              model,
              state0,
              forces,
              timesteps,
              cfg)
    # cfg[:max_timestep_cuts] = 1
    # cfg[:max_nonlinear_iterations] = 10
end

output = run_battery(inputparams;
                     hook = hook,
                     config_kwargs = config_kwargs,
                     extra_timing = false);

states = output[:states]

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
          yticklabelsize = 25
          )

scatterlines!(ax,
              t,
              E;
              linewidth = 4,
              markersize = 10,
              marker = :cross, 
              markercolor = :black,
              label = "Julia"
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
              markercolor = :black,
              label = "Julia"
              )

display(f)

seilength = [state[:NeAm][:normalizedSEIlength][end] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
          title     = "Length",
          xlabel    = "Time / s",
          ylabel    = "Length / ",
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25
          )

scatterlines!(ax,
              t,
              seilength;
              linewidth = 4,
              markersize = 10,
              marker = :cross, 
              markercolor = :black)

display(f)



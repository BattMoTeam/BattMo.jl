```@meta
EditURL = "../../../examples/beginner_tutorials/2_basic_plotting.jl"
```

A basic example

````@example 2_basic_plotting
using Jutul, BattMo, GLMakie

name = "p2d_40"
````

name = "p2d_40_jl_ud_func"
name = "p2d_40_no_cc"
name = "p2d_40_cccv"
name = "p2d_40_jl_chen2020"
name = "3d_demo_case"

````@example 2_basic_plotting
do_json = true

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
    inputparams = readBattMoJsonInputFile(fn)
    config_kwargs = (info_level = 0, )
    function hook(simulator,
                  model,
                  state0,
                  forces,
                  timesteps,
                  cfg)
    end
    output = run_battery(inputparams;
                         hook = hook,
                         config_kwargs = config_kwargs,
                         extra_timing = false);

    states = output[:states]

    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]

end

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


if !do_json
    scatterlines!(ax,
                  t,
                  Eref;
                  linewidth = 2,
                  marker = :cross,
                  markercolor = :black,
                  markersize = 1,
                  label = "Matlab")
    axislegend()
end


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

if !do_json
    scatterlines!(ax,
                  t,
                  Iref;
                  linewidth = 2,
                  marker = :cross,
                  markercolor = :black,
                  markersize = 1,
                  label = "Matlab")
    axislegend()
end

f
````

## Example on GitHub
If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_basic_plotting.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_basic_plotting.ipynb)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*





A basic example

```julia
using Jutul, BattMo, GLMakie

name = "p2d_40"
```


```
"p2d_40"
```


name = &quot;p2d_40_jl_ud_func&quot; name = &quot;p2d_40_no_cc&quot; name = &quot;p2d_40_cccv&quot; name = &quot;p2d_40_jl_chen2020&quot; name = &quot;3d_demo_case&quot;

```julia
do_json = false

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
    inputparams = readBattMoJsonInputFile(fn)
    config_kwargs = (info_level = 10, )
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

else

    fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", name, ".mat")
    inputparams = readBattMoMatlabInputFile(fn)
    inputparams.dict["use_state_ref"] = true
    config_kwargs = (info_level = 10,)

    function hook(simulator,
                  model,
                  state0,
                  forces,
                  timesteps,
                  cfg)

        names = [:Elyte,
                 :NeAm,
                 :PeCc,
                 :Control,
                 :NeCc,
                 :PeAm]

        for name in names
            cfg[:tolerances][name][:default] = 1e-8
        end

    end

    output = run_battery(inputparams;
                         hook = hook,
                         config_kwargs = config_kwargs,
                         max_step = nothing);
    states = output[:states]

    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]

    nsteps = size(states, 1)

    statesref = inputparams["states"]
    timeref   = t
    Eref      = [state["Control"]["E"] for state in statesref[1 : nsteps]]
    Iref      = [state["Control"]["I"] for state in statesref[1 : nsteps]]

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
```

![](oabsnuf.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_battery.jl), or as a [Jupyter Notebook](https://https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_battery.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._
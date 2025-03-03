### Getting started

We start by loading BattMo

```@example intro
using BattMo
```

BattMo uses a json input format. Json files can be easily read and modified. They are converted to dictionary structure

Let us choose the case
[p2d_40.json](https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json). We load it using the
function `readBattMoJsonInputFile`.

```@example intro
filename = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/p2d_40.json")
inputparams = readBattMoJsonInputFile(filename)
```

We run the simulation using the [run_battery](@ref) 

```@example intro
output = run_battery(inputparams)
nothing # hide
``` 
We can now plot the results

```@example intro
using GLMakie
states = output[:states]
t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, E)
ax = Axis(fig[1, 2], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t, I)
fig
```

see full example script here
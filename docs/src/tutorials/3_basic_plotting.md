```@meta
EditURL = "../../../examples/beginner_tutorials/3_basic_plotting.jl"
```

# Basic Plotting

In the previous tutorials we got an idea about how to run a simple simulation and about the structure of the simulation output.
In this tutorial we'll have a look into how we can retrieve the output quantities we want and how to plot them.

We'll run a simulation like we saw in the first tutorial, but now we also import the GLMakie package which we'll use for the plotting.

````@example 3_basic_plotting
using BattMo, GLMakie

file_name = "p2d_40_jl_chen2020.json"
file_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", file_name)

inputparams = readBattMoJsonInputFile(file_path)

output = run_battery(inputparams);
nothing #hide
````

Let's say we want to plot the cell current and cell voltage over time. First we'll retrieve these three quantities from the output.

````@example 3_basic_plotting
states = output[:states]

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
nothing # hide
````

Now we can use GLMakie to create a plot. Lets first plot the cell voltage.

````@example 3_basic_plotting
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
    )

f # hide
````

And the cell current.

````@example 3_basic_plotting
ax = Axis(f[1, 2],
            title     = "Current",
            xlabel    = "Time / s",
            ylabel    = "Current / V",
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
    )


f # hide
````

## Example on GitHub
If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/3_basic_plotting.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/3_basic_plotting.ipynb)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*


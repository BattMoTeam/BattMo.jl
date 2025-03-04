```@meta
EditURL = "../../../examples/beginner_tutorials/2_inspect_simulation_results.jl"
```

# How to inspect simulation results

We have seen how to simple it is to run a simulation using BattMo.
Now we'll have a look into how to inspect the results of a simulation.

We'll run a simulation like we saw in the previous tutorial

````@example 2_inspect_simulation_results
using BattMo

file_name = "p2d_40_jl_chen2020.json"
file_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", file_name)

inputparams = readBattMoJsonInputFile(file_path)

results = run_battery(inputparams);
nothing #hide
````

Now we'll have a look into what the results entail.

````@example 2_inspect_simulation_results
print(results)
````

So we can see

````@example 2_inspect_simulation_results
states = results[:states]
````

And we can see

````@example 2_inspect_simulation_results
t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]
````

## Example on GitHub
If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_inspect_simulation_results.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_inspect_simulation_results.ipynb)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*


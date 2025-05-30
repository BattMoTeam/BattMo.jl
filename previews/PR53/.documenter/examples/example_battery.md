


# An example using Matlab input {#An-example-using-Matlab-input}

## We prepare the input. {#We-prepare-the-input.}

```julia
using Jutul, BattMo, GLMakie
```


We load the matlab input file

```julia
name = "p2d_40"
fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", name, ".mat")
inputparams = load_matlab_battmo_input(fn)
```


We want to compare the solution obtained in julia with the solution computed in Matlab. We set the option to load the reference states computed in matlab, which are included in the matlab input file.

```julia
inputparams["use_state_ref"] = true
```


We prepare a hook that will be used by the simulator. In this hook, we modify the tolerance for the current collector. This is necessary because the very high conductivity of the current collector introduces round-off error **when** the current collectors are used in a P**2**D model. We should in fact use effective conductivities for the current collector for one-dimensional model.

```julia
function hook(simulator,
	model,
	state0,
	forces,
	timesteps,
	cfg)

	names = [:Elyte,
		:NeAm,
		:Control,
		:PeAm]

	if inputparams["model"]["include_current_collectors"]
		names = append!(names, [:PeCc, :NeCc])
	end

	for name in names
		cfg[:tolerances][name][:default] = 1e-8
	end

end
```


## We run the simulation and retrieve the output {#We-run-the-simulation-and-retrieve-the-output}

```julia
output = run_battery(inputparams;
	hook = hook,
	max_step = nothing);
states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

nsteps = size(states, 1)
```


```
Jutul: Simulating 1 hour, 9.505 seconds as 103 report steps
╭────────────────┬───────────┬───────────────┬──────────╮
│ Iteration type │  Avg/step │  Avg/ministep │    Total │
│                │ 103 steps │ 103 ministeps │ (wasted) │
├────────────────┼───────────┼───────────────┼──────────┤
│ Newton         │   2.42718 │       2.42718 │  250 (0) │
│ Linearization  │   3.42718 │       3.42718 │  353 (0) │
│ Linear solver  │   2.42718 │       2.42718 │  250 (0) │
│ Precond apply  │       0.0 │           0.0 │    0 (0) │
╰────────────────┴───────────┴───────────────┴──────────╯
╭───────────────┬─────────┬────────────┬─────────╮
│ Timing type   │    Each │   Relative │   Total │
│               │      ms │ Percentage │       s │
├───────────────┼─────────┼────────────┼─────────┤
│ Properties    │  0.2588 │     0.41 % │  0.0647 │
│ Equations     │ 19.5132 │    43.82 % │  6.8882 │
│ Assembly      │  5.7554 │    12.92 % │  2.0317 │
│ Linear solve  │  0.5094 │     0.81 % │  0.1274 │
│ Linear setup  │  0.0000 │     0.00 % │  0.0000 │
│ Precond apply │  0.0000 │     0.00 % │  0.0000 │
│ Update        │  3.2362 │     5.15 % │  0.8091 │
│ Convergence   │  6.0568 │    13.60 % │  2.1380 │
│ Input/Output  │  1.3825 │     0.91 % │  0.1424 │
│ Other         │ 14.0761 │    22.39 % │  3.5190 │
├───────────────┼─────────┼────────────┼─────────┤
│ Total         │ 62.8818 │   100.00 % │ 15.7204 │
╰───────────────┴─────────┴────────────┴─────────╯
```


## We retrieve the reference states computed in matlab. {#We-retrieve-the-reference-states-computed-in-matlab.}

```julia
statesref = inputparams["states"]
timeref   = t
Eref      = [state["Control"]["E"] for state in statesref[1:nsteps]]
Iref      = [state["Control"]["I"] for state in statesref[1:nsteps]]
```


## We plot the results and compare the two simulations {#We-plot-the-results-and-compare-the-two-simulations}

```julia
f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)


scatterlines!(ax,
	t,
	Eref;
	linewidth = 2,
	marker = :cross,
	markercolor = :black,
	markersize = 1,
	label = "Matlab")
axislegend()

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

scatterlines!(ax,
	t,
	Iref;
	linewidth = 2,
	marker = :cross,
	markercolor = :black,
	markersize = 1,
	label = "Matlab")
axislegend()
```


We observe a perfect match between the Matlab and Julia simulations.
![](metoyjs.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_battery.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_battery.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

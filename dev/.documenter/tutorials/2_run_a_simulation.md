


# How to run a simulation {#How-to-run-a-simulation}

BattMo simulations replicates the voltage-current response of a cell. To run a Battmo simulation, the basic workflow is:
- Set up cell parameters
  
- Set up a cycling protocol
  
- Select a model
  
- Prepare a simulation
  
- Run the simulation
  
- Inspect and visualize the outputs of the simulation
  

To start, we load BattMo (battery models and simulations) and GLMakie (plotting).

```julia
using BattMo, GLMakie
```


BattMo stores cell parameters, cycling protocols and settings in a user-friendly JSON format to facilitate reuse. For our example, we read the cell parameter set from a NMC811 vs Graphite-SiOx cell whose parameters were determined in the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). We also read an example cycling protocol for a simple Constant Current Discharge.

```julia
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
```


Next, we select the Lithium-Ion Battery Model with default model settings. A model can be thought as a mathematical implementation of the electrochemical and transport phenomena occuring in a real battery cell. The implementation consist of a system of partial differential equations and their corresponding parameters, constants and boundary conditions. The default Lithium-Ion Battery Model selected below corresponds to a basic P2D model, where neither current collectors nor thermal effects are considered.

```julia
model_setup = LithiumIonBattery()
```


```ansi
LithiumIonBattery("Setup object for a P2D lithium-ion model", {
    "RampUp" => "Sinusoidal"
    "Metadata" =>     {
        "Description" => "Default model settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects."
        "Title" => "P2D"
    }
    "TransportInSolid" => "FullDiffusion"
    "ModelFramework" => "P2D"
}, true)
```


Then we setup a Simulation by passing the model, cell parameters and a cycling protocol. A Simulation can be thought as a procedure to predict how the cell responds to the cycling protocol, by solving the equations in the model using the cell parameters passed. We first prepare the simulation:

```julia
sim = Simulation(model_setup, cell_parameters, cycling_protocol);
```


```ansi
✔️ Validation of CellParameters passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of CyclingProtocol passed: No issues found.
──────────────────────────────────────────────────
✔️ Validation of SimulationSettings passed: No issues found.
──────────────────────────────────────────────────
```


When the simulation is prepared, there are some validation checks happening in the background, which verify whether the cell parameters, cycling protocol and settings are sensible and complete to run a simulation. It is good practice to ensure that the Simulation has been properly configured by checking if has passed the validation procedure:

```julia
sim.is_valid
```


```ansi
true
```


Now we can run the simulation

```julia
output = solve(sim;)
```


```ansi
Jutul: Simulating 2 hours, 12 minutes as 163 report steps
╭────────────────┬───────────┬───────────────┬──────────╮
│[1m Iteration type [0m│[1m  Avg/step [0m│[1m  Avg/ministep [0m│[1m    Total [0m│
│[1m                [0m│[90m 146 steps [0m│[90m 146 ministeps [0m│[90m (wasted) [0m│
├────────────────┼───────────┼───────────────┼──────────┤
│[1m Newton         [0m│   2.32877 │       2.32877 │  340 (0) │
│[1m Linearization  [0m│   3.32877 │       3.32877 │  486 (0) │
│[1m Linear solver  [0m│   2.32877 │       2.32877 │  340 (0) │
│[1m Precond apply  [0m│       0.0 │           0.0 │    0 (0) │
╰────────────────┴───────────┴───────────────┴──────────╯
╭───────────────┬─────────┬────────────┬────────╮
│[1m Timing type   [0m│[1m    Each [0m│[1m   Relative [0m│[1m  Total [0m│
│[1m               [0m│[90m      ms [0m│[90m Percentage [0m│[90m      s [0m│
├───────────────┼─────────┼────────────┼────────┤
│[1m Properties    [0m│  0.0447 │     0.35 % │ 0.0152 │
│[1m Equations     [0m│  4.9869 │    55.37 % │ 2.4236 │
│[1m Assembly      [0m│  0.7143 │     7.93 % │ 0.3472 │
│[1m Linear solve  [0m│  0.2904 │     2.26 % │ 0.0987 │
│[1m Linear setup  [0m│  0.0000 │     0.00 % │ 0.0000 │
│[1m Precond apply [0m│  0.0000 │     0.00 % │ 0.0000 │
│[1m Update        [0m│  0.6246 │     4.85 % │ 0.2124 │
│[1m Convergence   [0m│  0.8866 │     9.84 % │ 0.4309 │
│[1m Input/Output  [0m│  0.1753 │     0.58 % │ 0.0256 │
│[1m Other         [0m│  2.4221 │    18.81 % │ 0.8235 │
├───────────────┼─────────┼────────────┼────────┤
│[1m Total         [0m│ 12.8737 │   100.00 % │ 4.3771 │
╰───────────────┴─────────┴────────────┴────────╯
```


The ouput is a NamedTuple storing the results of the simulation within multiple dictionaries. Let&#39;s plot the cell current and cell voltage over time and make a plot with the GLMakie package.

```julia
states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[1, 2], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f
```

![](ontwhkn.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_run_a_simulation.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_run_a_simulation.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

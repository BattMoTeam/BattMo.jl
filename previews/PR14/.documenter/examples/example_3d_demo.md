


# 3D battery example {#3D-battery-example}

```julia
using Jutul, BattMo, GLMakie
```


## Setup input parameters {#Setup-input-parameters}

```julia
name = "p2d_40_jl_chen2020"

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = readBattMoJsonInputFile(fn)

inputparams = mergeInputParams(inputparams_geometry, inputparams)
```


```
InputParams(Dict{String, Any}("include_current_collectors" => true, "use_thermal" => true, "Geometry" => Dict{String, Any}("height" => 0.02, "case" => "3D-demo", "Nh" => 10, "width" => 0.01, "faceArea" => 0.027, "Nw" => 10), "G" => Any[], "Separator" => Dict{String, Any}("density" => 946.0, "thickness" => 5.0e-5, "N" => 3, "bruggemanCoefficient" => 1.5, "thermalConductivity" => 0.334, "specificHeatCapacity" => 1692.0, "porosity" => 0.4), "Control" => Dict{String, Any}("numberOfCycles" => 10, "CRate" => 1.0, "dEdtLimit" => 0.0001, "initialControl" => "discharge", "DRate" => 1.0, "rampupTime" => 10.0, "dIdtLimit" => 0.0001, "controlPolicy" => "CCDischarge", "lowerCutoffVoltage" => 2.4, "upperCutoffVoltage" => 4.1…), "SOC" => 1.0, "Electrolyte" => Dict{String, Any}("ionicConductivity" => Dict{String, Any}("functionname" => "computeElectrolyteConductivity_Chen2020", "argumentlist" => Any["c"], "type" => "function"), "compnames" => Any["Li", "PF6"], "density" => 1200, "diffusionCoefficient" => Dict{String, Any}("functionname" => "computeDiffusionCoefficient_Chen2020", "argumentlist" => Any["c"], "type" => "function"), "initialConcentration" => 1000, "thermalConductivity" => 0.099, "specificHeatCapacity" => 1518.0, "bruggemanCoefficient" => 1.5, "species" => Dict{String, Any}("transferenceNumber" => 0.7406, "nominalConcentration" => 1000, "chargeNumber" => 1)), "Output" => Dict{String, Any}("variables" => Any["energy"]), "PositiveElectrode" => Dict{String, Any}("Coating" => Dict{String, Any}("thickness" => 8.0e-5, "N" => 3, "effectiveDensity" => 3500, "ActiveMaterial" => Dict{String, Any}("diffusionModelType" => "full", "density" => 4950.0, "massFraction" => 0.9, "Interface" => Dict{String, Any}("volumetricSurfaceArea" => 382183.9, "reactionRateConstant" => 3.545e-11, "chargeTransferCoefficient" => 0.5, "density" => 4950.0, "numberOfElectronsTransferred" => 1, "guestStoichiometry100" => 0.2661, "openCircuitPotential" => Dict{String, Any}("functionname" => "computeOCP_NMC811_Chen2020", "argumentlist" => Any["c", "cmax"], "type" => "function"), "guestStoichiometry0" => 0.9084, "saturationConcentration" => 51765.0, "activationEnergyOfReaction" => 17800.0…), "SolidDiffusion" => Dict{String, Any}("activationEnergyOfDiffusion" => 5000.0, "particleRadius" => 1.0e-6, "N" => 10, "referenceDiffusionCoefficient" => 1.0e-14), "thermalConductivity" => 2.1, "specificHeatCapacity" => 700.0, "electronicConductivity" => 100.0), "bruggemanCoefficient" => 1.5, "Binder" => Dict{String, Any}("density" => 1780.0, "massFraction" => 0.05, "thermalConductivity" => 0.165, "specificHeatCapacity" => 1400.0, "electronicConductivity" => 100.0), "ConductingAdditive" => Dict{String, Any}("density" => 1800.0, "massFraction" => 0.05, "thermalConductivity" => 0.5, "specificHeatCapacity" => 300.0, "electronicConductivity" => 100.0)), "CurrentCollector" => Dict{String, Any}("density" => 8960, "thickness" => 1.0e-5, "N" => 2, "tab" => Dict{String, Any}("height" => 0.001, "Nh" => 3, "width" => 0.004, "Nw" => 3), "electronicConductivity" => 5.96e7))…))
```


## Setup and run simulation {#Setup-and-run-simulation}

```julia
output = run_battery(inputparams);
```


```
Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:18:56[K
  Progress:  Solving step 2/77 (0.13% of time interval complete)[K
  Stats:     4 iterations in 27.71 s (6.93 s each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  12%|▌   |  ETA: 0:03:56[K
  Progress:  Solving step 9/77 (6.90% of time interval complete)[K
  Stats:     33 iterations in 28.21 s (854.97 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  14%|▋   |  ETA: 0:03:09[K
  Progress:  Solving step 11/77 (9.68% of time interval complete)[K
  Stats:     40 iterations in 28.34 s (708.42 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  18%|▊   |  ETA: 0:02:22[K
  Progress:  Solving step 14/77 (13.85% of time interval complete)[K
  Stats:     50 iterations in 28.50 s (569.93 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  21%|▉   |  ETA: 0:02:01[K
  Progress:  Solving step 16/77 (16.62% of time interval complete)[K
  Stats:     58 iterations in 28.62 s (493.53 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  23%|▉   |  ETA: 0:01:45[K
  Progress:  Solving step 18/77 (19.40% of time interval complete)[K
  Stats:     64 iterations in 28.73 s (448.86 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  27%|█▏  |  ETA: 0:01:26[K
  Progress:  Solving step 21/77 (23.57% of time interval complete)[K
  Stats:     73 iterations in 28.87 s (395.54 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  31%|█▎  |  ETA: 0:01:11[K
  Progress:  Solving step 24/77 (27.73% of time interval complete)[K
  Stats:     82 iterations in 29.02 s (353.89 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  35%|█▍  |  ETA: 0:01:00[K
  Progress:  Solving step 27/77 (31.90% of time interval complete)[K
  Stats:     91 iterations in 29.16 s (320.49 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  38%|█▌  |  ETA: 0:00:51[K
  Progress:  Solving step 30/77 (36.07% of time interval complete)[K
  Stats:     100 iterations in 29.32 s (293.19 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  42%|█▊  |  ETA: 0:00:44[K
  Progress:  Solving step 33/77 (40.23% of time interval complete)[K
  Stats:     109 iterations in 29.47 s (270.33 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  46%|█▉  |  ETA: 0:00:38[K
  Progress:  Solving step 36/77 (44.40% of time interval complete)[K
  Stats:     118 iterations in 29.61 s (250.96 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  50%|██  |  ETA: 0:00:32[K
  Progress:  Solving step 39/77 (48.57% of time interval complete)[K
  Stats:     127 iterations in 29.76 s (234.31 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  54%|██▏ |  ETA: 0:00:28[K
  Progress:  Solving step 42/77 (52.73% of time interval complete)[K
  Stats:     136 iterations in 29.90 s (219.86 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  58%|██▎ |  ETA: 0:00:24[K
  Progress:  Solving step 45/77 (56.90% of time interval complete)[K
  Stats:     145 iterations in 30.05 s (207.22 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  62%|██▌ |  ETA: 0:00:21[K
  Progress:  Solving step 48/77 (61.07% of time interval complete)[K
  Stats:     154 iterations in 30.19 s (196.04 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  65%|██▋ |  ETA: 0:00:17[K
  Progress:  Solving step 51/77 (65.23% of time interval complete)[K
  Stats:     163 iterations in 30.35 s (186.19 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  69%|██▊ |  ETA: 0:00:15[K
  Progress:  Solving step 54/77 (69.40% of time interval complete)[K
  Stats:     172 iterations in 30.50 s (177.31 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  73%|██▉ |  ETA: 0:00:12[K
  Progress:  Solving step 57/77 (73.57% of time interval complete)[K
  Stats:     181 iterations in 30.64 s (169.29 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  77%|███▏|  ETA: 0:00:10[K
  Progress:  Solving step 60/77 (77.73% of time interval complete)[K
  Stats:     190 iterations in 30.79 s (162.04 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  81%|███▎|  ETA: 0:00:08[K
  Progress:  Solving step 63/77 (81.90% of time interval complete)[K
  Stats:     199 iterations in 30.93 s (155.44 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  85%|███▍|  ETA: 0:00:06[K
  Progress:  Solving step 66/77 (86.07% of time interval complete)[K
  Stats:     208 iterations in 31.08 s (149.41 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  87%|███▌|  ETA: 0:00:05[K
  Progress:  Solving step 68/77 (88.85% of time interval complete)[K
  Stats:     215 iterations in 31.19 s (145.06 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  90%|███▋|  ETA: 0:00:04[K
  Progress:  Solving step 70/77 (91.62% of time interval complete)[K
  Stats:     223 iterations in 31.32 s (140.43 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  92%|███▊|  ETA: 0:00:03[K
  Progress:  Solving step 72/77 (94.40% of time interval complete)[K
  Stats:     231 iterations in 31.46 s (136.18 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  95%|███▊|  ETA: 0:00:02[K
  Progress:  Solving step 74/77 (97.18% of time interval complete)[K
  Stats:     239 iterations in 31.59 s (132.18 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  97%|███▉|  ETA: 0:00:01[K
  Progress:  Solving step 76/77 (99.96% of time interval complete)[K
  Stats:     246 iterations in 31.70 s (128.87 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:35[K
  Progress:  Solved step 77/77[K
  Stats:     252 iterations in 31.80 s (126.19 ms each)[K
╭────────────────┬──────────┬──────────────┬──────────╮
│ Iteration type │ Avg/step │ Avg/ministep │    Total │
│                │ 77 steps │ 77 ministeps │ (wasted) │
├────────────────┼──────────┼──────────────┼──────────┤
│ Newton         │  3.27273 │      3.27273 │  252 (0) │
│ Linearization  │  4.27273 │      4.27273 │  329 (0) │
│ Linear solver  │  3.27273 │      3.27273 │  252 (0) │
│ Precond apply  │      0.0 │          0.0 │    0 (0) │
╰────────────────┴──────────┴──────────────┴──────────╯
╭───────────────┬──────────┬────────────┬─────────╮
│ Timing type   │     Each │   Relative │   Total │
│               │       ms │ Percentage │       s │
├───────────────┼──────────┼────────────┼─────────┤
│ Properties    │   0.2358 │     0.19 % │  0.0594 │
│ Equations     │  25.3689 │    26.25 % │  8.3464 │
│ Assembly      │  14.6338 │    15.14 % │  4.8145 │
│ Linear solve  │  14.6487 │    11.61 % │  3.6915 │
│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │
│ Precond apply │   0.0000 │     0.00 % │  0.0000 │
│ Update        │   6.2780 │     4.98 % │  1.5821 │
│ Convergence   │  21.1774 │    21.91 % │  6.9674 │
│ Input/Output  │   4.5853 │     1.11 % │  0.3531 │
│ Other         │  23.7484 │    18.82 % │  5.9846 │
├───────────────┼──────────┼────────────┼─────────┤
│ Total         │ 126.1860 │   100.00 % │ 31.7989 │
╰───────────────┴──────────┴────────────┴─────────╯
```


## Plot discharge curve {#Plot-discharge-curve}

```julia
states = output[:states]
model  = output[:extra][:model]

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
f
```

![](ecyfvxa.jpeg)

## Plot potential on grid at last time step {#Plot-potential-on-grid-at-last-time-step}

```julia
state = states[10]

function plot_potential(am, cc, label)
    f3D = Figure(size = (600, 650))
    ax3d = Axis3(f3D[1, 1];
                 title = "Potential in $label electrode (coating and active material)")

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
    return f3D
end
```


```
plot_potential (generic function with 1 method)
```


## 

```julia
plot_potential(:PeAm, :PeCc, "positive")
```

![](oyggnbm.jpeg)

##  {#-2}

```julia
plot_potential(:NeAm, :NeCc, "negative")
```

![](mxrhhyu.jpeg)

## Plot surface concentration on grid at last time step {#Plot-surface-concentration-on-grid-at-last-time-step}

```julia
function plot_surface_concentration(component, label)
    f3D = Figure(size = (600, 650))
    ax3d = Axis3(f3D[1, 1];
                 title = "Surface concentration in $label electrode")

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
    return f3D
end
```


```
plot_surface_concentration (generic function with 1 method)
```


## Positive

```julia
plot_surface_concentration(:PeAm, "positive")
```

![](giichpf.jpeg)

## Negative

```julia
plot_surface_concentration(:NeAm, "negative")
```

![](yywhast.jpeg)

## Plot electrolyte concentration and potential on grid at last time step {#Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step}

```julia
function plot_elyte(var, label)
    f3D = Figure(size = (600, 650))
    ax3d = Axis3(f3D[1, 1]; title = "$label in electrolyte")

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
                            label = "$label")
    display(GLMakie.Screen(), f3D)
    f3D
end
```


```
plot_elyte (generic function with 1 method)
```


##  {#-3}

```julia
plot_elyte(:C, "concentration")
```

![](rmppdee.jpeg)

##  {#-4}

```julia
plot_elyte(:Phi, "potential")
```

![](dwelsca.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

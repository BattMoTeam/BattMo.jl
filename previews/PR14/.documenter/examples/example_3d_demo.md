


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
Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:17:49[K
  Progress:  Solving step 2/77 (0.13% of time interval complete)[K
  Stats:     4 iterations in 26.09 s (6.52 s each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  12%|▌   |  ETA: 0:03:42[K
  Progress:  Solving step 9/77 (6.90% of time interval complete)[K
  Stats:     33 iterations in 26.57 s (805.06 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  14%|▋   |  ETA: 0:02:57[K
  Progress:  Solving step 11/77 (9.68% of time interval complete)[K
  Stats:     40 iterations in 26.67 s (666.75 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  18%|▊   |  ETA: 0:02:14[K
  Progress:  Solving step 14/77 (13.85% of time interval complete)[K
  Stats:     50 iterations in 26.81 s (536.29 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  21%|▉   |  ETA: 0:01:54[K
  Progress:  Solving step 16/77 (16.62% of time interval complete)[K
  Stats:     58 iterations in 26.93 s (464.31 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  24%|█   |  ETA: 0:01:32[K
  Progress:  Solving step 19/77 (20.79% of time interval complete)[K
  Stats:     67 iterations in 27.06 s (403.95 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  28%|█▏  |  ETA: 0:01:15[K
  Progress:  Solving step 22/77 (24.96% of time interval complete)[K
  Stats:     76 iterations in 27.20 s (357.86 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  32%|█▎  |  ETA: 0:01:03[K
  Progress:  Solving step 25/77 (29.12% of time interval complete)[K
  Stats:     85 iterations in 27.35 s (321.77 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  36%|█▍  |  ETA: 0:00:53[K
  Progress:  Solving step 28/77 (33.29% of time interval complete)[K
  Stats:     94 iterations in 27.48 s (292.38 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  40%|█▋  |  ETA: 0:00:46[K
  Progress:  Solving step 31/77 (37.46% of time interval complete)[K
  Stats:     103 iterations in 27.62 s (268.12 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  44%|█▊  |  ETA: 0:00:39[K
  Progress:  Solving step 34/77 (41.62% of time interval complete)[K
  Stats:     112 iterations in 27.75 s (247.77 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  47%|█▉  |  ETA: 0:00:34[K
  Progress:  Solving step 37/77 (45.79% of time interval complete)[K
  Stats:     121 iterations in 27.88 s (230.44 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  51%|██  |  ETA: 0:00:29[K
  Progress:  Solving step 40/77 (49.96% of time interval complete)[K
  Stats:     130 iterations in 28.02 s (215.51 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  55%|██▎ |  ETA: 0:00:25[K
  Progress:  Solving step 43/77 (54.12% of time interval complete)[K
  Stats:     139 iterations in 28.15 s (202.51 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  59%|██▍ |  ETA: 0:00:21[K
  Progress:  Solving step 46/77 (58.29% of time interval complete)[K
  Stats:     148 iterations in 28.28 s (191.11 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  62%|██▌ |  ETA: 0:00:19[K
  Progress:  Solving step 48/77 (61.07% of time interval complete)[K
  Stats:     154 iterations in 28.39 s (184.36 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  65%|██▋ |  ETA: 0:00:16[K
  Progress:  Solving step 51/77 (65.23% of time interval complete)[K
  Stats:     163 iterations in 28.52 s (174.99 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  69%|██▊ |  ETA: 0:00:14[K
  Progress:  Solving step 54/77 (69.40% of time interval complete)[K
  Stats:     172 iterations in 28.66 s (166.60 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  73%|██▉ |  ETA: 0:00:12[K
  Progress:  Solving step 57/77 (73.57% of time interval complete)[K
  Stats:     181 iterations in 28.79 s (159.06 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  77%|███▏|  ETA: 0:00:09[K
  Progress:  Solving step 60/77 (77.73% of time interval complete)[K
  Stats:     190 iterations in 28.92 s (152.22 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  81%|███▎|  ETA: 0:00:07[K
  Progress:  Solving step 63/77 (81.90% of time interval complete)[K
  Stats:     199 iterations in 29.05 s (146.00 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  85%|███▍|  ETA: 0:00:06[K
  Progress:  Solving step 66/77 (86.07% of time interval complete)[K
  Stats:     208 iterations in 29.19 s (140.33 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  87%|███▌|  ETA: 0:00:05[K
  Progress:  Solving step 68/77 (88.85% of time interval complete)[K
  Stats:     215 iterations in 29.29 s (136.23 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  90%|███▋|  ETA: 0:00:04[K
  Progress:  Solving step 70/77 (91.62% of time interval complete)[K
  Stats:     223 iterations in 29.42 s (131.94 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  92%|███▊|  ETA: 0:00:03[K
  Progress:  Solving step 72/77 (94.40% of time interval complete)[K
  Stats:     231 iterations in 29.54 s (127.88 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  95%|███▊|  ETA: 0:00:02[K
  Progress:  Solving step 74/77 (97.18% of time interval complete)[K
  Stats:     239 iterations in 29.66 s (124.09 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  97%|███▉|  ETA: 0:00:01[K
  Progress:  Solving step 76/77 (99.96% of time interval complete)[K
  Stats:     246 iterations in 29.76 s (120.97 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:32[K
  Progress:  Solved step 77/77[K
  Stats:     252 iterations in 29.85 s (118.44 ms each)[K
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
│ Properties    │   0.2075 │     0.18 % │  0.0523 │
│ Equations     │  25.1867 │    27.76 % │  8.2864 │
│ Assembly      │  13.9548 │    15.38 % │  4.5911 │
│ Linear solve  │  13.7498 │    11.61 % │  3.4650 │
│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │
│ Precond apply │   0.0000 │     0.00 % │  0.0000 │
│ Update        │   5.4308 │     4.59 % │  1.3685 │
│ Convergence   │  20.0807 │    22.13 % │  6.6066 │
│ Input/Output  │   4.1770 │     1.08 % │  0.3216 │
│ Other         │  20.4615 │    17.28 % │  5.1563 │
├───────────────┼──────────┼────────────┼─────────┤
│ Total         │ 118.4438 │   100.00 % │ 29.8478 │
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

![](cebxjct.jpeg)

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

![](pdmemzs.jpeg)

##  {#-2}

```julia
plot_potential(:NeAm, :NeCc, "negative")
```

![](ztcprom.jpeg)

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

![](ejwbkhh.jpeg)

## Negative

```julia
plot_surface_concentration(:NeAm, "negative")
```

![](sphwkye.jpeg)

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

![](zslbgkp.jpeg)

##  {#-4}

```julia
plot_elyte(:Phi, "potential")
```

![](onfumix.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl), or as a [Jupyter Notebook](https://https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._




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
Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:17:14[K
  Progress:  Solving step 2/77 (0.13% of time interval complete)[K
  Stats:     4 iterations in 25.21 s (6.30 s each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  13%|▌   |  ETA: 0:03:11[K
  Progress:  Solving step 10/77 (8.29% of time interval complete)[K
  Stats:     37 iterations in 25.71 s (694.98 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  18%|▊   |  ETA: 0:02:09[K
  Progress:  Solving step 14/77 (13.85% of time interval complete)[K
  Stats:     50 iterations in 25.92 s (518.34 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  21%|▉   |  ETA: 0:01:50[K
  Progress:  Solving step 16/77 (16.62% of time interval complete)[K
  Stats:     58 iterations in 26.03 s (448.82 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  24%|█   |  ETA: 0:01:29[K
  Progress:  Solving step 19/77 (20.79% of time interval complete)[K
  Stats:     67 iterations in 26.16 s (390.45 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  28%|█▏  |  ETA: 0:01:13[K
  Progress:  Solving step 22/77 (24.96% of time interval complete)[K
  Stats:     76 iterations in 26.29 s (345.92 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  32%|█▎  |  ETA: 0:01:01[K
  Progress:  Solving step 25/77 (29.12% of time interval complete)[K
  Stats:     85 iterations in 26.42 s (310.85 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  36%|█▍  |  ETA: 0:00:52[K
  Progress:  Solving step 28/77 (33.29% of time interval complete)[K
  Stats:     94 iterations in 26.55 s (282.46 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  40%|█▋  |  ETA: 0:00:44[K
  Progress:  Solving step 31/77 (37.46% of time interval complete)[K
  Stats:     103 iterations in 26.68 s (259.05 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  44%|█▊  |  ETA: 0:00:38[K
  Progress:  Solving step 34/77 (41.62% of time interval complete)[K
  Stats:     112 iterations in 26.83 s (239.51 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  47%|█▉  |  ETA: 0:00:33[K
  Progress:  Solving step 37/77 (45.79% of time interval complete)[K
  Stats:     121 iterations in 26.95 s (222.70 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  51%|██  |  ETA: 0:00:28[K
  Progress:  Solving step 40/77 (49.96% of time interval complete)[K
  Stats:     130 iterations in 27.07 s (208.21 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  55%|██▎ |  ETA: 0:00:24[K
  Progress:  Solving step 43/77 (54.12% of time interval complete)[K
  Stats:     139 iterations in 27.20 s (195.66 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  59%|██▍ |  ETA: 0:00:21[K
  Progress:  Solving step 46/77 (58.29% of time interval complete)[K
  Stats:     148 iterations in 27.33 s (184.65 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  63%|██▌ |  ETA: 0:00:18[K
  Progress:  Solving step 49/77 (62.46% of time interval complete)[K
  Stats:     157 iterations in 27.46 s (174.89 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  67%|██▋ |  ETA: 0:00:15[K
  Progress:  Solving step 52/77 (66.62% of time interval complete)[K
  Stats:     166 iterations in 27.59 s (166.21 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  71%|██▉ |  ETA: 0:00:13[K
  Progress:  Solving step 55/77 (70.79% of time interval complete)[K
  Stats:     175 iterations in 27.72 s (158.39 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  74%|███ |  ETA: 0:00:10[K
  Progress:  Solving step 58/77 (74.96% of time interval complete)[K
  Stats:     184 iterations in 27.85 s (151.38 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  78%|███▏|  ETA: 0:00:08[K
  Progress:  Solving step 61/77 (79.12% of time interval complete)[K
  Stats:     193 iterations in 27.98 s (144.96 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  82%|███▎|  ETA: 0:00:07[K
  Progress:  Solving step 64/77 (83.29% of time interval complete)[K
  Stats:     202 iterations in 28.10 s (139.10 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  86%|███▍|  ETA: 0:00:05[K
  Progress:  Solving step 67/77 (87.46% of time interval complete)[K
  Stats:     211 iterations in 28.22 s (133.75 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  88%|███▌|  ETA: 0:00:04[K
  Progress:  Solving step 69/77 (90.23% of time interval complete)[K
  Stats:     219 iterations in 28.33 s (129.35 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  91%|███▋|  ETA: 0:00:03[K
  Progress:  Solving step 71/77 (93.01% of time interval complete)[K
  Stats:     227 iterations in 28.43 s (125.26 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  94%|███▊|  ETA: 0:00:02[K
  Progress:  Solving step 73/77 (95.79% of time interval complete)[K
  Stats:     235 iterations in 28.54 s (121.45 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  97%|███▉|  ETA: 0:00:01[K
  Progress:  Solving step 76/77 (99.96% of time interval complete)[K
  Stats:     246 iterations in 28.69 s (116.62 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:31[K
  Progress:  Solved step 77/77[K
  Stats:     252 iterations in 28.77 s (114.16 ms each)[K
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
│ Properties    │   0.2157 │     0.19 % │  0.0544 │
│ Equations     │  23.1338 │    26.46 % │  7.6110 │
│ Assembly      │  13.3662 │    15.29 % │  4.3975 │
│ Linear solve  │  12.9230 │    11.32 % │  3.2566 │
│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │
│ Precond apply │   0.0000 │     0.00 % │  0.0000 │
│ Update        │   5.7782 │     5.06 % │  1.4561 │
│ Convergence   │  19.6375 │    22.46 % │  6.4607 │
│ Input/Output  │   4.5148 │     1.21 % │  0.3476 │
│ Other         │  20.5764 │    18.02 % │  5.1853 │
├───────────────┼──────────┼────────────┼─────────┤
│ Total         │ 114.1635 │   100.00 % │ 28.7692 │
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

![](yiqxvse.jpeg)

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

![](mzoiezz.jpeg)

##  {#-2}

```julia
plot_potential(:NeAm, :NeCc, "negative")
```

![](anvpfwd.jpeg)

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

![](cifofbs.jpeg)

## Negative

```julia
plot_surface_concentration(:NeAm, "negative")
```

![](jfyzhgz.jpeg)

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

![](pxxjevc.jpeg)

##  {#-4}

```julia
plot_elyte(:Phi, "potential")
```

![](taxizue.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

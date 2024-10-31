


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
Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:17:22[K
  Progress:  Solving step 2/77 (0.13% of time interval complete)[K
  Stats:     4 iterations in 25.38 s (6.35 s each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  15%|▋   |  ETA: 0:02:37[K
  Progress:  Solving step 12/77 (11.07% of time interval complete)[K
  Stats:     43 iterations in 25.98 s (604.13 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  26%|█   |  ETA: 0:01:24[K
  Progress:  Solving step 20/77 (22.18% of time interval complete)[K
  Stats:     70 iterations in 26.38 s (376.92 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  29%|█▏  |  ETA: 0:01:10[K
  Progress:  Solving step 23/77 (26.35% of time interval complete)[K
  Stats:     79 iterations in 26.52 s (335.64 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  33%|█▍  |  ETA: 0:00:58[K
  Progress:  Solving step 26/77 (30.51% of time interval complete)[K
  Stats:     88 iterations in 26.65 s (302.79 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  37%|█▌  |  ETA: 0:00:50[K
  Progress:  Solving step 29/77 (34.68% of time interval complete)[K
  Stats:     97 iterations in 26.77 s (276.02 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  41%|█▋  |  ETA: 0:00:42[K
  Progress:  Solving step 32/77 (38.85% of time interval complete)[K
  Stats:     106 iterations in 26.91 s (253.84 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  45%|█▊  |  ETA: 0:00:36[K
  Progress:  Solving step 35/77 (43.01% of time interval complete)[K
  Stats:     115 iterations in 27.05 s (235.24 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  49%|██  |  ETA: 0:00:31[K
  Progress:  Solving step 38/77 (47.18% of time interval complete)[K
  Stats:     124 iterations in 27.18 s (219.21 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  53%|██▏ |  ETA: 0:00:27[K
  Progress:  Solving step 41/77 (51.35% of time interval complete)[K
  Stats:     133 iterations in 27.31 s (205.36 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  56%|██▎ |  ETA: 0:00:23[K
  Progress:  Solving step 44/77 (55.51% of time interval complete)[K
  Stats:     142 iterations in 27.44 s (193.27 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  60%|██▍ |  ETA: 0:00:20[K
  Progress:  Solving step 47/77 (59.68% of time interval complete)[K
  Stats:     151 iterations in 27.57 s (182.61 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  64%|██▋ |  ETA: 0:00:17[K
  Progress:  Solving step 50/77 (63.85% of time interval complete)[K
  Stats:     160 iterations in 27.71 s (173.16 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  68%|██▊ |  ETA: 0:00:14[K
  Progress:  Solving step 53/77 (68.01% of time interval complete)[K
  Stats:     169 iterations in 27.83 s (164.69 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  72%|██▉ |  ETA: 0:00:12[K
  Progress:  Solving step 56/77 (72.18% of time interval complete)[K
  Stats:     178 iterations in 27.96 s (157.10 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  76%|███ |  ETA: 0:00:10[K
  Progress:  Solving step 59/77 (76.35% of time interval complete)[K
  Stats:     187 iterations in 28.11 s (150.33 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  79%|███▏|  ETA: 0:00:08[K
  Progress:  Solving step 62/77 (80.51% of time interval complete)[K
  Stats:     196 iterations in 28.24 s (144.09 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  83%|███▍|  ETA: 0:00:06[K
  Progress:  Solving step 65/77 (84.68% of time interval complete)[K
  Stats:     205 iterations in 28.37 s (138.39 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  87%|███▌|  ETA: 0:00:05[K
  Progress:  Solving step 68/77 (88.85% of time interval complete)[K
  Stats:     215 iterations in 28.51 s (132.62 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  90%|███▋|  ETA: 0:00:04[K
  Progress:  Solving step 70/77 (91.62% of time interval complete)[K
  Stats:     223 iterations in 28.63 s (128.37 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  92%|███▊|  ETA: 0:00:03[K
  Progress:  Solving step 72/77 (94.40% of time interval complete)[K
  Stats:     231 iterations in 28.74 s (124.41 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  95%|███▊|  ETA: 0:00:02[K
  Progress:  Solving step 74/77 (97.18% of time interval complete)[K
  Stats:     239 iterations in 28.85 s (120.72 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps  99%|████|  ETA: 0:00:00[K
  Progress:  Solving step 77/77 (100.00% of time interval complete)[K
  Stats:     250 iterations in 29.01 s (116.03 ms each)[K[A[A

[K[A[K[ASimulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:32[K
  Progress:  Solved step 77/77[K
  Stats:     252 iterations in 29.04 s (115.23 ms each)[K
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
│ Properties    │   0.2025 │     0.18 % │  0.0510 │
│ Equations     │  24.2977 │    27.53 % │  7.9939 │
│ Assembly      │  13.3871 │    15.17 % │  4.4043 │
│ Linear solve  │  13.3711 │    11.60 % │  3.3695 │
│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │
│ Precond apply │   0.0000 │     0.00 % │  0.0000 │
│ Update        │   5.4329 │     4.72 % │  1.3691 │
│ Convergence   │  19.6021 │    22.21 % │  6.4491 │
│ Input/Output  │   4.1206 │     1.09 % │  0.3173 │
│ Other         │  20.1696 │    17.50 % │  5.0827 │
├───────────────┼──────────┼────────────┼─────────┤
│ Total         │ 115.2263 │   100.00 % │ 29.0370 │
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

![](woysaos.jpeg)

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

![](jcrezho.jpeg)

##  {#-2}

```julia
plot_potential(:NeAm, :NeCc, "negative")
```

![](osybtwi.jpeg)

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

![](rxzxpeq.jpeg)

## Negative

```julia
plot_surface_concentration(:NeAm, "negative")
```

![](jlkumwv.jpeg)

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

![](ovrierr.jpeg)

##  {#-4}

```julia
plot_elyte(:Phi, "potential")
```

![](nkcyjic.jpeg)

## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

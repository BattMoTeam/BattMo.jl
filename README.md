[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://battmoteam.github.io/BattMo.jl/dev/)
[![Build Status](https://github.com/battmoteam/BattMo.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/battmoteam/BattMo.jl/actions/workflows/CI.yml?query=branch%3Amain)

# BattMo.jl is a framework for continuum modelling of lithium-ion batteries written in Julia
> [!TIP]
> Please see the docs for more details, tutorials and examples: https://battmoteam.github.io/BattMo.jl/dev/



The Battery Modelling Toolbox (**BattMo**) is a resource for continuum modelling of electrochemical devices in MATLAB. The initial development features a pseudo X-dimensional (PXD) framework for the Doyle-Fuller-Newman model of lithium-ion battery cells. This is currently a early release that implements a subset of features from the [MATLAB version of BattMo](https://github.com/BattMoTeam/BattMo) with improved numerical performance. **BattMo.jl** is based on [Jutul.jl](https://github.com/sintefmath/Jutul.jl) and uses finite-volume discretizations and automatic differentiation to simulate models in 1D, 2D and 3D.

The current implementation has two options for setting up simulation cases:

- You can read in input data prepared in the MATLAB version of BattMo (general 3D grids)
- Or you can use the common BattMo JSON format to run cases

<img src="docs/src/assets/battmologo_text.png" style="margin-left: 5cm" width="300px">

## Installation

This package is registered in the General Julia registry. To add it to your Julia environment, open Julia and run

```julia
using Pkg; Pkg.add("BattMo")
```

### Getting started

For an example of usage, you can add the GLMakie plotting package:

```julia
using Pkg
Pkg.add("GLMakie")
```

You can then run the following to simulate the predefined `p2d_40` case:

```julia
using BattMo
# Simulate case
filename = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/p2d_40.json")
# Read input from json file
inputparams = readBattMoJsonInputFile(filename)
# run simulation from given input
output = run_battery(inputparams);
# Plot result
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
display(fig)
```

This should produce the following plot:
![Discharge curve](docs/src/assets/discharge.png)

### 3D simulation example

This example uses plotting from Jutul, so we need to add that package to our environment.

```julia
using Pkg
Pkg.add("Jutul")
```

Run a 3D model and plot the results in an interactive viewer.

```julia
using BattMo
# Simulate case
states, reports, extra, exported = run_battery("3d_demo_case");
# Parts of the battery overlap in physical space - shift them a bit and plot
# with Jutul's interactive GLMakie plotting viewer.
using GLMakie
using Jutul
dx = [0.02 0 0]
shift = Dict()
shift[:NAM] = dx
shift[:PAM] = dx
shift[:CC] = dx
shift[:PP] = dx
plot_multimodel_interactive(extra[:model], states, shift = shift, colormap = :curl)
```

![3D plot](docs/src/assets/3d_plot.png)

## Acknowledgements

BattMo has received funding from the European Union’s Horizon 2020 innovation program under grant agreement numbers:

- 875527 HYDRA
- 957189 BIG-MAP
- 101104013 BATMAX
- 101103997 DigiBatt

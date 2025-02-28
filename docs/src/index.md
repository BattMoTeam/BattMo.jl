````@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: BattMo.jl
  text: Fast open-source battery simulation
  image:
    src: battmologo_stacked.png
    alt: BattMo
  tagline: 1D, 2D and 3D open-source P2D/PXD Lithium-Ion battery simulation
  actions:
    - theme: brand
      text: Getting started
      link: /man/intro
    - theme: alt
      text: BattMo Web App
      link: https://app.batterymodel.com/
    - theme: alt
      text: Github
      link: https://github.com/sintefmath/BattMo.jl
    - theme: alt
      text: Simulate a battery
      link: /examples/example_cycle
    - theme: alt
      text: About
      link: https://batterymodel.com/

features:
  - icon: 🔋
    title: Accurate and open
    details: Validated on standard benchmarks. Automatic differentiation and Julia syntax means that the code is easy to read and edit. Based on proven computational core for other multiphysics domains.
    link: /examples

  - icon: ⚡
    title: Fast and flexible
    details: Written in Julia, simulate with scripting syntax without sacrificing performance. Extensible with new features.
    link: /man/advanced

  - icon: 🧱
    title: 1D, 2D and 3D
    details: One code handles both 1D models and complex 3D grids, with support for high-performance linear solvers for bigger models.
    link: /examples

  - icon: 📈
    title: Ready for optimization and calibration
    details: Automatic differentiation allows for fast gradient-based optimization and parameter/model matching
    link: /examples
---
````

The Battery Modelling Toolbox (**BattMo**) is a resource for continuum modelling of electrochemical devices in MATLAB. The code features a pseudo X-dimensional (PXD) framework for the Doyle-Fuller-Newman model of lithium-ion battery cells. The code implements a subset of features from the [MATLAB version of BattMo](https://github.com/BattMoTeam/BattMo) with improved numerical performance. **BattMo.jl** is based on [Jutul.jl](https://github.com/sintefmath/Jutul.jl) and uses finite-volume discretizations and automatic differentiation to simulate models in 1D, 2D and 3D.

The current implementation has many options for setting up simulation cases:

- Set up 1D, 2D and 3D grids using scripting syntax
- Templates for different types of battery chemistry parameters in JSON format
- Support for a variety of open formats
- Read in input data prepared in the MATLAB version of BattMo (coin-cell, jellyroll, pouch)
- Make use of common BattMo JSON format to run cases


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

```@example
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
fig
```

## Get involved

The code is open source [on GitHub](https://github.com/BattmoTeam/BattMo.jl). Pull requests, comments or issues are welcome!

## Acknowledgements

BattMo has received funding from the European Union’s Horizon 2020 innovation program under grant agreement numbers:

- 875527 HYDRA
- 957189 BIG-MAP
- 101104013 BATMAX
- 101103997 DigiBatt

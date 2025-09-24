---
title: "BattMo.jl: A Julia package for battery cell modeling"
tags:
  - Julia
  - battery modeling
authors:
  - name: Simon Clark
    orcid: 0000-0002-8758-6109
    affiliation: 1
  - name: Xavier Raynaud
    orcid: 0000-0002-4100-3035
    affiliation: 2
  - name: Halvor Møll Nilsen
    orcid: 0000-0002-2153-0962
    affiliation: 2
  - name: August Johansson
    orcid: 0000-0001-6950-6016
    affiliation: 2
  - name: Eibar Flores
    orcid: 0000-0003-2954-1233
  - name: Lorena Hendrix
    orcid: 0009-0006-9621-6122
    affiliation: 1
  - name: Francesca Watson
    orcid: 0000-0002-4391-4166
    affiliation: 2
  - name: Sridevi Krishnamurthi
    orcid: 0009-0006-0805-6713
    affiliation: 1
  - name: Olav Møyner
    orcid: 0000-0001-9993-3879
    affiliation: 2
affiliations:
 - name: SINTEF Industry, Dept. of Sustainable Energy Technology, Norway
   index: 1
 - name: SINTEF Digital, Dept. of Mathematics and Cybernetics, Norway
   index: 2
date: 4 February 2025
bibliography: paper.bib
---
<!-- To compile this file, after installing docker, from this directory, run : docker run --rm --volume $PWD:/data --user $(id -u):$(id -g) --env JOURNAL=joss openjournals/inara  -->
# Summary
This paper introduces BattMo.jl, the Battery Modelling Toolbox, an open-source Julia framework for continuum-scale simulation of electrochemical cells. Using a finite-volume approach, BattMo.jl supports both reduced-order pseudo-2-dimensional (P2D) models and fully three-dimensional (3D) simulations of realistic geometries such as cylindrical and pouch cells. The toolbox combines high-performance solvers, built-in libraries of battery designs and cycling protocols, and an intuitive programmatic and graphical interface. It further includes an adjoint-based optimization framework for parameter estimation and model calibration, enabling close integration of modelling with experimental workflows. The [BattMoTeam](https://github.com/BattMoTeam) collaborates closely with the [SINTEF Battery Lab](https://www.sintef.no/en/all-laboratories/sintef-battery-lab/), gaining valuable input from experienced battery researchers and helping to bridge the gap between academic modelling and industrial innovation.


# Statement of need
New high-performance battery designs are essential for achieving the goals of the electric energy transition. To reduce costly prototyping and accelerate innovation, both industry and academia increasingly rely on rigorous digital workflows that complement experimental research and provide deeper insights into battery behavior.

Recently, a variety of
open-source battery modelling codes have been released including PyBaMM [@sulzer2021python], cideMOD [@CiriaAylagas2022], LIONSIMBA [@torchio2016lionsimba], PETLion [@Berliner_2021], and MPET, among others. These open-source modelling frameworks help the battery community reduce the cost of model development and help ensure the
validity and the reproducibility of findings. Yet there remains a clear need for tools that (i) address both Li-ion and post-Li-ion chemistries, (ii) support full 3D cell simulations, and (iii) combine computational efficiency with broad accessibility.

BattMo.jl responds to this need by putting effort into creating a flexible model architecture, providing a framework for 3D simulations together with a library of standard battery geometries, offering very short runtimes (e.g., ~400 ms for a standard P2D discharge), and by laying an emphasis on usability and accesibility through its intuitive API and [graphical interface](https://app.batterymodel.com/). Furthermore, BattMo has an in-house API for adjoint-based optimization, allowing robust parameter calibration and design optimization.

# Architecture

The Doyle-Fuller-Newman (DFN) [@Doyle1993ModelingCell] approach is used as a base model. On top of that the user has the option to include degradation mechanisms such as SEI layer growth,


The solver in BattMo uses automatic differentiation and support adjoint computation. We can therefore computute the
derivative of objective functions with respect to all parameters in a very efficient way. Gradient-based optimization
routine can be used to compute parameters from experimental data by minimizing the difference between observed and
predicted results.


The simulation input parameters, including the cell parameters cycling protocol parameters, and simulation related settings, are specified through json schemas. In this respect, we follow the guidelines of the Battery Interface Ontology (BattINFO) to support semantic interoperability in accordance with the FAIR principles. 

# Convenient Functionalities

- BattINFO- and EMMO-compliant input formats for semantic interoperability
- Automatic validation of model instances, parameters, and settings to prevent unclear errors.
- Guidance for parameter set development, including clear definitions of parameters and settings.
- Convenient tools for inspecting, printing, and plotting cell information and simulation results.
- Headless user interface designed for digital twin integration and web API applications.

# Examples

A simple P2D constant current constant voltage simulation using cell parameters from Chen at al. [@chen2020].

```Julia
using BattMo, GLMakie

# Load default cell parameters and cycling protocol
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")

# Setup a LithiumIonBattery model
model = LithiumIonBattery()

# Setup the Simulation object
sim = Simulation(model, cell_parameters, cycling_protocol);

# Solve the simulation
output = solve(sim)

# Easily plot some results
plot_dashboard(output; plot_type = "contour")

```

A P4D constant current discharge simulation of a cylindrical cell using cell parameters from Chen at al. [@chen2020].

```Julia
using BattMo, GLMakie

# Load cell parameters and cycling protocol
cell_parameters = load_cell_parameters(; from_default_set = "Chen2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

# We want to setup the model and simulation for P4D simulations
model_settings = load_model_settings(; from_default_set = "P4D_cylindrical")
simulation_settings = load_simulation_settings(; from_default_set = "P4D_cylindrical")

# Setup the model
model = LithiumIonBattery(; model_settings)

# Setup the simulation
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# Solve the simulation
output = solve(sim)

# Cool interactive plotting of the results in the 3D geometry
plot_interactive_3d(output)
```


# Future development
Soon to be expected functionalities are:
- Fully flexible cycling protocol creation (already available in MATLAB version, see BattMo Family).
- Fully thermal coupling (already available in MATLAB version, see BattMo Family).
- Composite active materials (already available in MATLAB version, see BattMo Family).
- A user-friendly API for model development and adaptation.
- Additional tools for paramatrization of open circuit potentials, diffusion coefficients, etc.

# Software dependencies

BattMo.jl is a Julia-based software building on Jutul.jl [@Jutul:2025] which provides a reliable foundation for meshing
intricate geometries, efficiently solving large systems of equations, and visualizing the results. For plotting, BattMo.jl and Jutul.jl rely on Makie.jl [@Makie].


# BattMo Family

The following softwares include the BattMo family:
- [BattMo.jl](https://github.com/BattMoTeam/BattMo.jl) (described in this paper)
- [BattMo](https://github.com/BattMoTeam/BattMo) (MATLAB version)
- [PyBattMo](https://github.com/BattMoTeam/BattMo.jl) (Python wrapper around BattMo.jl)
- [BattMoApp](https://app.batterymodel.com/) (Online web-application build on top of BattMo.jl)


# Acknowledgements

We acknowledge contributions from the EU, Grant agreements 101069765, 875527, 101104013, 101103997

# References
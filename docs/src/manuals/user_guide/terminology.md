# Input terminology

This section describes the key terminology related to input parameters in BattMo. The input parameters influence both the physical behavior of the battery model and the numerical methods used for solving equations. These parameters are categorized based on their role in describing experimental conditions and numerical settings which divides them into two main groups:

- Parameters 
- Settings 

## Parameters
Parameters represent the controllable variables in real-world experiments.

They can be categorized based on their purpose:
- *Cell parameters*: Define the characteristics of a battery cell. Instantiated with type [`CellParameters`](@ref).
- *Cycling protocol parameters*: Specify how the cell is operated during a simulation (experiment). Instantiated with type [`CyclingProtocol`](@ref).

### Cell Parameters
These parameters characterize the intrinsic properties of a battery cell, such as:

```json
{"NegativeElectrode": {
    "Coating": {
      "BruggemanCoefficient": 1.5,
      "EffectiveDensity": 1900.0,
      "Thickness": 1.0e-4,
      "Width": 1.0e-2,
      "Length": 2.0e-2,
      "Area": 0.0002,
      "SurfaceCoefficientOfHeatTransfer": 1000
    }}}
```
All parameter values should be given in **SI units**. An examples of a cell parameter set can be found [here](https://github.com/BattMoTeam/BattMo.jl/blob/6b3316286e4345f0468d465296c49d68292eb1f7/src/input/defaults/cell_parameters/chen_2020.json).

### Cycling Parameters
These parameters define the operational conditions of the battery during a simulation, such as:

```json
    {
  "Protocol": "cc_discharge",
  "InitialStateOfCharge": 0.99,
  "DRate": 1.0,
  "LowerVoltageLimit": 2.5,
  "UpperVoltageLimit": 4.1,
  "InitialControl": "discharging",
  "AmbientTemperature": 298.15,
  "InitialTemperature": 298.15
}
```

An examples of a cycling protocol set can be found [here](https://github.com/BattMoTeam/BattMo.jl/blob/6b3316286e4345f0468d465296c49d68292eb1f7/src/input/defaults/cycling_protocols/cc_discharge.json).

## Settings
Settings are used to configure numerical assumptions for solving equations and finding numerical solutions.

They can be categorized based on their purpose:
- *Model settings*: instantiated with type [`ModelSettings`](@ref).
- *Simulation settings*: instantiated with type [`SimulationSettings`](@ref).
- *Solver settings*: instantiated with type [`SolverSettings`](@ref).

### Model Settings
Define numerical assumptions related to the battery model, such as diffusion methods or simplifications used in the simulation:

```json
{
    "ModelFramework": "P2D",
    "TransportInSolid": "FullDiffusion",
    "CurrentCollectors": false,
    "RampUp": "Sinusoidal",
    "SEIModel": "Bolay"
}
```
An examples of model settings can be found [here](https://github.com/BattMoTeam/BattMo.jl/blob/6b3316286e4345f0468d465296c49d68292eb1f7/src/input/defaults/model_settings/p2d.json).

### Simulation Settings
Define numerical assumptions specific to the simulation process, including time-stepping schemes and discretization precision:

```json
{

    "PositiveElectrodeCoatingGridPoints": 10,
    "PositiveElectrodeParticleGridPoints": 10,
    "NegativeElectrodeCoatingGridPoints": 10,
    "NegativeElectrodeParticleGridPoints": 10,
    "SeparatorGridPoints": 10,
    "Grid": [],
    "TimeStepDuration": 50,
    "RampUpTime": 10,
    "RampUpSteps": 5
}
```
An examples of simulation settings can be found [here](https://github.com/BattMoTeam/BattMo.jl/blob/6b3316286e4345f0468d465296c49d68292eb1f7/src/input/defaults/simulation_settings/p2d.json).

### Solver Settings
Define the solver behavior and verbosity:

```json
{

    "LinearSolver": {
        "Method": "Direct",
        "MaxSize": 1000000
    },
    "Verbose": {
        "InfoLevel": 0,
    }
}
```
An examples of simulation settings can be found [here](https://github.com/BattMoTeam/BattMo.jl/blob/6b3316286e4345f0468d465296c49d68292eb1f7/src/input/defaults/solver_settings/direct.json).


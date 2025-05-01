# High level interface


## Input types

```@docs
BattMo.AbstractInput
ParameterSet
CellParameters
CyclingProtocol
ModelSettings
SimulationSettings
FullSimulationInput
BattMoFormattedInput
BattMo.InputParams
BattMo.MatlabInputParams
```

## Read input

```@docs
load_cell_parameters
load_cycling_protocol
load_model_settings
load_simulation_settings
load_battmo_formatted_input
load_matlab_battmo_input
```

## Battery model types

```@docs
BatteryModel
LithiumIonBatteryModel
```

## Forward simulation

```@docs
Simulation
solve
run_battery
```

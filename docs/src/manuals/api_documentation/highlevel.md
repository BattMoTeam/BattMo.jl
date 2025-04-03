# High level interface


## Input types

```@docs
AbstractInput
ParameterSet
CellParameters
CyclingProtocol
ModelSettings
SimulationSettings
FullSimulationInput
BattMoFormattedInput
InputParams
MatlabInputParams
```

## Read input 

```@docs
read_cell_parameters
read_cycling_protocol
read_model_settings
read_simulation_settings
read_battmo_formatted_input
read_matlab_battmo_input
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


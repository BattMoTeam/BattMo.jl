# High level interface


## Input types

```@docs
BattMo.AbstractInput
ParameterSet
CellParameters
CyclingProtocol
ModelSettings
SimulationSettings
```

## Read input

```@docs
load_cell_parameters
load_cycling_protocol
load_model_settings
load_simulation_settings
```

## Model types

```@docs
ModelConfigured
LithiumIonBattery
```

## Forward simulation

```@docs
Simulation
solve(problem::Simulation; kwargs...)
BattMo.solve_simulation
```
## Retrieve output variables
```@docs
get_output_time_series
get_output_states
get_output_metrics
```

## Plotting
```@docs
plot_dashboard
plot_output
plot_interactive_3d
```

## Tools that print information
```@docs
print_submodels
print_default_input_sets
```

## Tools that write files
```@docs
generate_default_parameter_files
write_to_json_file
```

## Calibration

```@docs
AbstractCalibration
VoltageCalibration
solve(vc::AbstractCalibration; kwarg...)
free_calibration_parameter!
print_calibration_overview
```
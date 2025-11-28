# High level interface


## Input types

```@docs
BattMo.AbstractInput
ParameterSet
CellParameters
CyclingProtocol
ModelSettings
SimulationSettings
SolverSettings
FullSimulationInput
```

## Read input

```@docs
load_cell_parameters
load_cycling_protocol
load_model_settings
load_simulation_settings
load_solver_settings
load_full_simulation_input
```

## Model types

```@docs
ModelConfigured
LithiumIonBattery
SodiumIonBattery
```

## Forward simulation

```@docs
Simulation
solve(problem::Simulation; kwargs...)
run_simulation
```

## Plotting
```@docs
plot_dashboard
plot_output
plot_interactive_3d
plot_cell_curves
```

## Tools that print extra information
```@docs
print_info(input::S; view = nothing) where {S <: ParameterSet}
print_info(output::SimulationOutput)
print_info(from_name::String; view::Union{Nothing, String} = nothing)
print_info(calibration::AbstractCalibration)
quick_cell_check(cell::CellParameters; cell_2::Union{Nothing, CellParameters} = nothing)
print_submodels()
print_default_input_sets()
```

## Tools that write files
```@docs
generate_default_parameter_files
write_to_json_file
```

## Voltage Calibration

```@docs
AbstractCalibration
VoltageCalibration
solve(vc::AbstractCalibration; kwarg...)
free_calibration_parameter!
print_calibration_overview
```
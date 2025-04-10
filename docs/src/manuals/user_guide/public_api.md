# Public API

This document provides an overview of the public API for using `BattMo`. The API allows users to load parameter sets, define battery models, setup simulation objects and run simulations.

## Loading Parameters
Input parameter files are stored in JSON format and define the characteristics of the battery model and the simulation environment. For more information in the input terminilogy have a look at the [input terminology](./terminology) section.

Parameters are loaded using helper functions that read JSON files and return structured data. These functions are [`read_cell_parameters`](@ref), [`read_cycling_protocol`](@ref), [`read_model_settings`](@ref), and [`read_simulation_settings`](@ref). Each function takes a file path as input and returns a dictionary containing the respective settings.

## Model Initialization
A model can be instantiated using the sub classes of abstract type [`BatteryModel`](@ref). At the moment only the [`LithiumIonBatteryModel`](@ref) constructor is available. By passing a [`ModelSettings`](@ref) object to the constructor, the user can personalize the model to be solved.

## Simulation Initialization
A Simulation object can be instantiated using the [`Simulation`](@ref) constructor. This constructor requires the instantiated model object, [`CellParameters`](@ref) struct and [`CyclingProtocol`](@ref) structs as arguments and takes a instantiated [`SimulationSettings`](@ref) struct as an optional argument.

## Solve for a simulation
A simulation can be solved by passing a [`Simulation`](@ref) object to the [`solve`](@ref) function. This function will return the simulation output.

## Example Usage
Below is an example of a complete workflow:

```julia
# Define file paths
file_path_cell = "path/to/cell_parameters.json"
file_path_model = "path/to/model_settings.json"
file_path_cycling = "path/to/cycling_protocol.json"
file_path_simulation = "path/to/simulation_settings.json"

# Load parameters
cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
model_settings = load_model_settings(; from_file_path = file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)

# Initialize model and simulation
model = LithiumIonBatteryModel(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

# Run simulation
output = solve(sim)
```

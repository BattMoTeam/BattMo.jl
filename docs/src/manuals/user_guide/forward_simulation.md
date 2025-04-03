# Public API Forward Simulation

## Overview
This document provides an overview of the public API for setting up and running battery cell simulations using `BattMo`. The API allows users to define battery model parameters, load cycling protocols, configure simulation settings, and execute battery simulations.

## File Paths
Input parameter files are stored in JSON format and define the characteristics of the battery model and the simulation environment.

```julia
file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_3D_demoCase.json")
file_path_model = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/model_settings/", "model_settings_P2D.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCCV.json")
file_path_simulation = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simulation_settings/", "simulation_settings_P2D.json")
```

## Loading Parameters
Parameters are loaded using helper functions that read JSON files and return structured data.

```julia
cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
model_settings = read_model_settings(file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)
```

### Function Signatures

[`read_cell_parameters`](@ref) -> [`CellParameters`](@ref)\n
[`read_cycling_protocol`](@ref) -> [`CyclingProtocol`](@ref)\n
[`read_model_settings`](@ref) -> [`ModelSettings`](@ref)\n
[`read_simulation_settings`](@ref) -> [`SimulationSettings`](@ref)\n

Each function takes a file path as input and returns a dictionary containing the respective settings.

## Model and Simulation Initialization
Once the parameters are loaded, a battery model is instantiated and a simulation is configured.

```julia
model = LithiumIonBatteryModel(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)
output = solve(sim)
```

### Function Signatures

[`LithiumIonBatteryModel(; model_settings::ModelSettings)`](@ref) -> [`SimulationSettings`](@ref) \n
[`Simulation(model::LithiumIonBatteryModel, cell_parameters::Dict, cycling_protocol::Dict; simulation_settings::Dict)`](@ref) -> [`Simulation`](@ref)\n
[`solve(solving_problem::Simulation)`](@ref) -> [`SimulationOutput`](@ref)\n
```julia
LithiumIonBatteryModel(; model_settings::ModelSettings) -> LithiumIonBatteryModel
Simulation(model::LithiumIonBatteryModel, cell_parameters::Dict, cycling_protocol::Dict; simulation_settings::Dict) -> Simulation
solve(sim::Simulation) -> SimulationOutput
```
- `LithiumIonBatteryModel` initializes a battery model using the provided settings.
- `Simulation` sets up a simulation using the model, cell parameters, and cycling protocol.
- `solve` executes the simulation and returns the results.


## Example Usage
Below is an example of a complete workflow:

```julia
# Define file paths
file_path_cell = "path/to/cell_parameters.json"
file_path_model = "path/to/model_settings.json"
file_path_cycling = "path/to/cycling_protocol.json"
file_path_simulation = "path/to/simulation_settings.json"

# Load parameters
cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
model_settings = read_model_settings(file_path_model)
simulation_settings = read_simulation_settings(file_path_simulation)

# Initialize model and simulation
model = LithiumIonBatteryModel(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

# Run simulation
output = solve(sim)
```

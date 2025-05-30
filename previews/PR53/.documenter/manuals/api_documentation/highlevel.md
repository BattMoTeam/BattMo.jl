
# High level interface {#High-level-interface}

## Input types {#Input-types}
<details class='jldocstring custom-block' open>
<summary><a id='BattMo.AbstractInput' href='#BattMo.AbstractInput'><span class="jlbinding">BattMo.AbstractInput</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractInput
```


Abstract type for all parameter sets that can be given as an input to BattMo.

For any structure of this type, it is possible to access and set the values of the object using the same syntax as a standard Julia [dictionary](https://docs.julialang.org/en/v1/base/collections/#Dictionaries).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L11-L18" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.ParameterSet' href='#BattMo.ParameterSet'><span class="jlbinding">BattMo.ParameterSet</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Abstract type for parameter sets that are part of the user API.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L146-L148" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.CellParameters' href='#BattMo.CellParameters'><span class="jlbinding">BattMo.CellParameters</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Cell parameter set type that represents the cell parameters


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L194" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.CyclingProtocol' href='#BattMo.CyclingProtocol'><span class="jlbinding">BattMo.CyclingProtocol</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Parameter set type that represents the cycling protocol related parameters


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L204" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.ModelSettings' href='#BattMo.ModelSettings'><span class="jlbinding">BattMo.ModelSettings</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Parameter set type that represents the model related settings


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L213" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.SimulationSettings' href='#BattMo.SimulationSettings'><span class="jlbinding">BattMo.SimulationSettings</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Parameter set type that represents the simulation related settings


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L223" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.FullSimulationInput' href='#BattMo.FullSimulationInput'><span class="jlbinding">BattMo.FullSimulationInput</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



Parameter set type that includes all other parameter set types


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L232" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.BattMoFormattedInput' href='#BattMo.BattMoFormattedInput'><span class="jlbinding">BattMo.BattMoFormattedInput</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
abstract type BattMoFormattedInput <: AbstractInput
```


Abstract type representing input parameters formatted for BattMo. This type is used exclusively in the backend as an input to the simulation. Subtypes of `BattMoFormattedInput` contain parameter dictionaries structured for BattMo compatibility.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L241-L247" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.InputParams' href='#BattMo.InputParams'><span class="jlbinding">BattMo.InputParams</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct InputParams <: BattMoFormattedInput
```


Represents a validated and backend-formatted set of input parameters for a BattMo simulation.

**Fields**
- `data ::Dict{String, Any}` : A dictionary storing the input parameters for BattMo.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L251-L258" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.MatlabInputParams' href='#BattMo.MatlabInputParams'><span class="jlbinding">BattMo.MatlabInputParams</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct MatlabInputParams <: BattMoFormattedInput
```


Represents input parameters derived from MATLAB-generated files, formatted for BattMo compatibility.

**Fields**
- `data ::Dict{String, Any}` : A dictionary storing MATLAB-extracted input parameters.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/input_types.jl#L265-L272" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Read input {#Read-input}
<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_cell_parameters' href='#BattMo.load_cell_parameters'><span class="jlbinding">BattMo.load_cell_parameters</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_cell_parameters(; from_file_path::String = nothing, from_default_set::String = nothing, from_model_template::BatteryModelSetup = nothing)
```


Reads and loads cell parameters either from a JSON file, a default set, or a model template.

**Arguments**
- `from_file_path ::String` : (Optional) Path to the JSON file containing cell parameters.
  
- `from_default_set ::String` : (Optional) The name of the default set to load cell parameters from.
  
- `from_model_template ::BatteryModelSetup` : (Optional) A `BatteryModelSetup` instance used to load an empty set of cell parameters required for the concerning model.
  

**Returns**

An instance of `CellParameters`.

**Errors**

Throws an `ArgumentError` if none of the arguments are provided.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L35-L50" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_cycling_protocol' href='#BattMo.load_cycling_protocol'><span class="jlbinding">BattMo.load_cycling_protocol</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_cycling_protocol(; from_file_path::String = nothing, from_default_set::String = nothing)
```


Reads and loads cycling protocol either from a JSON file or a default set.

**Arguments**
- `from_file_path ::String` : (Optional) Path to the JSON file containing cycling protocol.
  
- `from_default_set ::String` : (Optional) The name of the default set to load cycling protocol from.
  

**Returns**

An instance of `CyclingProtocol`.

**Errors**

Throws an `ArgumentError` if neither `from_file_path` nor `from_default_set` is provided.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L72-L86" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_model_settings' href='#BattMo.load_model_settings'><span class="jlbinding">BattMo.load_model_settings</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_model_settings(; from_file_path::String = nothing, from_default_set::String = nothing)
```


Reads and loads model settings either from a JSON file or a default set.

**Arguments**
- `from_file_path ::String` : (Optional) Path to the JSON file containing model settings.
  
- `from_default_set ::String` : (Optional) The name of the default set to load model settings from.
  

**Returns**

An instance of `ModelSettings`.

**Errors**

Throws an `ArgumentError` if neither `from_file_path` nor `from_default_set` is provided.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L5-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_simulation_settings' href='#BattMo.load_simulation_settings'><span class="jlbinding">BattMo.load_simulation_settings</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_simulation_settings(; from_file_path::String = nothing, from_default_set::String = nothing, from_model_template::BatteryModelSetup = nothing)
```


Reads and loads simulation settings either from a JSON file, a default set, or a model template.

**Arguments**
- `from_file_path ::String` : (Optional) Path to the JSON file containing simulation settings.
  
- `from_default_set ::String` : (Optional) The name of the default set to load simulation settings from.
  
- `from_model_template ::BatteryModelSetup` : (Optional) A `BatteryModelSetup` instance used to load an empty set of simulation settings required for the concerning model.
  

**Returns**

An instance of `SimulationSettings`.

**Errors**

Throws an `ArgumentError` if none of the arguments are provided.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L102-L117" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_battmo_formatted_input' href='#BattMo.load_battmo_formatted_input'><span class="jlbinding">BattMo.load_battmo_formatted_input</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_battmo_formatted_input(filepath::String)
```


Reads and parses a JSON file into an `InputParams` instance.

**Arguments**
- `filepath ::String` : Path to the JSON file.
  

**Returns**

An instance of `InputParams`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L153-L163" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.load_matlab_battmo_input' href='#BattMo.load_matlab_battmo_input'><span class="jlbinding">BattMo.load_matlab_battmo_input</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
load_matlab_battmo_input(inputFileName::String)
```


Reads the input from a MATLAB output file which contains a description of the model and returns an `MatlabInputParams` that can be sent to the simulator.

**Arguments**
- `inputFileName ::String` : Path to the MATLAB file.
  

**Returns**

An instance of `MatlabInputParams` that can be sent to the simulator via `run_battery`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/input/loader.jl#L136-L148" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Battery model types {#Battery-model-types}
<details class='jldocstring custom-block' open>
<summary><a id='BattMo.BatteryModelSetup' href='#BattMo.BatteryModelSetup'><span class="jlbinding">BattMo.BatteryModelSetup</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
abstract type BatteryModelSetup
```


Abstract type representing a battery model. All battery models should inherit from this type.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/models/full_battery_model_setups/battery_model.jl#L4-L9" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.LithiumIonBattery' href='#BattMo.LithiumIonBattery'><span class="jlbinding">BattMo.LithiumIonBattery</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct LithiumIonBattery <: BatteryModelSetup
```


Represents a lithium-ion battery model based on the Doyle-Fuller-Newman approach.

**Fields**
- `name ::String` : A descriptive name for the model.
  
- `model_settings ::ModelSettings` : Settings specific to the model.
  

**Constructor**

```
LithiumIonBattery(; model_settings = get_default_model_settings(LithiumIonBattery))
```


Creates an instance of `LithiumIonBattery` with the specified or default model settings. The model name is automatically generated based on the model geometry.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/models/full_battery_model_setups/lithium_ion.jl#L5-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Forward simulation {#Forward-simulation}
<details class='jldocstring custom-block' open>
<summary><a id='BattMo.Simulation' href='#BattMo.Simulation'><span class="jlbinding">BattMo.Simulation</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
struct Simulation <: SolvingProblem
```


Represents a battery simulation problem to be solved.

**Fields**
- `function_to_solve ::Function` : The function responsible for running the simulation.
  
- `model ::BatteryModelSetup` : The battery model being simulated.
  
- `cell_parameters ::CellParameters` : The cell parameters for the simulation.
  
- `cycling_protocol ::CyclingProtocol` : The cycling protocol used.
  
- `simulation_settings ::SimulationSettings` : The simulation settings applied.
  
- `is_valid ::Bool` : A flag indicating if the simulation is valid.
  

**Constructor**

```
Simulation(model::BatteryModelSetup, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol; simulation_settings::SimulationSettings = get_default_simulation_settings(model))
```


Creates an instance of `Simulation`, initializing it with the given parameters and defaulting simulation settings if not provided.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/setup/model_setup.jl#L24-L42" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.solve' href='#BattMo.solve'><span class="jlbinding">BattMo.solve</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
solve(problem::Simulation; hook=nothing, kwargs...)
```


Solves a given `Simulation` problem by running the associated simulation function.

**Arguments**
- `problem ::Simulation` : The simulation problem instance.
  
- `hook` (optional) : A user-defined function or callback to modify the solving process.
  
- `kwargs...` : Additional keyword arguments passed to the solver.
  

**Returns**

The output of the simulation if the problem is valid. 

**Throws**

Throws an error if the `Simulation` object is not valid, prompting the user to check warnings during instantiation.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/setup/model_setup.jl#L123-L138" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BattMo.run_battery' href='#BattMo.run_battery'><span class="jlbinding">BattMo.run_battery</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
run_battery(model::BatteryModelSetup, cell_parameters::CellParameters, 
			cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings; 
			hook=nothing, kwargs...)
```


Runs a battery simulation using the provided model, cell parameters, cycling protocol, and simulation settings.

**Arguments**
- `model ::BatteryModelSetup` : The battery model to be used.
  
- `cell_parameters ::CellParameters` : The cell parameter set.
  
- `cycling_protocol ::CyclingProtocol` : The cycling protocol parameter set.
  
- `simulation_settings ::SimulationSettings` : The simulation settings parameter set.
  
- `hook` (optional) : A user-defined function or callback to modify the process.
  
- `kwargs...` : Additional keyword arguments.
  

**Returns**

The output of the battery simulation after executing `run_battery` with formatted input.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/setup/model_setup.jl#L250-L267" target="_blank" rel="noreferrer">source</a></Badge>



```julia
run_battery(inputparams::AbstractInputParams; hook = nothing)
```


Simulate a battery for a given input. The input is expected to be an instance of AbstractInputParams. Such input can be prepared from a json file using the function [`load_battmo_formatted_input`](/manuals/api_documentation/highlevel#BattMo.load_battmo_formatted_input).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/BattMoTeam/BattMo.jl/blob/5b8152bf0b90b0bc202fc3e49808e77eeb1d854c/src/setup/model_setup.jl#L285-L292" target="_blank" rel="noreferrer">source</a></Badge>

</details>


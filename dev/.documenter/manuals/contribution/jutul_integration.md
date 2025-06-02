
# Code architecture and Jutul.jl {#Code-architecture-and-Jutul.jl}

The BattMo code relies heavily on Jutul. Jutul is a Julia framework for fully differentiable multiphysics simulators. This page has the purpose of giving an overview on how the BattMo code is structured starting from the input variables until until solving the simulation with the focus on how Jutul is utilized throughout the code. See the [Jutul documentation](https://sintefmath.github.io/Jutul.jl/dev/) for more information on their API.

BattMo uses `Jutul.simulate` [function](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.simulate) to solve for the complete battery model. To this function we pass: initial states, `Jutul.Simulator`, time steps, forces, and some configurations.

Let&#39;s go through each of the arguments one by one to see how we set them up. We&#39;ll start with the `Jutul.Simulator` as that one is the most complicated.

## Simulator {#Simulator}

`Jutul.Simulator` is a [Jutul Type](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.Simulator) that we use to set up a simulator object for the battery model to be solved. Within the `Jutul.Simulator` struct, we store our battery model and the parameters that belong to the model. The Simulator type requires the model to be of type `Jutul.JutulModel`, and the parameters should be off type `Jutul.JutulStorage`.

### JutulModel {#JutulModel}

`Jutul.JutulModel` is a Jutul abstract type that contains several subclasses: `Jutul.SimulationModel`, which can be used when passing a single model to the simulator, and `Jutul.MultiModel`, which can be used when passing a model consisting of several submodels to the simulator.

The BattMo backend defines the complete simulation model by combining several submodels. These submodels are:
- ActiveMaterialModel
  
- ElectrolyteModel
  
- CurrentCollectorModel
  
- SEIModel
  
- CurrentAndVoltageModel
  

Each of these submodels is stored as a `Jutul.SimulationModel` [Struct](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.SimulationModel), and then the submodels are stored within a `Jutul.MultiModel` [Struct](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.MultiModel).
- model settings
  
- simulation settings
  

### SimulationModel {#SimulationModel}

The `Jutul.SimulationModel` [Struct](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.SimulationModel) stores the following attributes:
- domain (`::Jutul.JutulDomain`): `Jutul.DataDomain` and `Jutul.DiscritizedDomain`, obtained from the finite volume mesh of type `Jutul.FiniteVolumeMesh`
  
- system (`::Jutul.JutulSystem`): the system to be solved, so in the case of `ActiveMaterialModel`, this is for example the struct `ActiveMaterial` which stores the concerning parameters and a discretization struct containing descritization data.
  
- primary_variables: An ordered dict containing the primary variables. These are the variables that are solved directly from the transport equations.
  
- secondary_variables: variables that depend on the primary_variables.
  
- parameters: some other variables that infuence the calculation of the primary variables
  
- equations: the equations used to solve the system
  
- output_variables: the output variables that are wanted
  

When calling the `Jutul.SimulationModel` constructor, giving it the domain and system as arguments, it calls the following functions to retrieve the other attributes: 

```
Jutul.update_model_pre_selection!
Jutul.select_primary_variables!
Jutul.select_secondary_variables!
Jutul.select_parameters!
Jutul.select_equations!
Jutul.select_output_variables!
Jutul.update_model_post_selection!  
```


BattMo defines these equations for every submodel type. 

### JutulStorage {#JutulStorage}

The `Jutul.JutulStorage [Struct](https://sintefmath.github.io/Jutul.jl/dev/usage/#Jutul.JutulStorage) stores a dict of a parameter set.

We divide the BattMo simulation input variables in several categories:
- Cell parameters
  
- Cycling parameters
  
- Model settings
  
- Simulation settings
  

See the page about [terminology](../user_guide/terminology.md) to learn more about the definition of each of these variable categories.

When cell parameters are loaded by the user, the parameters will be devidided further into subcategories according to the different submodels defined within the BattMo backend. 

These means that we end up with the following variable sets that will be handled in the BattMo backend:
- active material parameters
  
- electrolyte parameters
  
- current collector parameters
  
- sei layer parameters
  
- thermal parameters
  
- cycling parameters
  
- model settings
  
- simulation settings
  

All the parameter sets (not the settings) are linked to the submodels an need to be therefore handled as the correct type within Jutul. Therefore, each of these parameter sets are stored as a `Jutul.JutulStorage` type.

The model settings and simulation settings will be handled in a different way.

The model settings are only handled within the BattMo backend and specificy some assumptions on the model, like for example, wether to include the current collector model in the simulation. 

The simulation settings contain information about the time and spatial discretization. 

## Time steps {#Time-steps}

The time steps are also an argument of the `Jutul.simulate` function. These are determined from both the cycling parameters, which specify the cycling protocol, and the simulation setting, which specify the time discretization. The time steps are computed in the BattMo backend and then passed on as an Array to the `Jutul.simulate` function.

## Other used functions from Jutul {#Other-used-functions-from-Jutul}
- `Jutul.setup_cross_term`
  
- `jutul.add_cross_term`
  

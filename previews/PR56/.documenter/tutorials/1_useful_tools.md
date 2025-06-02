


# Useful Tools in BattMo {#Useful-Tools-in-BattMo}

Before we dive into how to set up and run simulations, it&#39;s helpful to get familiar with some of the built-in tools provided by **BattMo**. These utilities can save time and improve your workflow, and we&#39;ll be using most of them throughout the tutorials.

```julia
using BattMo
```


## Saving Default Parameter Sets Locally {#Saving-Default-Parameter-Sets-Locally}

BattMo includes several default parameter sets that you can use as a starting point. If you want to explore or customize them, you can easily save them to your local disk using:

```julia
path = pwd()
folder_name = "default_parameter_sets"
generate_default_parameter_files(path, folder_name)
```


```ansi
🛠 JSON files successfully written! Path:
	/home/runner/work/BattMo.jl/BattMo.jl/docs/build/tutorials/default_parameter_sets
```


This will create a folder in your current working directory containing the default parameter files.

## Viewing Parameter Set Information {#Viewing-Parameter-Set-Information}

To quickly inspect which default parameter sets are included with BattMo and what each contains, you can use:

```julia
print_default_input_sets_info()
```


```ansi

====================================================================================================
📋 Overview of Available Default Sets
====================================================================================================

📁 cell_parameters:         Chen2020, Xu2015
📁 cycling_protocols:       CCCV, CCCharge, CCCycling, CCDischarge, user_defined_current_function
📁 model_settings:          P2D, P4D_pouch
📁 simulation_settings:     P2D, P4D_pouch

====================================================================================================
📖 Detailed Descriptions
====================================================================================================

📂 cell_parameters
----------------------------------------------------------------------------------------------------
Chen2020
🔹 Cell name:       	LG INR 21700 M50
🔹 Cell case:       	Cylindrical
🔹 Source:          	]8;;https://doi.org/10.1149/1945-7111/ab9050\visit]8;;\
🔹 Suitable for:
   • CurrentCollectors:  Generic
   • SEIModel:           Bolay
   • RampUp:             Sinusoidal
   • TransportInSolid:   FullDiffusion
   • ModelFramework:     P2D
🔹 Description:     	Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration. SEI parameters are from Bolay2022: https://doi.org/10.1016/j.powera.2022.100083 .

Xu2015
🔹 Cell name:       	LP2770120
🔹 Cell case:       	Pouch
🔹 Source:          	]8;;https://doi.org/10.1016/j.energy.2014.11.073\visit]8;;\
🔹 Suitable for:
   • CurrentCollectors:  Generic
   • RampUp:             Sinusoidal
   • TransportInSolid:   FullDiffusion
   • ModelFramework:     P2D, P4D Pouch
🔹 Description:     	Parameter set of a commercial Type LP2770120 prismatic LiFePO4/graphite cell, for an electrochemical pseudo-two-dimensional (P2D) model.

📂 cycling_protocols
----------------------------------------------------------------------------------------------------
CCCV
🔹 Description:     	Parameter set for a constant current constant voltage cyling protocol.

CCCharge
🔹 Description:     	Parameter set for a constant current charging protocol.

CCCycling
🔹 Description:     	Parameter set for a constant current cycling protocol.

CCDischarge
🔹 Description:     	Parameter set for a constant current discharging protocol.

user_defined_current_function
🔹 Description:     	Parameter set that shows an example of how to include a user defined function in the cycling protocol parameters.

📂 model_settings
----------------------------------------------------------------------------------------------------
P2D
🔹 Description:     	Default model settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.

P4D_pouch
🔹 Description:     	Default model settings for a P4D pouch simulation including a current ramp up, current collectors.

📂 simulation_settings
----------------------------------------------------------------------------------------------------
P2D
🔹 Suitable for:
   • SEIModel:           Bolay
   • RampUp:             Sinusoidal
   • TransportInSolid:   FullDiffusion
   • ModelFramework:     P2D
🔹 Description:     	Default simulation settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.

P4D_pouch
🔹 Suitable for:
   • SEIModel:           Bolay
   • RampUp:             Sinusoidal
   • TransportInSolid:   FullDiffusion
   • CurrentCollector:   Generic
   • ModelFramework:     P2D, P4D Pouch
🔹 Description:     	Default simulation settings for a P4D pouch simulation including a current ramp up, current collectors.
```


## Inspecting Individual Parameters {#Inspecting-Individual-Parameters}

If you&#39;re unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example:

```julia
parameter_name = "OpenCircuitPotential"

print_parameter_info(parameter_name)
```


```ansi
================================================================================
ℹ️  Parameter Information
================================================================================
🔹 Name:         	OpenCircuitPotential
🔹 Description:		The open-circuit potential of the active material under a given intercalant stoichimetry and temperature.
🔹 Type:         	String, Dict{String, Vector}, Real
🔹 Unit:         	V
🔹 Documentation:	]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/simulation_dependent_input\visit]8;;\
🔹 Ontology link:	]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_9c657fdc_b9d3_4964_907c_f9a6e8c5f52b\visit]8;;\
```


Another example

```julia
parameter_name = "ModelFramework"

print_parameter_info(parameter_name)
```


```ansi
❌ No parameters found matching: ModelFramework
```


This is especially useful when building or editing custom parameter sets.

## Listing Available Submodels {#Listing-Available-Submodels}

BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:

```julia
print_submodels_info()
```


```ansi
================================================================================
ℹ️  Submodels Information
================================================================================
Parameter                     Options                       Documentation
--------------------------------------------------------------------------------
CurrentCollectors             Generic                       -
SEIModel                      Bolay                         ]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/sei_model\visit]8;;\
RampUp                        Sinusoidal                    ]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/ramp_up\visit]8;;\
TransportInSolid              FullDiffusion                 -
ModelFramework                P2D, P4D Pouch                ]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\visit]8;;\
```


## Write a parameter set object to a JSON file {#Write-a-parameter-set-object-to-a-JSON-file}

You can use the following function to save your ParameterSet object to a JSON file:

```julia
file_path = "path_to_json_file/file.json"
parameter_set = CellParameters(Dict("NegativeElectrode" => Dict("ElectrodeCoating" => Dict("Thickness" => 100e-6))))

write_to_json_file(file_path, parameter_set)
```


```ansi
An error occurred while writing to the file: SystemError("opening file \"path_to_json_file/file.json\"", 2, nothing)
```


## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/1_useful_tools.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/1_useful_tools.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

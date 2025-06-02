


# Tutorial: Creating Your Own Parameter Sets in BattMo.jl {#Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl}

This tutorial walks you through the process of creating and customizing your own parameter sets in **BattMo.jl**. Parameter sets define the physical and chemical properties of the battery system you&#39;re simulating. You can build them from scratch using model templates, modify them, and save them for future use.

## Step 1: Load a Model Setup {#Step-1:-Load-a-Model-Setup}

```julia
#First, define the battery model configuration you'd like to use. This will serve as the template for generating your parameter set. BattMo includes several default setups to choose from.


using BattMo

model_settings = load_model_settings(; from_default_set = "P4D_pouch")
model_setup = LithiumIonBattery(; model_settings)
```


```ansi
LithiumIonBattery("Setup object for a P4D Pouch lithium-ion model", {
    "CurrentCollectors" => "Generic"
    "RampUp" => "Sinusoidal"
    "Metadata" =>     {
        "Description" => "Default model settings for a P4D pouch simulation including a current ramp up, current collectors."
        "Title" => "P4D_pouch"
    }
    "TransportInSolid" => "FullDiffusion"
    "ModelFramework" => "P4D Pouch"
}, true)
```


## Step 2: Create an Empty Parameter Set {#Step-2:-Create-an-Empty-Parameter-Set}

Next, create an empty parameter dictionary based on your model setup. This will include all the required keys but without any values filled in.

```julia
empty_cell_parameter_set = load_cell_parameters(; from_model_template = model_setup)
```


```ansi
{
    "Electrolyte" =>     {
        "TransferenceNumber" => 0.0
        "DiffusionCoefficient" => 0.0
        "IonicConductivity" => 0.0
        "Density" => 0.0
        "ChargeNumber" => 0.0
        "Concentration" => 0.0
    }
    "Cell" =>     {
        "ElectrodeGeometricSurfaceArea" => 0.0
        "ElectrodeWidth" => 0.0
        "ElectrodeLength" => 0.0
        "Case" => ""
    }
    "PositiveElectrode" =>     {
        "ActiveMaterial" =>         {
            "ActivationEnergyOfDiffusion" => 0.0
            "NumberOfElectronsTransfered" => 0.0
            "StoichiometricCoefficientAtSOC0" => 0.0
            "OpenCircuitPotential" => 0.0
            "ReactionRateConstant" => 0.0
            "MassFraction" => 0.0
            "StoichiometricCoefficientAtSOC100" => 0.0
            "ActivationEnergyOfReaction" => 0.0
            "MaximumConcentration" => 0.0
            "VolumetricSurfaceArea" => 0.0
            "DiffusionCoefficient" => 0.0
            "ParticleRadius" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
            "ChargeTransferCoefficient" => 0.0
        }
        "ElectrodeCoating" =>         {
            "BruggemanCoefficient" => 0.0
            "EffectiveDensity" => 0.0
            "Thickness" => 0.0
        }
        "Binder" =>         {
            "MassFraction" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
        }
        "CurrentCollector" =>         {
            "TabLength" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
            "Thickness" => 0.0
            "TabWidth" => 0.0
        }
        "ConductiveAdditive" =>         {
            "MassFraction" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
        }
    }
    "Separator" =>     {
        "Density" => 0.0
        "BruggemanCoefficient" => 0.0
        "Thickness" => 0.0
        "Porosity" => 0.0
    }
    "NegativeElectrode" =>     {
        "ActiveMaterial" =>         {
            "ActivationEnergyOfDiffusion" => 0.0
            "NumberOfElectronsTransfered" => 0.0
            "StoichiometricCoefficientAtSOC0" => 0.0
            "OpenCircuitPotential" => 0.0
            "ReactionRateConstant" => 0.0
            "MassFraction" => 0.0
            "StoichiometricCoefficientAtSOC100" => 0.0
            "ActivationEnergyOfReaction" => 0.0
            "MaximumConcentration" => 0.0
            "VolumetricSurfaceArea" => 0.0
            "DiffusionCoefficient" => 0.0
            "ParticleRadius" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
            "ChargeTransferCoefficient" => 0.0
        }
        "ElectrodeCoating" =>         {
            "BruggemanCoefficient" => 0.0
            "EffectiveDensity" => 0.0
            "Thickness" => 0.0
        }
        "Binder" =>         {
            "MassFraction" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
        }
        "CurrentCollector" =>         {
            "TabLength" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
            "Thickness" => 0.0
            "TabWidth" => 0.0
        }
        "ConductiveAdditive" =>         {
            "MassFraction" => 0.0
            "Density" => 0.0
            "ElectronicConductivity" => 0.0
        }
    }
}
```


## Step 3: Save the Empty Parameter Set to a JSON File {#Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File}

You can now write this empty set to a JSON file. This file can be edited manually, shared, or used as a base for further customization.

```julia
file_path = "my_custom_parameters.json"
write_to_json_file(file_path, empty_cell_parameter_set)
```


```ansi
Data successfully written to my_custom_parameters.json
```


## Step 4: Get Help with Parameters {#Step-4:-Get-Help-with-Parameters}

If you&#39;re unsure about what a specific parameter means or how it should be formatted, BattMo provides a helpful function to inspect any parameter.

```julia
print_parameter_info("OpenCircuitPotential")
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


## Step 5: Now you can load you own parameter set to run simulations with it. {#Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it.}

```julia
	cell_parameters = load_cell_parameters(; from_file_path = "my_custom_parameters.json")
```


## Example on GitHub {#Example-on-GitHub}

If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/5_create_parameter_sets.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/5_create_parameter_sets.ipynb)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._

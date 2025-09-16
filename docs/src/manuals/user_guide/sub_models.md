# Sub-models overview (ModelSettings)

## Available sub-models


| ModelSetting                      | Sub-model(s)                              | Description                                                           |      
|-----------------------------------|-------------------------------------------|-----------------------------------------------------------------------|
| `"ModelFrameWork"`                | "P2D", "P4D Pouch", "P4D Cylindrical"     | [See the PXD section](../user_guide/pxd_model.md)                     |
| `"TransportInSolid"`              | "FullDiffusion"                           | -                                                                     |
| `"RampUp"`                        | "Sinusoidal"                              | [See the Ramp Up section](../user_guide/ramp_up.md)                   |
| `"ButlerVolmer"`                  | "Standard", "Chayambuka"                  | [See the Sodium ion section](../user_guide/sodium_ion_model.md)       |   
| `"CurrentCollectors"`             | "Standard"                                | -                                                                     |
| `"SEIModel"`                      | "Bolay"                                   | [See the SEI section](../user_guide/sei_model.md)                     |
| `"TemperatureDependence"`         | "Arrhenius"                               | [See the temperature dependence section](../user_guide/arrhenius.md)  |
| `"PotentialFlowDiscretization"`   | "GeneralAD", "TwoPointDiscretization"     | -                                                                     |

## How to select sub-models

Sub-models can be selected by defining the concerning setting in the model settings. If the setting is not defined that submodel will not be used. Create a json file and set the settings within the file or load a file and alter it in the command line.

```
# load model settings file
model_settings = load_model_setttings(; from_default_set = "P2D")

# modify settings
model_settings["TemperatureDependent"] = "Arrhenius"
```

Or create a ModelSettings instance.

```
model_settings = ModelSettings(Dict(
    "ModelFrameWork"    => "P2D",
    "TransportInSolid"  => "FullDiffusion",
    "RampUp"            => "Sinusoidal",
    "ButlerVolmer"      => "Standard"
))

model_settings["TemperatureDependent"] = "Arrhenius"
```

The model settings can then be pased to the battery model struct that you'd like to use, for example, to instantiate a lithium ion battery model:

```
model = LithiumIonBattery(;model_settings = model_settings)
```
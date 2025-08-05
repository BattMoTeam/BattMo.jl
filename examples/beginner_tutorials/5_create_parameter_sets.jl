# # Tutorial: Creating Your Own Parameter Sets in BattMo.jl

# This tutorial walks you through the process of creating and customizing your own parameter sets in **BattMo.jl**. Parameter sets define the physical and chemical properties of the battery system you're simulating. You can build them from scratch using model templates, modify them, and save them for future use.


# ## Step 1: Load a Model Setup

#First, define the battery model configuration you'd like to use. This will serve as the template for generating your parameter set. BattMo includes several default setups to choose from.


using BattMo

model_settings = load_model_settings(; from_default_set = "P4D_pouch")
model = LithiumIonBattery(; model_settings)


# ## Step 2: Create an Empty Parameter Set

# Next, create an empty parameter dictionary based on your model setup. This will include all the required keys but without any values filled in.


empty_cell_parameter_set = load_cell_parameters(; from_model_template = model)


# ## Step 3: Save the Empty Parameter Set to a JSON File

# You can now write this empty set to a JSON file. This file can be edited manually, shared, or used as a base for further customization.


file_path = "my_custom_parameters.json"
write_to_json_file(file_path, empty_cell_parameter_set)

# ## Step 4: Get Help with Parameters

# If you're unsure about what a specific parameter means or how it should be formatted, BattMo provides a helpful function to inspect any parameter.

print_parameter_info("OpenCircuitPotential")


# ## Step 5: Now you can load you own parameter set to run simulations with it.

try # hide
	cell_parameters = load_cell_parameters(; from_file_path = "my_custom_parameters.json")
	nothing # hide
catch # hide
	nothing # hide
end # hide

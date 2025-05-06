# # Useful Tools in BattMo

# Before we dive into how to set up and run simulations, it's helpful to get familiar with some of the built-in tools provided by **BattMo**. 
# These utilities can save time and improve your workflow, and we'll be using most of them throughout the tutorials.


using BattMo

# ## Saving Default Parameter Sets Locally

# BattMo includes several default parameter sets that you can use as a starting point. 
# If you want to explore or customize them, you can easily save them to your local disk using:

path = pwd()
folder_name = "default_parameter_sets"
generate_default_parameter_files(path, folder_name)
nothing # hide 

# This will create a folder in your current working directory containing the default parameter files.

# ## Viewing Parameter Set Information

# To quickly inspect which default parameter sets are included with BattMo and what each contains, you can use:

print_default_parameter_sets_info()


# ## Inspecting Individual Parameters
# If you're unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example:

parameter_name = "OpenCircuitVoltage"

print_parameter_info(parameter_name)

# Another example

parameter_name = "ModelGeometry"

print_parameter_info(parameter_name)

# This is especially useful when building or editing custom parameter sets.

# ## Listing Available Submodels

# BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:

print_submodels_info()





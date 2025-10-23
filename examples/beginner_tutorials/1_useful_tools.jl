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

print_default_input_sets()


# ## Inspecting Individual Parameters
# If you're unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example, for cell parameters and cycling protocol parameters:

parameter_name = "OpenCircuitPotential"

print_info(parameter_name; view = "CellParameters")

# An example for model or simulation settings:

parameter_name = "ModelFramework"

print_info(parameter_name; view = "ModelSettings")

# An example for output variables:

parameter_name = "Concentration"

print_info(parameter_name; view = "OutputVariable")

# And a general example, find variables with charge in the name.

print_info("charge")


# This is especially useful when building or editing custom parameter sets.

# ## Listing Available Submodels

# BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:

print_submodels()


# ## Write a parameter set object to a JSON file

# You can use the following function to save your ParameterSet object to a JSON file:

file_path = "path_to_json_file/file.json"
parameter_set = CellParameters(Dict("NegativeElectrode" => Dict("Coating" => Dict("Thickness" => 100e-6))))

write_to_json_file(file_path, parameter_set)
nothing # hide


# ## Get quick information on a cell parameter set

# Let's load a default cell parameter set.
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
nothing # hide

# You can easily print some handy quantities and metrics for debugging:

quick_cell_check(cell_parameters)

# If there are functional parameters present within the parameter set, like the OCP or electrolyte diffusion coefficient, you can easily plot those parameters against a realistic x-quantity range:

plot_cell_curves(cell_parameters)


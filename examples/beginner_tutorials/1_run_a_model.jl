# # How to run a model
#
# Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.

using BattMo

# BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default 
# parameter sets, for example the Li-ion parameter set that has been created from the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 


file_name = "p2d_40_jl_chen2020.json"
file_path_cell = string(dirname(pathof(BattMo)), "/../input/cell_parameters/", "cell_parameter_set_chen2020.json")
file_path_model = string(dirname(pathof(BattMo)), "/../input/model_settings/", "model_settings_P2D.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../input/cycling_protocols/", "CCCV.json")
file_path_simulation = string(dirname(pathof(BattMo)), "/../input/simulation_settings/", "simulation_settings_P2D.json")

# First we convert the json data to a julia dict and format it using the folowing function.


####### Many functions API
cell_parameters = load_cell_parameters(file_path_cell)
cycling_protocol = load_cycling_protocol(file_path_cycling)
model_settings = load_model_settings(file_path_model)
simulation_settings = load_simulation_settings(file_path_simulation)


########################################


model = LithiumIon(; model_settings);

output = run_battery(model, CellParameters(Dict("Cell" => Dict("Case" => "Cylindrical"))), cycling_protocol; simulation_settings);



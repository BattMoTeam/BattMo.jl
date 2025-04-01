# # How to run a model
#
# Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.

using BattMo

# BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default 
# parameter sets, for example the Li-ion parameter set that has been created from the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)

########################################


model = LithiumIon();

# output = run_battery(inputparams)
output = run_battery(model, cell_parameters, cycling_protocol);

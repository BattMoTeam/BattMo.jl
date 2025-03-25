# # How to run a model
#
# Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.

using BattMo

# BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default 
# parameter sets, for example the Li-ion parameter set that has been created from the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050). 


file_name = "p2d_40_jl_chen2020.json"
file_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", file_name)

# First we convert the json data to a julia dict and format it using the folowing function.


####### Many functions API
cell_parameters = set_cell_parameters_bpx(filepath)
cell_parameters = load_cell_parameters(filepath)
cycling_protocol = load_cycling_protocol(filepath)
simulation_settings = load_simulation_settings(filepath::String)

###### multiple dispatch API
cell_parameters = load_parameters(CellParameters, filepath::String)
cell_parameters = load_parameters(BPXParameters, filepath::String)
cell_parameters = load_parameters(MatlabParameters, filepath::String)
cycling_protocol = load_parameters(CyclingProtocol, filepath::String)
simulation_settings = load_parameters(SimulationSettings, filepath::String)'

##### Multiple dispatch + constructor API
cell_parameters = CellParameters(filepath::String)
cell_parameters = BPXParameters(filepath::String)
cell_parameters = MatlabParameters(filepath::String)
cycling_protocol = CyclingProtocol(filepath::String)
simulation_settings = SimulationSettings(filepath::String)

########################################

function set_cell_parameters(; file_path, url, name, dict)

end

model = LithiumIon(cell_parameters; model_settings)

model = LithiumIon("Chen2020")

cycling_protocol = load_cycling_protocol("CCCV")

results = simulate(model, cycling_protocol)


# Then we can run the model.

results = run_battery(model; cycling_protocol);

# # Handling simulation outputs

# In this tutorial we will explore the outputs of a simulation for interesting tasks:
# - Plot voltage and current curves
# - Plot overpotentials
# - Plot cell states in space and time
# - Save outputs
# - Load outputs.

# Lets start with loading some pre-defined cell parameters, cycling protocols, and running a simulation. 

using BattMo, GLMakie

file_path_cell = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cell_parameters/", "cell_parameter_set_chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/cycling_protocols/", "CCDischarge.json")

cell_parameters = read_cell_parameters(file_path_cell)
cycling_protocol = read_cycling_protocol(file_path_cycling)
nothing # hide

model = LithiumIonBatteryModel()

sim = Simulation(model, cell_parameters, cycling_protocol);

output = solve(sim)
nothing # hide

# UPDATE WITH NEW OUTPUT API

# ### The simulation output

# ### Access overpotentials

# ### Plot cell states

# ### Save and load outputs






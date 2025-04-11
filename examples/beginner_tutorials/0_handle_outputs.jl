# # Handling simulation outputs

# In this tutorial we will explore the outputs of a simulation for interesting tasks:
# - Plot voltage and current curves
# - Plot overpotentials
# - Plot cell states in space and time
# - Save outputs
# - Load outputs.

# Lets start with loading some pre-defined cell parameters, cycling protocols, and running a simulation. 

using BattMo, GLMakie

file_path_cell = string(dirname(pathof(BattMo)), "/input/defaults/cell_parameters/", "Chen2020_calibrated.json")
file_path_cycling = string(dirname(pathof(BattMo)), "/input/defaults/cycling_protocols/", "CCDischarge.json")

cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)
cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)
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






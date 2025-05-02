# # Handling simulation outputs

# In this tutorial we will explore the outputs of a simulation for interesting tasks:
# - Plot voltage and current curves
# - Plot overpotentials
# - Plot cell states in space and time
# - Save outputs
# - Load outputs.

# Lets start with loading some pre-defined cell parameters, cycling protocols, and running a simulation. 

using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
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






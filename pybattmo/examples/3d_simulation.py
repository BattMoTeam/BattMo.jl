# Partial port of https://battmoteam.github.io/BattMo.jl/dev/tutorials/2_run_a_simulation
from battmo import *
import plotly.express as px

# Load parameter sets
cell_parameters = load_cell_parameters(from_default_set="Chen2020")
cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
model_settings = load_model_settings(from_default_set="P4D_cylindrical")
simulation_settings = load_simulation_settings(from_default_set="P4D_cylindrical")

# Setup model and simulation
model = LithiumIonBattery(model_settings=model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol, simulation_settings=simulation_settings)
output = solve(sim)

# Plot voltage curve
plot_dashboard(output)

# Plot interative 3D results
plot_interactive_3d(output)

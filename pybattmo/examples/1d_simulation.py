# Partial port of https://battmoteam.github.io/BattMo.jl/dev/tutorials/2_run_a_simulation
from battmo import *
import plotly.express as px
import pandas as pd
import numpy as np

# Load parameter sets
cell_parameters = load_cell_parameters(from_default_set="Chen2020")
cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")

# Have a quick look into what kind of cell we're dealing with
print_cell_info(cell_parameters)

# Setup model and simulation
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)
output = solve(sim)

# Have a look into which output quantities are available
print_output_overview(output)

# Plot voltage curve
time_series = output.time_series

df = to_pandas(time_series)
fig = px.line(df, x="Time", y="Voltage", title="Voltage curve")
fig.show()

# Plot a dashboard
plot_dashboard(output, plot_type="contour")

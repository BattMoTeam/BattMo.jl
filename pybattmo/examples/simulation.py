# Partial port of https://battmoteam.github.io/BattMo.jl/dev/tutorials/2_run_a_simulation
from battmo import *
import plotly.express as px
import pandas as pd
import numpy as np

cell_parameters = load_cell_parameters(from_default_set="Chen2020")
cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")

model_setup = LithiumIonBattery()
sim = Simulation(model_setup, cell_parameters, cycling_protocol)
output = solve(sim)

print_output_overview(output)

time_series = get_output_time_series(output)

df = to_pandas(time_series)
fig = px.line(df, x="Time", y="Voltage", title="Unsorted Input")
fig.show()

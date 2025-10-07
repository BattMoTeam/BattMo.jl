# This example shows how the BattMos calibration api can be used and therefore only shows a simple calibration procedure using only one experimental voltage curve.
# A more complete example can be found among the BattMo.jl examples.


import pandas as pd
from battmo import *
import numpy as np
import plotly.express as px
import os

# Load experimental data
battmo_base = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
exdata = os.path.join(battmo_base, "examples", "example_data")

df_05 = pd.read_csv(os.path.join(exdata, "Xu_2015_voltageCurve_05C.csv"), names=["Time", "Voltage"])

# ## Load cell parameters and cycling protocol
cell_parameters = load_cell_parameters(from_default_set="Xu2015")
cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")

cycling_protocol["LowerVoltageLimit"] = 2.25

# ## Create model and simulation
model = LithiumIonBattery()

cycling_protocol["DRate"] = 0.5

sim = Simulation(model, cell_parameters, cycling_protocol)
output0 = solve(sim)

# Extract t-V data
time_series = output0.time_series

df_sim = to_pandas(time_series)

# Plot
fig = px.line(df_sim, x="Time", y="Voltage", title="Voltage curve")
# Add experimental data as another trace
fig.add_scatter(x=df_05["Time"], y=df_05["Voltage"], mode="markers", name="Experimental 0.5C")
fig.show()


# Set up the first calibration
cal = VoltageCalibration(np.array(df_05["Time"]), np.array(df_05["Voltage"]), sim)

#  Free some parameters to calibrate
free_calibration_parameter(
    cal,
    ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    lower_bound=0.0,
    upper_bound=1.0,
)
free_calibration_parameter(
    cal,
    ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
    lower_bound=0.0,
    upper_bound=1.0,
)

free_calibration_parameter(
    cal,
    ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"],
    lower_bound=0.0,
    upper_bound=1.0,
)
free_calibration_parameter(
    cal,
    ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"],
    lower_bound=0.0,
    upper_bound=1.0,
)

free_calibration_parameter(
    cal,
    ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"],
    lower_bound=10000.0,
    upper_bound=1e5,
)
free_calibration_parameter(
    cal,
    ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"],
    lower_bound=10000.0,
    upper_bound=1e5,
)

# print an overview of the calibration object
print_calibration_overview(cal)

# Solve the calibration problem
solve(cal)

# Retrieve the calibrated parameters and print an overview of the calibration
cell_parameters_calibrated = cal.calibrated_cell_parameters
print_calibration_overview(cal)

# Run a simulation using the calibrated cell parameters
sim_calibrated = Simulation(model, cell_parameters_calibrated, cycling_protocol)
output_calibrated = solve(sim_calibrated)

# ## Extract t-V data
time_series_cal = output_calibrated.time_series

df_sim_cal = to_pandas(time_series_cal)

# Plot
fig = px.line(df_sim, x="Time", y="Voltage", title="Voltage curve")
fig.data[0].name = "Base Simulation"
# Add experimental data as another trace
fig.add_scatter(x=df_05["Time"], y=df_05["Voltage"], mode="markers", name="Experimental 0.5C")
fig.add_scatter(x=df_sim_cal["Time"], y=df_sim_cal["Voltage"], mode="lines", name="Calibrated")
fig.show()

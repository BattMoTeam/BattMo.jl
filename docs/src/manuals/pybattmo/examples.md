# PyBattMo examples

This page provides a few examples of running simulations and calibrations with PyBattMo. For more detailed examples, please refer to the BattMo.jl documentation, as all functionalities are shared between the two.

> **Important tip**: run the examples within a notebook or using cells in [VSCode](https://code.visualstudio.com/docs/python/jupyter-support-py) to make use of the high performance of Julia. Julia compiles the functions and objects that you use when you first run a code. Because of this, the second time you run the same code it is super fast! But to make use of this, you need to have a kernel that keeps running in between code executions. Therefore, it does work with jupytor notebooks.
>
> **Note**: the BattMo plotting functions in PyBattMo are experimental and not very stable yet.

## Run a simulation

```python
from battmo import *
import plotly.express as px
import pandas as pd
import numpy as np

# Load parameter sets
cell_parameters = load_cell_parameters(from_default_set="chen_2020")
cycling_protocol = load_cycling_protocol(from_default_set="cc_discharge")

# Have a quick look into what kind of cell we're dealing with
quick_cell_check(cell_parameters)

# Setup model and simulation
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)
output = solve(sim)

# Have a look into which output quantities are available
print_info(output)

# Plotting using Plotly
df = to_pandas(output.time_series)
fig = px.line(df, x="Time", y="Voltage", title="Voltage curve")
fig.show()
```

## Run a 3D simulation

```python
from battmo import *

# Load parameter sets and settings
cell_parameters = load_cell_parameters(from_default_set="chen_2020")
cycling_protocol = load_cycling_protocol(from_default_set="cc_discharge")
model_settings = load_model_settings(from_default_set="p4d_cylindrical")
simulation_settings = load_simulation_settings(from_default_set="p4d_cylindrical")

# Setup model and simulation
model = LithiumIonBattery(model_settings=model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol, simulation_settings=simulation_settings)
output = solve(sim)

# Plot interative 3D results
plot_interactive_3d(output)
```

## Calibrate a cell parameter set to experimental data

```python
# The purpose of this example is to show how you can use the BattMo calibration api and therefore only shows a simple calibration procedure using only one experimental voltage curve is shown. A more complete example can be found among the BattMo.jl examples.

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
cell_parameters = load_cell_parameters(from_default_set="xu_2015")
cycling_protocol = load_cycling_protocol(from_default_set="cc_discharge")

cycling_protocol["LowerVoltageLimit"] = 2.25
cycling_protocol["DRate"] = 0.5

# ## Create model and simulation object
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)
output0 = solve(sim)

# Extract t-V data
df_sim = to_pandas(output.time_series)

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
print_info(cal)

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

```

## Headless UI

```python
from battmo import *

simulation_input = load_full_simulation_input(from_default_set="chen_2020")

output = run_simulation(simulation_input)

plot_dashboard(output, plot_type="contour")
```

## User defined input function
This short example shows how a user defined python function, describing an input parameter, can be exposed to BattMo.
```python
from battmo import *

def negative_electrode_ocp(c, T, refT, cmax):
    ocp = get_1d_interpolator(x, ocp)
    return ocp(c / cmax)

# Expose function to battmo
expose_to_battmo(negative_electrode_ocp)
```

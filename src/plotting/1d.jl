export plot_dashboard, plot_output, plot_cell_curves

#####################################################################################################
# The actual functions within this script can be found within "../ext/BattMoGLMakieExt.jl"
#####################################################################################################

function plot_cell_curves end

function plot_cell_curves_ end

"""
	BattMo.plot_output(output, output_variables; layout=nothing)

Plot specified variables from simulation output using GLMakie.

# Arguments
- `output`: NamedTuple with simulation data.
- `output_variables`: Vector of variable names or groups of names to plot.
- `layout`: Optional (nrows, ncols) tuple to set subplot arrangement.

# Notes
- Requires GLMakie to be imported beforehand.
- Automatically chooses layout if none provided.
- Supports line plots (1D data) and contour plots (2D data).
- Displays units and metadata in labels.

# Example
```julia
using GLMakie
fig = BattMo.plot_output(output, 
				["Voltage vs Time", 
				["NeAmSurfaceConcentration vs Time at Position index 1", "NeAmSurfaceConcentration vs Time at Position index 10"],
				"ElectrolytePotential vs time and Position",
				]; layout=(3,1))
```
"""
function plot_output end

function plot_impl end

"""
	BattMo.plot_dashboard(output; plot_type="simple")

Plot a dashboard summarizing simulation output with selectable styles.

# Arguments
- `output`: Simulation output NamedTuple.
- `plot_type`: One of `"simple"`, `"line"`, or `"contour"` (default `"simple"`).

# Description
- `"simple"`: Shows time series of current and voltage.
- `"line"`: Adds interactive line plots of concentrations and potentials with a time slider.
- `"contour"`: Shows contour plots of concentrations and potentials over time and position.

# Example
```julia
using GLMakie
fig = BattMo.plot_dashboard(output; plot_type="line")
```
"""
function plot_dashboard end

function plot_dashboard_impl end



export plot_dashboard, plot_output, plot_cell_curves, plot_thermal_source_contributions


#####################################################################################################
# The actual functions within this script can be found within "../ext/BattMoMakieExt.jl"
#####################################################################################################

"""
    BattMo.plot_cell_curves_impl(cell_parameters::CellParameters; new_window = true)

Plot functional parameter curves from a cell parameter set.

Scans `cell_parameters` for known functional properties (e.g., open-circuit potential, diffusion coefficient,
reaction rate constant, conductivity) and plots their dependence on concentration and temperature.

# Arguments
- `cell_parameters::CellParameters`: Cell parameter object containing model data.
- `new_window::Bool = true`: If `true`, display the figure in a new window.

# Returns
- `fig::Figure`: A Makie figure with subplots of all detected functional parameter curves.

# Notes
- Only functional (non-constant) parameters are plotted.
- The layout and axes are auto-scaled based on the number and type of parameters.
"""
function plot_cell_curves(arg...; kwarg...)
	check_plotting_availability()
	plot_cell_curves_impl(arg...; kwarg...)
end

function plot_cell_curves_impl end

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
				["NegativeElectrodeActiveMaterialSurfaceConcentration vs Time at Position index 1", "NegativeElectrodeActiveMaterialSurfaceConcentration vs Time at Position index 10"],
				"ElectrolytePotential vs time and Position",
				]; layout=(3,1))
```
"""
function plot_output(arg...; kwarg...)
	check_plotting_availability()
	plot_output_impl(arg...; kwarg...)
end

function plot_output_impl end

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
function plot_dashboard(arg...; kwarg...)
	check_plotting_availability()
	plot_dashboard_impl(arg...; kwarg...)
end

function plot_dashboard_impl end

"""
	BattMo.plot_thermal_source_contributions(time, source_parts; total_source=nothing, include_residual=true, normalize=false, new_window=true)

Plot thermal source-term contributions over time from the post-processed thermal source decomposition.
The figure contains two panels:
- Total heat production versus time.
- Accumulated (time-integrated) contribution of each individual source.

# Arguments
- `time`: Time vector.
- `source_parts`: Vector of dictionaries as returned by `get_energy_source!` (second return value) for each time step.

# Keywords
- `total_source=nothing`: Optional vector of total source fields (one per time step). If provided with `include_residual=true`,
  a residual contribution is plotted as `total - sum(source_parts)`.
- `include_residual=true`: Include residual line when `total_source` is provided.
- `normalize=false`: Plot percentage contribution of total source instead of absolute power.
- `new_window=true`: Open in independent plotting window when available.
"""
function plot_thermal_source_contributions(arg...; kwarg...)
	check_plotting_availability()
	plot_thermal_source_contributions_impl(arg...; kwarg...)
end

function plot_thermal_source_contributions_impl end


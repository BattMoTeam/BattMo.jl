export plot_dashboard, plot_output, plot_cell_curves
export activate_browser, deactivate_browser

#####################################################################################################
# The actual functions within this script can be found within "../ext/BattMoGLMakieExt.jl"
#####################################################################################################

function activate_browser()
	ENV["Browser"] = "true"
end

function deactivate_browser()
	ENV["Browser"] = "false"
end

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
				["NeAmSurfaceConcentration vs Time at Position index 1", "NeAmSurfaceConcentration vs Time at Position index 10"],
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

function independent_figure(fig)
	display(fig)
end

function check_plotting_availability(; throw = true, interactive = false)
	ok = true
	try
		ok = check_plotting_availability_impl()
	catch e
		if throw
			if e isa MethodError
				error("""Plotting is not available. You need to have either a GLMakie or WGLMakie backend available. 
					GLMakie opens the plots in a separate window and is recommended for interactive plots.
					WGLMakie renders the plots in your browser. 

					To fix: using Pkg; Pkg.add(\"GLMakie\") and then call using GLMakie to enable plotting.
					
					or: using Pkg; Pkg.add(\"WGLMakie\") and then call using WGLMakie, activate_browser(), and using BattMoGLMakieExt to enable plotting.
					
					""")
			else
				rethrow(e)
			end
		else
			ok = false
		end
	end
	if interactive
		plotting_check_interactive()
	end
	return ok
end

function check_plotting_availability_impl

end


module BattMoMakieExt

using BattMo, RuntimeGeneratedFunctions
using Makie: Makie
using Makie: Slider, Label, Axis, Colorbar, Figure, Observable, GridLayout
using Makie: scatterlines!, contourf!, vlines!, lines!, autolimits!
using Makie: on, axislegend
using Jutul: si_unit

RuntimeGeneratedFunctions.init(@__MODULE__)

function BattMo.check_plotting_availability_impl()
	return true
end

function BattMo.independent_figure(fig)
	backend_str = string(nameof(Makie.current_backend()))
	if backend_str == "GLMakie"
		BattMo.independent_figure_GLMakie(fig)
	elseif backend_str == "WGLMakie"
		BattMo.independent_figure_WGLMakie(fig)

	else
		@warn "Independent figure creation not implemented for backend $(Makie.current_backend())."
	end
end

function BattMo.plot_cell_curves_impl(cell_parameters::CellParameters; new_window = true)
	num_points = 100

	function last_key(path::String)
		parts = split(path, '/')
		return parts[end]
	end

	meta_data = get_cell_parameters_meta_data()

	# --- Define the known functional parameters ---
	param_map = Dict(
		"NegativeElectrode/ActiveMaterial/OpenCircuitPotential" => (BattMo.setup_ocp_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"PositiveElectrode/ActiveMaterial/OpenCircuitPotential" => (BattMo.setup_ocp_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"NegativeElectrode/ActiveMaterial/DiffusionCoefficient" => (BattMo.setup_electrode_diff_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"PositiveElectrode/ActiveMaterial/DiffusionCoefficient" => (BattMo.setup_electrode_diff_evaluation_expression_from_string, [:c, :T, :refT, :cmax]),
		"NegativeElectrode/ActiveMaterial/ReactionRateConstant" => (BattMo.setup_reaction_rate_constant_evaluation_expression_from_string, [:c, :T]),
		"PositiveElectrode/ActiveMaterial/ReactionRateConstant" => (BattMo.setup_reaction_rate_constant_evaluation_expression_from_string, [:c, :T]),
		"Electrolyte/IonicConductivity" => (BattMo.setup_conductivity_evaluation_expression_from_string, [:c, :T]),
		"Electrolyte/DiffusionCoefficient" => (BattMo.setup_diffusivity_evaluation_expression_from_string, [:c, :T]),
	)

	# --- collect only the parameters that exist and are plottable ---
	functional_params = String[]
	for (param_path, _) in param_map
		keys = split(param_path, "/")
		val = cell_parameters.all
		for k in keys
			if isa(val[k], Real)
				val = nothing
				break
			end
			val = val[k]
		end
		if !(val === nothing)
			push!(functional_params, param_path)
		end
	end

	n = length(functional_params)
	ncols = ceil(Int, sqrt(n))
	nrows = ceil(Int, n / ncols)

	# --- auto-scale figure size based on rows/cols ---
	fig = Figure(size = (400 * ncols, 300 * nrows))

	for (i, param_path) in enumerate(functional_params)
		# Retrieve value from nested Dict
		keys = split(param_path, "/")
		val = cell_parameters.all
		for k in keys
			val = val[k]
		end

		# Determine axis label and concentration range
		if occursin("NegativeElectrode", param_path)
			cmax = cell_parameters.all["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"]
			c_range = range(0, cmax, length = num_points)
			x_values = c_range ./ cmax
			x_label = "Stoichiometry  /  -"
		elseif occursin("PositiveElectrode", param_path)
			cmax = cell_parameters.all["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"]
			c_range = range(0, cmax, length = num_points)
			x_values = c_range ./ cmax
			x_label = "Stoichiometry  /  -"
		elseif occursin("Electrolyte", param_path)
			c0 = cell_parameters.all["Electrolyte"]["Concentration"]
			c_range = range(0.2c0, 4c0, length = num_points)
			x_values = c_range
			unit = meta_data["Concentration"]["unit"]
			x_label = "Electrolyte concentration  /  $unit"
			cmax = missing
		else
			c_range = range(0, 1, length = num_points)
			x_values = c_range
			x_label = "c"
			cmax = missing
		end

		# --- row-wise placement ---
		row = (i - 1) ÷ ncols
		col = (i - 1) % ncols

		y = Float64[]
		T_val = 298.15
		refT_val = 298.15

		if isa(val, AbstractString) && haskey(param_map, param_path)
			quantity = last_key(param_path)
			unit = meta_data[quantity]["unit"]
			ax = Axis(fig[row, col], title = param_path,
				xlabel = x_label, ylabel = "$quantity / $unit")
			setup_func, args_symbols = param_map[param_path]
			f_expr = setup_func(val)
			f_generated = @RuntimeGeneratedFunction(f_expr)

			# Evaluate function with the appropriate arguments
			if :cmax in args_symbols && :refT in args_symbols
				y = [f_generated(c, T_val, refT_val, cmax) for c in c_range]
			elseif length(args_symbols) == 2
				y = [f_generated(c, T_val) for c in c_range]
			else
				y = [f_generated(c) for c in c_range]
			end
			lines!(ax, x_values, y, color = :blue)

		elseif isa(val, Dict)
			quantity = last_key(param_path)
			unit = meta_data[quantity]["unit"]
			ax = Axis(fig[row, col], title = param_path,
				xlabel = x_label, ylabel = "$quantity / $unit")

			if all(haskey(val, k) for k in ["X", "Y"])
				x_values, y = val["X"], val["Y"]
			elseif haskey(val, "FunctionName")
				f = BattMo.setup_function_from_function_name(val["FunctionName"])
				if isa(cmax, Missing)
					y = [f(c, T_val) for c in c_range]
				else
					try
						y = [f(c, T_val, T_val, cmax) for c in c_range]
					catch
						y = [f(c, T_val) for c in c_range]
					end
				end
			end
			lines!(ax, x_values, y, color = :blue)
		end
	end

	if new_window
		BattMo.independent_figure(fig)
	end
	return fig
end




function BattMo.plot_output_impl(
	output::SimulationOutput,
	variables::Union{Vector{String}, Vector{Any}, Vector{Any}};
	layout::Union{Nothing, Tuple{Int, Int}} = nothing,
	new_window = true,
)
	grouped_vars = [isa(g, String) ? [g] : g for g in variables]
	nplots = length(grouped_vars)

	# Determine layout
	if layout === nothing
		nrows = floor(Int, sqrt(nplots))
		ncols = ceil(Int, nplots / nrows)
	else
		nrows, ncols = layout
		if nrows * ncols < nplots
			error("Layout $(nrows)x$(ncols) is too small for $nplots plots.")
		end
	end

	fig = Figure(size = (1000, 350 * nrows))
	grid = fig[1, 1] = GridLayout()

	# Get time info
	time_series_data = output.time_series
	full_time = time_series_data["Time"]
	nt = length(full_time)
	available_time_vars = keys(time_series_data)

	# Get metadata for units
	meta_data = BattMo.get_output_variables_meta_data()

	# Helper: Parse variable string
	function parse_variable(varstr::String)
		base = match(r"(.+)vs", varstr) |> x -> strip(x[1])

		dims = occursin(r"vs", varstr) ? match(r"vs (.+?)(?: at|$)", varstr) |> x -> split(strip(x[1]), r" and ") : []

		selectors = Dict{String, Union{Nothing, Int, Symbol}}()
		for cap in eachmatch(r"(\w+) index (\w+)", varstr)
			dim = String(cap[1])
			idx = if cap[2] == "end"
				:end
			else
				parse(Int, cap[2])
			end
			selectors[dim] = idx
		end
		return (base = strip(base), dims = dims, selectors = selectors)
	end

	# Helper: Get unit string for main quantities only (with slash and spaces)
	function get_main_unit_str(quantity)
		if haskey(meta_data, quantity) && haskey(meta_data[quantity], "unit")
			unit = meta_data[quantity]["unit"]
			return isempty(unit) ? "" : "  / $unit"   # two spaces, slash, space, then unit
		end
		return ""
	end

	# Helper: Build title suffix with actual index values and units for dims if available (no slash, just space before unit)
	function build_title_suffix(non_plot_dims, sel, known_dims)
		parts = String[]
		for d in non_plot_dims
			idx = get(sel, d, nothing)
			if idx === :end
				idx = length(known_dims[d])
			elseif idx === nothing
				push!(parts, "$(d)=all")
				continue
			end
			val = known_dims[d][idx]

			# Determine unit string for dimension
			unit_str = ""
			if d == "Position" || d == "NegativeElectrodeActiveMaterialRadius" || d == "PositiveElectrodeActiveMaterialRadius"
				val = val * 1e6   # convert from meters to μm
				unit_str = " μm"
			elseif d == :Time
				if haskey(meta_data, "Time") && haskey(meta_data["Time"], "unit")
					u = meta_data["Time"]["unit"]
					if !isempty(u)
						unit_str = " $u"
					end
				end
			else
				if haskey(meta_data, string(d)) && haskey(meta_data[string(d)], "unit")
					u = meta_data[string(d)]["unit"]
					if !isempty(u)
						unit_str = " $u"
					end
				end
			end

			val_str = isa(val, Number) ? string(round(val, digits = 3)) : string(val)
			push!(parts, "$(d)=$val_str$unit_str")
		end

		isempty(parts) ? "" : " at " * join(parts, ", ")
	end

	# Helper: Warn and skip if all data are NaNs
	function all_nan_warn(varstr, data)
		if all(isnan, data)
			@warn "All values are NaN for variable \"$varstr\". Data will not be visible in the plot."
			return true
		end
		return false
	end

	# Main loop
	for (i, var_group) in enumerate(grouped_vars)
		row = div(i - 1, ncols) + 1
		col = mod(i - 1, ncols) + 1
		subgrid = GridLayout()
		grid[row, col] = subgrid

		ax_432 = Axis(subgrid[1, 1])
		plotted_lines = false
		plot_type = nothing  # :line or :contour or nothing

		for varstr in var_group
			try
				parsed = parse_variable(varstr)

				clean_var = parsed.base
				dims = parsed.dims
				dims = String.(dims)
				sel = parsed.selectors

				main_unit_str = get_main_unit_str(clean_var)

				# State variables and metrics
				states_data = output.states
				metric_data = output.metrics
				time_series = output.time_series

				data = merge(states_data, metric_data, time_series)

				var_data = data[clean_var]

				rad_pe = data["PositiveElectrodeActiveMaterialRadius"] * 1e6
				rad_ne = data["NegativeElectrodeActiveMaterialRadius"] * 1e6
				pos = data["Position"] * 1e6
				nt = length(full_time)
				cycles = metric_data["CycleIndex"]

				known_dims = Dict(pairs(data))
				dim_lengths = Dict("Time" => nt, "Position" => length(pos), "NegativeElectrodeActiveMaterialRadius" => length(rad_ne), "PositiveElectrodeActiveMaterialRadius" => length(rad_pe), "CycleNumber" => length(cycles))
				sz = size(var_data)

				# Ensure dims are plain strings
				dims = String.(dims)

				# Build dimension assignments
				dim_assignments = Dict{Int, String}()
				for (i, s) in enumerate(sz)
					assigned = false

					# Only look at dims specified in the "vs"
					for d in dims
						if haskey(data, d) && length(data[d]) == s
							dim_assignments[i] = d
							assigned = true
							break
						end
					end

					# Also check selectors
					if !assigned
						for d in keys(sel)
							if haskey(data, d) && length(data[d]) == s
								dim_assignments[i] = d
								assigned = true
								break
							end
						end
					end

					if !assigned
						error("Could not assign dimension $i for variable $clean_var with size $sz (length: $s)")
					end
				end

				# Now plot_dims_syms is exactly the dims from "vs"
				plot_dims_syms = dims
				non_plot_dims = setdiff(collect(values(dim_assignments)), plot_dims_syms)

				# Build slicing tuple
				slices = Any[]
				for i in 1:ndims(var_data)
					dim_sym = dim_assignments[i]
					if dim_sym in plot_dims_syms
						push!(slices, Colon())
					elseif haskey(sel, dim_sym)
						idx = get(sel, dim_sym, nothing)
						if idx === :end
							push!(slices, length(data[dim_sym]))
						elseif idx isa Int
							push!(slices, idx)
						else
							error("Selector index has wrong type for non-plotted dimension $dim_sym in \"$varstr\"")
						end
					end
				end


				# Extract data slice
				data_slice = var_data[slices...]

				# Check for all NaN slice and skip if so
				if all_nan_warn(varstr, vec(data_slice))
					continue
				end

				# Build axis values
				x_sym = plot_dims_syms[1]
				x_vals = known_dims[x_sym]
				x_label = string(x_sym) * "  /  " * meta_data[String(x_sym)]["unit"]

				if length(plot_dims_syms) == 1
					title_suffix = build_title_suffix(non_plot_dims, sel, known_dims)
					label_with_suffix = isempty(title_suffix) ? varstr : "$title_suffix"

					lines!(ax_432, x_vals, vec(data_slice), label = label_with_suffix)
					ax_432.xlabel = x_label
					ax_432.ylabel = clean_var * main_unit_str
					# Set the title explicitly using title! function:
					ax_432.title = isempty(title_suffix) ? varstr : "$clean_var"
					plotted_lines = true
					plot_type = :line

				elseif length(plot_dims_syms) == 2
					if plot_type == :line
						@warn "Mixing line and contour plots in the same subplot is not supported."
					end
					plot_type = :contour

					y_sym = plot_dims_syms[2]
					y_vals = known_dims[y_sym]
					y_label = string(y_sym) * "  /  " * meta_data[String(x_sym)]["unit"]

					if size(data_slice) == (length(y_vals), length(x_vals))
						z = data_slice
					elseif size(data_slice) == (length(x_vals), length(y_vals))
						z = data_slice'
					else
						error("Unexpected shape $(size(data_slice)), expected (y,x)=($(length(y_vals)),$(length(x_vals)))")
					end

					co = contourf!(ax_432, x_vals, y_vals, z'; colormap = :viridis)

					ax_432.xlabel = x_label
					ax_432.ylabel = y_label
					Colorbar(subgrid[1, 2], co, label = "$main_unit_str")

					title_suffix = build_title_suffix(non_plot_dims, sel, known_dims)
					ax_432.title = isempty(title_suffix) ? varstr : "$clean_var$title_suffix"

				else
					error("More than 2 plot dimensions not supported: $dims")
				end

			catch e
				error("Failed to plot \"$varstr\": $(e.msg)")
			end
		end

		if plotted_lines
			axislegend(ax_432)
			# Clear title if multiple lines to avoid clutter, or you can customize
			if var_group isa Vector && length(var_group) > 1
				ax_432.title = ""
			end
		end
	end

	if new_window

		BattMo.independent_figure(fig)
	end
	return fig
end


function BattMo.plot_dashboard_impl(output; plot_type = "simple", new_window = true)

	time_series = output.time_series
	t = time_series["Time"] / si_unit("hour")
	I = time_series["Current"]
	E = time_series["Voltage"]

	states = output.states

	n_steps = length(t)
	x = states["Position"] * 10^6

	NeAm_conc = states["NegativeElectrodeActiveMaterialSurfaceConcentration"]
	PeAm_conc = states["PositiveElectrodeActiveMaterialSurfaceConcentration"]
	Elyte_conc = states["ElectrolyteConcentration"]

	NeAm_pot = states["NegativeElectrodeActiveMaterialPotential"]
	PeAm_pot = states["PositiveElectrodeActiveMaterialPotential"]
	Elyte_pot = states["ElectrolytePotential"]
	if plot_type == "simple"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Simple Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  h"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  h"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		if new_window
			BattMo.independent_figure(fig)
		end

		return fig

	elseif plot_type == "line"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Line Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  h"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  h"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		slider = Slider(grid[6, 1:3], range = 1:n_steps, startvalue = 1)
		ts = slider.value

		# Time observable for current slider step
		t_line = Observable(t[1])

		# Add vertical dashed grey line to Current and Voltage plots
		vline_current = vlines!(ax_current, t_line, color = :gray, linestyle = :dash)
		vline_voltage = vlines!(ax_voltage, t_line, color = :gray, linestyle = :dash)

		# Update the time for the vertical lines when slider changes
		on(ts) do i
			t_line[] = t[i]
		end

		function state_plot(ax_678, data, label)
			obs_data = Observable(data[1, :])
			plt = lines!(ax_678, x, obs_data, label = label; linewidth = 4)
			ax_678.xlabel = "Position  /  μm"
			on(ts) do i
				obs_data[] = data[i, :]
				autolimits!(ax_678)
			end
		end

		# Concentrations
		state_plot(Axis(grid[3, 1], title = "NeAm Surface Concentration  /  mol·m⁻³"), NeAm_conc, "NeAm SurfaceConcentration")
		state_plot(Axis(grid[3, 2], title = "Electrolyte Concentration  /  mol·m⁻³"), Elyte_conc, "Elyte C")
		state_plot(Axis(grid[3, 3], title = "PeAm Surface Concentration  /  mol·m⁻³"), PeAm_conc, "PeAm SurfaceConcentration")

		# Potentials
		state_plot(Axis(grid[4, 1], title = "NeAm Potential  /  V"), NeAm_pot, "NeAm ϕ")
		state_plot(Axis(grid[4, 2], title = "Electrolyte Potential  /  V"), Elyte_pot, "Elyte ϕ")
		state_plot(Axis(grid[4, 3], title = "PeAm Potential  /  V"), PeAm_pot, "PeAm ϕ")

		if new_window
			BattMo.independent_figure(fig)
		end

		return fig

	elseif plot_type == "contour"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Contour Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  h"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  h"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		function contour_with_labels(parent_grid, row, col, data, title)
			subgrid = parent_grid[row, col] = GridLayout()

			ax_678 = Axis(subgrid[1, 1])
			plt = contourf!(ax_678, x, t, data')
			ax_678.ylabel = "Time  /  h"
			ax_678.xlabel = "Position  / μm"
			ax_678.title = title

			Colorbar(subgrid[1, 2], plt, width = 15)
		end

		# Concentration plots
		contour_with_labels(grid, 3, 1, NeAm_conc, "NeAm Surface Concentration  /  mol·m⁻³")
		contour_with_labels(grid, 3, 2, Elyte_conc, "Electrolyte Concentration  /  mol·m⁻³")
		contour_with_labels(grid, 3, 3, PeAm_conc, "PeAm Surface Concentration  /  mol·m⁻³")

		# Potential plots
		contour_with_labels(grid, 4, 1, NeAm_pot, "NeAm Potential  /  V")
		contour_with_labels(grid, 4, 2, Elyte_pot, "Electrolyte Potential  /  V")
		contour_with_labels(grid, 4, 3, PeAm_pot, "PeAm Potential  /  V")

		if new_window
			BattMo.independent_figure(fig)
		end

		return fig

	else
		error("Unsupported plot_type $plot_type. Use \"line\" or \"contour\".")
	end
end




end # module

module BattMoGLMakieExt

using BattMo, GLMakie


function BattMo.plot_output(output::NamedTuple, output_variables::Union{Vector{String}, Vector{Vector{String}}, Vector{Any}}; layout::Union{Nothing, Tuple{Int, Int}} = nothing)
	if !isdefined(Main, :GLMakie)
		error("GLMakie must be explicitly imported (e.g., with `using GLMakie`) before calling `plot_dashboard`.")
	end
	return BattMo.plot_impl(output, output_variables; layout = layout)
end

function BattMo.plot_impl(
	output::NamedTuple,
	variables::Union{Vector{String}, Vector{Any}, Vector{Any}};
	layout::Union{Nothing, Tuple{Int, Int}} = nothing,
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
	time_series_data = get_output_time_series(output)
	full_time = time_series_data[:Time]
	nt = length(full_time)
	available_time_vars = keys(time_series_data)

	# Get metadata for units
	meta_data = BattMo.get_output_variables_meta_data()

	# Helper: Parse variable string
	function parse_variable(varstr::String)
		base = match(r"^[^v]+", varstr) |> x -> strip(x.match)

		dims = occursin(r"vs", varstr) ? match(r"vs (.+?)(?: at|$)", varstr) |> x -> split(strip(x[1]), r" and ") : []

		selectors = Dict{Symbol, Union{Nothing, Int, Symbol}}()
		for cap in eachmatch(r"(\w+) index (\w+)", varstr)
			dim = Symbol(cap[1])
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
			if d == :Position || d == :NeAmRadius || d == :PeAmRadius
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

		ax = Axis(subgrid[1, 1])
		plotted_lines = false
		plot_type = nothing  # :line or :contour or nothing

		for varstr in var_group
			try
				parsed = parse_variable(varstr)
				clean_var = parsed.base
				dims = parsed.dims
				sel = parsed.selectors

				main_unit_str = get_main_unit_str(clean_var)

				# State variables and metrics
				states_data = get_output_states(output)
				metric_data = get_output_metrics(output)
				time_series = get_output_time_series(output)

				data = merge(states_data, metric_data, time_series)

				var_data = data[Symbol(clean_var)]

				rad_pe = data[:PeAmRadius] * 1e6
				rad_ne = data[:NeAmRadius] * 1e6
				pos = data[:Position] * 1e6
				nt = length(full_time)
				cycles = metric_data[:CycleNumber]

				known_dims = Dict(pairs(data))#Dict(:Time => full_time, :Position => pos, :NeAmRadius => rad_ne, :PeAmRadius => rad_pe, :CycleNumber)
				dim_lengths = Dict(:Time => nt, :Position => length(pos), :NeAmRadius => length(rad_ne), :PeAmRadius => length(rad_pe), :CycleNumber => length(cycles))
				sz = size(var_data)

				# Infer dimension assignments
				dim_assignments = Dict{Int, Symbol}()
				for (i, s) in enumerate(sz)
					for k in keys(data)
						v = data[k]
						if s == length(v) && !(k in values(dim_assignments)) && (k in Symbol.(dims) || haskey(sel, k))
							dim_assignments[i] = k
							break
						end
					end
				end

				if length(dim_assignments) != ndims(var_data)
					error("Could not assign all dimensions for variable $clean_var with size $(sz)")
				end

				plot_dims_syms = Symbol.(dims)
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

					lines!(ax, x_vals, vec(data_slice), label = label_with_suffix)
					ax.xlabel = x_label
					ax.ylabel = clean_var * main_unit_str
					# Set the title explicitly using title! function:
					ax.title = isempty(title_suffix) ? varstr : "$clean_var"
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

					co = contourf!(ax, x_vals, y_vals, z'; colormap = :viridis)

					ax.xlabel = x_label
					ax.ylabel = y_label
					Colorbar(subgrid[1, 2], co, label = "$main_unit_str")

					title_suffix = build_title_suffix(non_plot_dims, sel, known_dims)
					ax.title = isempty(title_suffix) ? varstr : "$clean_var$title_suffix"

				else
					error("More than 2 plot dimensions not supported: $dims")
				end

			catch e
				error("Failed to plot \"$varstr\": $(e.msg)")
			end
		end

		if plotted_lines
			axislegend(ax)
			# Clear title if multiple lines to avoid clutter, or you can customize
			if var_group isa Vector && length(var_group) > 1
				ax.title = ""
			end
		end
	end

	display(fig)
	return fig
end



function BattMo.plot_dashboard(output; plot_type = "simple")
	if !isdefined(Main, :GLMakie)
		error("GLMakie must be explicitly imported (e.g., with `using GLMakie`) before calling `plot_dashboard`.")
	end
	return BattMo.plot_dashboard_impl(output; plot_type = plot_type)
end

function BattMo.plot_dashboard_impl(output; plot_type = "simple")

	time_series = get_output_time_series(output; quantities = ["Time", "Voltage", "Current"])
	t = time_series[:Time]
	I = time_series[:Current]
	E = time_series[:Voltage]

	states = get_output_states(output)

	n_steps = length(t)
	x = states[:Position] * 10^6

	NeAm_conc = states[:NeAmSurfaceConcentration]
	PeAm_conc = states[:PeAmSurfaceConcentration]
	Elyte_conc = states[:ElectrolyteConcentration]

	NeAm_pot = states[:NeAmPotential]
	PeAm_pot = states[:PeAmPotential]
	Elyte_pot = states[:ElectrolytePotential]
	if plot_type == "simple"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Simple Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  s"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  s"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		return fig

	elseif plot_type == "line"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Line Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  s"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  s"
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

		function state_plot(ax, data, label)
			obs_data = Observable(data[1, :])
			plt = lines!(ax, x, obs_data, label = label; linewidth = 4)
			ax.xlabel = "Position  /  μm"
			on(ts) do i
				obs_data[] = data[i, :]
				autolimits!(ax)
			end
		end

		# Concentrations
		state_plot(Axis(grid[3, 1], title = "NeAm Surface Concentration  /  mol·m⁻³"), NeAm_conc, "NeAm Cs")
		state_plot(Axis(grid[3, 2], title = "Electrolyte Concentration  /  mol·m⁻³"), Elyte_conc, "Elyte C")
		state_plot(Axis(grid[3, 3], title = "PeAm Surface Concentration  /  mol·m⁻³"), PeAm_conc, "PeAm Cs")

		# Potentials
		state_plot(Axis(grid[4, 1], title = "NeAm Potential  /  V"), NeAm_pot, "NeAm ϕ")
		state_plot(Axis(grid[4, 2], title = "Electrolyte Potential  /  V"), Elyte_pot, "Elyte ϕ")
		state_plot(Axis(grid[4, 3], title = "PeAm Potential  /  V"), PeAm_pot, "PeAm ϕ")

		return fig

	elseif plot_type == "contour"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Contour Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "Time  /  s"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "Time  /  s"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		function contour_with_labels(parent_grid, row, col, data, title)
			subgrid = parent_grid[row, col] = GridLayout()

			ax = Axis(subgrid[1, 1])
			plt = contourf!(ax, x, t, data')
			ax.ylabel = "Time  /  s"
			ax.xlabel = "Position  / μm"
			ax.title = title

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
		return fig

	else
		error("Unsupported plot_type $plot_type. Use \"line\" or \"contour\".")
	end
end




end # module

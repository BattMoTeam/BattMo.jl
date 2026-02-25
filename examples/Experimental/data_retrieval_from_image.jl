using BattMo
using GLMakie
using FileIO
using Images
using DelimitedFiles
using Statistics

struct UserQuit <: Exception end

# Interactive plot-digitizer:
# 1) Click 2 x-calibration points with known x values.
# 2) Click 2 y-calibration points with known y values.
# 3) Click as many curve points as needed.
# Controls:
# - Left click: add point in current mode
# - Right click: remove last point in current mode
# - Key 1: switch to x-calibration mode
# - Key 2: switch to y-calibration mode
# - Key 3: switch to data mode
# - Key s: save CSV
# - Key q or Escape: close window

function affine_map(v, v0, v1, d0, d1)
	scale = (d1 - d0) / (v1 - v0)
	return d0 + (v - v0) * scale
end

function pixel_to_data(points, xpix, ypix, xvals, yvals)
	p0x, p1x = xpix
	p0y, p1y = ypix
	x0, x1 = xvals
	y0, y1 = yvals

	data_x = [affine_map(p[1], p0x[1], p1x[1], x0, x1) for p in points]
	data_y = [affine_map(p[2], p0y[2], p1y[2], y0, y1) for p in points]
	return data_x, data_y
end

function save_digitized_data(path, px_points, xpix, ypix, xvals, yvals)
	x_data, y_data = pixel_to_data(px_points, xpix, ypix, xvals, yvals)
	table = hcat(x_data, y_data)
	writedlm(path, table, ',')
	@info "Saved $(length(x_data)) points to $path"
end

function apply_rotation(img_raw, rotation::Symbol)
	if rotation == :none
		return img_raw
	elseif rotation == :left
		return rotl90(img_raw)
	elseif rotation == :right
		return rotr90(img_raw)
	elseif rotation == :flip
		return rot180(img_raw)
	else
		error("Unsupported rotation=$rotation. Use :none, :left, :right, or :flip.")
	end
end

function zoom_window_bounds(pos::Point2f, img, half_window::Int)
	xi = clamp(round(Int, pos[1]), 1, size(img, 2))
	yi = clamp(round(Int, pos[2]), 1, size(img, 1))
	xmin = max(1, xi - half_window)
	xmax = min(size(img, 2), xi + half_window)
	ymin = max(1, yi - half_window)
	ymax = min(size(img, 1), yi + half_window)
	return xmin, xmax, ymin, ymax
end

function color_at_point(img, pos::Point2f)
	x = clamp(round(Int, pos[1]), 1, size(img, 2))
	y = clamp(round(Int, pos[2]), 1, size(img, 1))
	c = RGB(img[y, x])
	return (Float64(c.r), Float64(c.g), Float64(c.b))
end

function robust_sample_color(img, pos::Point2f; radius::Int = 10)
	x0 = clamp(round(Int, pos[1]), 1, size(img, 2))
	y0 = clamp(round(Int, pos[2]), 1, size(img, 1))
	xmin = max(1, x0 - radius)
	xmax = min(size(img, 2), x0 + radius)
	ymin = max(1, y0 - radius)
	ymax = min(size(img, 1), y0 + radius)

	# Estimate local background color as channel-wise median in the neighborhood.
	rs = Float64[]
	gs = Float64[]
	bs = Float64[]
	for y in ymin:ymax, x in xmin:xmax
		c = RGB(img[y, x])
		push!(rs, Float64(c.r))
		push!(gs, Float64(c.g))
		push!(bs, Float64(c.b))
	end
	rbg = median(rs)
	gbg = median(gs)
	bbg = median(bs)

	# Pick the pixel most different from local background.
	best_d2 = -Inf
	best_rgb = color_at_point(img, pos)
	for y in ymin:ymax, x in xmin:xmax
		c = RGB(img[y, x])
		dr = Float64(c.r) - rbg
		dg = Float64(c.g) - gbg
		db = Float64(c.b) - bbg
		d2 = dr * dr + dg * dg + db * db
		if d2 > best_d2
			best_d2 = d2
			best_rgb = (Float64(c.r), Float64(c.g), Float64(c.b))
		end
	end
	return best_rgb
end

function connected_components(mask::BitMatrix; min_size::Int = 1)
	h, w = size(mask)
	labels = zeros(Int, h, w)
	visited = falses(h, w)
	components = NamedTuple[]
	label_id = 0

	neighbors = ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1))

	for y in 1:h
		for x in 1:w
			if !mask[y, x] || visited[y, x]
				continue
			end
			label_id += 1
			stack = Tuple{Int, Int}[(y, x)]
			visited[y, x] = true
			labels[y, x] = label_id
			component_pixels = Tuple{Int, Int}[]
			xsum = 0.0
			ysum = 0.0
			xmin = x
			xmax = x
			ymin = y
			ymax = y

			while !isempty(stack)
				cy, cx = pop!(stack)
				push!(component_pixels, (cy, cx))
				xsum += cx
				ysum += cy
				xmin = min(xmin, cx)
				xmax = max(xmax, cx)
				ymin = min(ymin, cy)
				ymax = max(ymax, cy)
				for (dy, dx) in neighbors
					ny = cy + dy
					nx = cx + dx
					if 1 <= ny <= h && 1 <= nx <= w && mask[ny, nx] && !visited[ny, nx]
						visited[ny, nx] = true
						labels[ny, nx] = label_id
						push!(stack, (ny, nx))
					end
				end
			end

			count = length(component_pixels)
			if count >= min_size
				push!(components, (
					id = label_id,
					pixels = component_pixels,
					count = count,
					xmin = xmin,
					xmax = xmax,
					ymin = ymin,
					ymax = ymax,
					width = xmax - xmin + 1,
					height = ymax - ymin + 1,
					fill = count / ((xmax - xmin + 1) * (ymax - ymin + 1)),
					cx = xsum / count,
					cy = ysum / count,
				))
			end
		end
	end
	return labels, components
end

function auto_extract_curve_points(
	img,
	sample_pos::Point2f;
	method::Symbol = :color,
	color_tol::Float64 = 0.12,
	min_pixels_per_col::Int = 1,
	plot_bounds::Union{Nothing, NTuple{4, Float64}} = nothing,
	guide_pos::Union{Nothing, Point2f} = nothing,
)
	h, w = size(img)
	r0, g0, b0 = robust_sample_color(img, sample_pos)
	tol2 = color_tol^2

	mask = falses(h, w)
	for y in 1:h
		for x in 1:w
			c = RGB(img[y, x])
			dr = Float64(c.r) - r0
			dg = Float64(c.g) - g0
			db = Float64(c.b) - b0
			mask[y, x] = dr * dr + dg * dg + db * db <= tol2
		end
	end

	labels, components_all = connected_components(mask; min_size = 2)
	if isempty(components_all)
		return Point2f[]
	end
	components_plot = components_all
	if plot_bounds !== nothing
		xmin_b, xmax_b, ymin_b, ymax_b = plot_bounds
		components_plot = filter(c -> xmin_b <= c.cx <= xmax_b && ymin_b <= c.cy <= ymax_b, components_all)
	end

	if method == :symbol_color
		sx = clamp(round(Int, sample_pos[1]), 1, w)
		sy = clamp(round(Int, sample_pos[2]), 1, h)
		sample_label = labels[sy, sx]

		if sample_label == 0
			# Click may not be exactly on the symbol pixel; use closest component centroid.
			best_d2 = Inf
			for c in components_all
				d2 = (c.cx - sx)^2 + (c.cy - sy)^2
				if d2 < best_d2
					best_d2 = d2
					sample_label = c.id
				end
			end
		end

		sample_comp = nothing
		for c in components_all
			if c.id == sample_label
				sample_comp = c
				break
			end
		end
		sample_comp === nothing && return Point2f[]
		isempty(components_plot) && return Point2f[]

		sample_area = sample_comp.count
		sample_aspect = sample_comp.width / max(sample_comp.height, 1)
		sample_fill = sample_comp.fill
		candidates = NamedTuple[]
		for c in components_plot
			area_ratio = c.count / max(sample_area, 1)
			aspect = c.width / max(c.height, 1)
			aspect_ratio = aspect / max(sample_aspect, eps())
			fill_diff = abs(c.fill - sample_fill)
			score = abs(log(max(area_ratio, eps()))) + abs(log(max(aspect_ratio, eps()))) + 2.0 * fill_diff
			if score <= 2.2
				push!(candidates, (c = c, score = score))
			end
		end

		if isempty(candidates)
			return Point2f[]
		end

		sort!(candidates; by = v -> v.score)
		keep_n = max(8, round(Int, 0.35 * length(candidates)))
		candidates = candidates[1:min(keep_n, length(candidates))]

			filtered = Point2f[]
			for v in candidates
				push!(filtered, Point2f(v.c.cx, v.c.cy))
			end

			if guide_pos !== nothing
				# Keep candidates near the guide component family in y.
				gy = guide_pos[2]
				y_span = max(20.0, 0.35 * (maximum(p -> p[2], filtered) - minimum(p -> p[2], filtered) + 1.0))
				filtered = [p for p in filtered if abs(p[2] - gy) <= y_span]
				isempty(filtered) && return Point2f[]

				sort!(filtered; by = p -> p[1])
				dxs = Float64[]
				for i in 2:length(filtered)
					dx = filtered[i][1] - filtered[i - 1][1]
					dx > 0 && push!(dxs, dx)
				end
				max_dx = isempty(dxs) ? 40.0 : clamp(3.0 * median(dxs), 8.0, 70.0)
				max_dy = max(14.0, 0.22 * y_span)
				traced = trace_curve_from_guide(filtered, guide_pos; max_dx = max_dx, max_dy = max_dy)
				if length(traced) >= max(4, floor(Int, 0.25 * length(filtered)))
					filtered = traced
				end
			end

			sort!(filtered; by = p -> (p[1], p[2]))
			return filtered
	else
		# Color-only extraction: follow the largest connected color component.
		isempty(components_plot) && return Point2f[]
		best = if guide_pos === nothing
			components_plot[argmax(map(c -> c.count, components_plot))]
		else
			gx = guide_pos[1]
			gy = guide_pos[2]
			components_plot[argmin(map(c -> (c.cx - gx)^2 + (c.cy - gy)^2, components_plot))]
		end
		colmap = Dict{Int, Vector{Int}}()
		for (py, px) in best.pixels
			ys = get!(colmap, px, Int[])
			push!(ys, py)
		end

		points = Point2f[]
		for x in sort(collect(keys(colmap)))
			ys = colmap[x]
			if length(ys) >= min_pixels_per_col
				push!(points, Point2f(x, median(ys)))
			end
		end
		return points
	end
end

function trace_curve_from_guide(points::Vector{Point2f}, guide_pos::Point2f; max_dx::Float64 = 40.0, max_dy::Float64 = 22.0)
	isempty(points) && return Point2f[]
	n = length(points)
	seed = argmin(((p[1] - guide_pos[1])^2 + (p[2] - guide_pos[2])^2 for p in points))
	selected = falses(n)
	selected[seed] = true

	function walk!(direction::Symbol)
		current = seed
		while true
			best = 0
			best_cost = Inf
			cx = points[current][1]
			cy = points[current][2]
			for i in 1:n
				selected[i] && continue
				dx = points[i][1] - cx
				if direction == :right && dx <= 0
					continue
				elseif direction == :left && dx >= 0
					continue
				end
				adx = abs(dx)
				ady = abs(points[i][2] - cy)
				if adx > max_dx || ady > max_dy
					continue
				end
				cost = adx + 1.8 * ady
				if cost < best_cost
					best_cost = cost
					best = i
				end
			end
			if best == 0
				break
			end
			selected[best] = true
			current = best
		end
	end

	walk!(:left)
	walk!(:right)
	out = Point2f[]
	for i in 1:n
		selected[i] && push!(out, points[i])
	end
	sort!(out; by = p -> p[1])
	return out
end

function calibrated_plot_bounds(xcal::Vector{Point2f}, ycal::Vector{Point2f}; pad::Float64 = 10.0)
	xmin = min(xcal[1][1], xcal[2][1]) - pad
	xmax = max(xcal[1][1], xcal[2][1]) + pad
	ymin = min(ycal[1][2], ycal[2][2]) - pad
	ymax = max(ycal[1][2], ycal[2][2]) + pad
	return (Float64(xmin), Float64(xmax), Float64(ymin), Float64(ymax))
end

function close_digitizer_window!(fig, screen_ref::Base.RefValue{Any})
	if screen_ref[] !== nothing
		try
			close(screen_ref[])
			return
		catch
		end
	end
	try
		GLMakie.destroy!(fig)
	catch
		@warn "Could not close digitizer window cleanly."
	end
end

function axis_mouseposition_clamped(ax, img)
	p = Point2f(mouseposition(ax))
	x = clamp(p[1], 1, size(img, 2))
	y = clamp(p[2], 1, size(img, 1))
	return Point2f(x, y)
end

function digitize_plot_image(;
	image_file::AbstractString,
	output_file::AbstractString,
	x_cal_values::Tuple{<:Real, <:Real},
	y_cal_values::Tuple{<:Real, <:Real},
	rotation::Symbol = :right,
	figsize::Tuple{Int, Int} = (900, 700),
	auto_advance::Bool = true,
	enable_zoom_preview::Bool = true,
	zoom_half_window::Int = 20,
)
	img_raw = load(image_file)
	img = apply_rotation(img_raw, rotation)

	fig = Figure(size = figsize)
	screen_ref = Ref{Any}(nothing)
	ax = GLMakie.Axis(fig[1, 1], title = "Image digitizer")
	ax_zoom = GLMakie.Axis(fig[1, 2], title = "Zoom", yreversed = ax.yreversed[])
	colsize!(fig.layout, 1, Relative(0.78))
	colsize!(fig.layout, 2, Relative(0.22))
	image!(ax, 1 .. size(img, 2), 1 .. size(img, 1), img)

	mode = Observable(:xcal)
	xcal = Observable(Point2f[])
	ycal = Observable(Point2f[])
	pixel_points = Observable(Point2f[])
	auto_preview_points = Observable(Point2f[])
	mouse_pos = Observable(Point2f(1, 1))
	sample_pos = Observable(Point2f[])
	guide_pos = Observable(Point2f[])

	scatter!(ax, xcal; marker = :rect, color = :orange, markersize = 16, label = "x calibration")
	scatter!(ax, ycal; marker = :utriangle, color = :cyan, markersize = 16, label = "y calibration")
	scatter!(ax, pixel_points; marker = :x, color = :red, markersize = 14, label = "curve points")
	scatter!(ax, auto_preview_points; marker = :circle, color = (:deepskyblue, 0.55), markersize = 8, strokecolor = :black, strokewidth = 1, label = "auto preview")
	scatter!(ax, sample_pos; marker = :circle, color = :gold, markersize = 12, strokecolor = :black, strokewidth = 2, label = "auto sample")
	scatter!(ax, guide_pos; marker = :diamond, color = :limegreen, markersize = 12, strokecolor = :black, strokewidth = 2, label = "auto guide")
	axislegend(ax; position = :rb)
	image!(ax_zoom, 1 .. size(img, 2), 1 .. size(img, 1), img)
	scatter!(
		ax_zoom,
		mouse_pos;
		marker = :circle,
		markersize = 10,
		color = :yellow,
		strokecolor = :black,
		strokewidth = 2,
	)
	hidedecorations!(ax_zoom)
	hidespines!(ax_zoom)
	xmin0, xmax0, ymin0, ymax0 = zoom_window_bounds(mouse_pos[], img, zoom_half_window)
	xlims!(ax_zoom, xmin0, xmax0)
	ylims!(ax_zoom, ymin0, ymax0)

	@info "Click two x-calibration points. Known x values: $(x_cal_values)."
	@info "Then click two y-calibration points. Known y values: $(y_cal_values)."
	@info "Then click curve points. Press s to save."

	on(events(fig).mouseposition) do _
		mouse_pos[] = axis_mouseposition_clamped(ax, img)
		if enable_zoom_preview
			xmin, xmax, ymin, ymax = zoom_window_bounds(mouse_pos[], img, zoom_half_window)
			xlims!(ax_zoom, xmin, xmax)
			ylims!(ax_zoom, ymin, ymax)
		end
	end

	on(events(fig).mousebutton) do ev
		if ev.action != Mouse.press
			return
		end
		pos = mouse_pos[]

		if ev.button == Mouse.left
			if mode[] == :xcal
				push!(xcal[], pos)
				notify(xcal)
				@info "x-calibration point $(length(xcal[])): $pos"
				if auto_advance && length(xcal[]) == 2
					mode[] = :ycal
					@info "x-calibration complete. Click two y-calibration points."
				end
			elseif mode[] == :ycal
				push!(ycal[], pos)
				notify(ycal)
				@info "y-calibration point $(length(ycal[])): $pos"
				if auto_advance && length(ycal[]) == 2
					mode[] = :data
					@info "y-calibration complete. Now click curve points."
				end
				elseif mode[] == :sample
					sample_pos[] = Point2f[pos]
					notify(sample_pos)
					@info "Auto-sample point: $pos"
				elseif mode[] == :guide
					guide_pos[] = Point2f[pos]
					notify(guide_pos)
					@info "Auto-guide point: $pos"
				else
				push!(pixel_points[], pos)
				notify(pixel_points)
				@info "curve point $(length(pixel_points[])): $pos"
			end
		elseif ev.button == Mouse.right
			if mode[] == :xcal && !isempty(xcal[])
				pop!(xcal[])
				notify(xcal)
			elseif mode[] == :ycal && !isempty(ycal[])
				pop!(ycal[])
				notify(ycal)
			elseif mode[] == :data && !isempty(pixel_points[])
				pop!(pixel_points[])
				notify(pixel_points)
				elseif mode[] == :sample && !isempty(sample_pos[])
					empty!(sample_pos[])
					notify(sample_pos)
				elseif mode[] == :guide && !isempty(guide_pos[])
					empty!(guide_pos[])
					notify(guide_pos)
				end
		else
			return
		end
	end

	on(events(fig).keyboardbutton) do ev
		if ev.action != Keyboard.press
			return
		end
		if ev.key == Keyboard._1
			mode[] = :xcal
			@info "Mode: x-calibration"
		elseif ev.key == Keyboard._2
			mode[] = :ycal
			@info "Mode: y-calibration"
		elseif ev.key == Keyboard._3
			mode[] = :data
			@info "Mode: data"
			elseif ev.key == Keyboard._4
				mode[] = :sample
				@info "Mode: auto sample"
			elseif ev.key == Keyboard._5
				mode[] = :guide
				@info "Mode: auto guide"
		elseif ev.key == Keyboard.s
			if length(xcal[]) != 2 || length(ycal[]) != 2
				@warn "Need exactly 2 x-calibration and 2 y-calibration points before saving."
			elseif isempty(pixel_points[])
				@warn "No curve points to save."
			else
				save_digitized_data(
					output_file,
					pixel_points[],
					xcal[],
					ycal[],
					x_cal_values,
					y_cal_values,
				)
			end
		elseif ev.key == Keyboard.q || ev.key == Keyboard.escape
			close_digitizer_window!(fig, screen_ref)
		else
			return
		end
	end

	screen_ref[] = display(fig)
	return (
		fig = fig,
		screen_ref = screen_ref,
		mode = mode,
		xcal = xcal,
		ycal = ycal,
		pixel_points = pixel_points,
		auto_preview_points = auto_preview_points,
		sample_pos = sample_pos,
		guide_pos = guide_pos,
		img = img,
		output_file = output_file,
		x_cal_values = x_cal_values,
		y_cal_values = y_cal_values,
	)
end

function prompt_with_default(prompt::AbstractString, default::AbstractString)
	print("$prompt [$default]: ")
	input = strip(readline())
	lower = lowercase(input)
	lower in ("q", "quit", "exit") && throw(UserQuit())
	return isempty(input) ? default : input
end

function prompt_continue(prompt::AbstractString = "Finished with this step? [y/n]:")
	while true
		print("$prompt ")
		input = lowercase(strip(readline()))
		if input in ("q", "quit", "exit")
			throw(UserQuit())
		end
		if input in ("y", "yes")
			return true
		elseif input in ("n", "no", "")
			return false
		else
			println("Please answer y or n.")
		end
	end
end

function wait_for_points(stage_name::AbstractString, points_obs::Observable{Vector{Point2f}}, required::Int)
	while true
		done = prompt_continue("[$stage_name] You currently have $(length(points_obs[])) point(s). Finished with this step? [y/n]:")
		if !done
			continue
		end
		if length(points_obs[]) < required
			println("[$stage_name] Need at least $required points before finishing.")
			continue
		end
		break
	end
	println("[$stage_name] Collected $(length(points_obs[])) points.")
end

function prompt_tuple(prompt::AbstractString, default::Tuple{<:Real, <:Real})
	print("$prompt ($(default[1]), $(default[2])): ")
	input = strip(readline())
	lower = lowercase(input)
	lower in ("q", "quit", "exit") && throw(UserQuit())
	if isempty(input)
		return (Float64(default[1]), Float64(default[2]))
	end
	parts = split(input, ',')
	length(parts) == 2 || error("Please provide exactly two comma-separated values.")
	return (parse(Float64, strip(parts[1])), parse(Float64, strip(parts[2])))
end

function prompt_rotation(default::Symbol)
	print("Rotation (:none, :left, :right, :flip) [$default]: ")
	input = strip(readline())
	lower = lowercase(input)
	lower in ("q", "quit", "exit") && throw(UserQuit())
	if isempty(input)
		return default
	end
	rot = Symbol(lower)
	rot in (:none, :left, :right, :flip) || error("Rotation must be :none, :left, :right, or :flip.")
	return rot
end

function prompt_choice(prompt::AbstractString, options::Vector{String}, default::String)
	allowed = Set(lowercase.(options))
	while true
		print("$prompt [$(join(options, '/')) | default=$default]: ")
		input = lowercase(strip(readline()))
		if input in ("q", "quit", "exit")
			throw(UserQuit())
		end
		if isempty(input)
			return lowercase(default)
		end
		if input in allowed
			return input
		end
		println("Please choose one of: $(join(options, ", "))")
	end
end

function prompt_float(prompt::AbstractString, default::Float64; minval::Float64 = -Inf, maxval::Float64 = Inf)
	while true
		input = prompt_with_default(prompt, string(default))
		value = try
			parse(Float64, input)
		catch
			NaN
		end
		if isfinite(value) && minval <= value <= maxval
			return value
		end
		println("Please enter a numeric value in [$minval, $maxval].")
	end
end

function wait_for_single_point(stage_name::AbstractString, point_obs::Observable{Vector{Point2f}}; label::AbstractString = "point")
	while true
		done = prompt_continue("[$stage_name] Click one $label in the figure. Finished? [y/n]:")
		if !done
			continue
		end
		if isempty(point_obs[])
			println("[$stage_name] No $label selected yet.")
			continue
		end
		break
	end
	return point_obs[][1]
end

function prompt_yes_no(prompt::AbstractString; default::Bool = false)
	default_label = default ? "y" : "n"
	while true
		print("$prompt [y/n, default=$default_label]: ")
		input = lowercase(strip(readline()))
		if input in ("q", "quit", "exit")
			throw(UserQuit())
		end
		if isempty(input)
			return default
		elseif input in ("y", "yes")
			return true
		elseif input in ("n", "no")
			return false
		end
		println("Please answer y or n.")
	end
end

function run_digitizer_cli()
	session = nothing
	battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
	default_image = joinpath(battmo_base, "examples", "Experimental", "resources", "bolay_experimental_discharge.png")
	default_output = joinpath(battmo_base, "examples", "Experimental", "resources", "bolay_experimental_discharge_digitized.csv")
	default_xcal = (0.0, 2.0)
	default_ycal = (3.0, 4.0)
	default_rotation = :right
	default_mode = "manual"
	default_auto_tol = "0.12"

	println("Interactive setup for plot digitization")
	println("Press Enter to accept defaults. Type q/quit/exit to cancel.")
	image_file = prompt_with_default("Image file", default_image)
	output_file = prompt_with_default("Output CSV", default_output)
	x_cal_values = prompt_tuple("x calibration values (x1,x2)", default_xcal)
	y_cal_values = prompt_tuple("y calibration values (y1,y2)", default_ycal)
	rotation = prompt_rotation(default_rotation)
	workflow_mode = prompt_choice("Point creation mode", ["manual", "auto"], default_mode)

	auto_from_legend = false
	auto_color_tol = 0.12
	if workflow_mode == "auto"
		auto_from_legend = prompt_choice(
			"Does the plot have a legend symbol for the target curve?",
			["yes", "no"],
			"yes",
		) == "yes"
		auto_color_tol = prompt_float("Auto-detect color tolerance (0.01-0.5)", parse(Float64, default_auto_tol); minval = 0.01, maxval = 0.5)
	end

	println("\nLaunching GUI digitizer with your settings...")
	println("Mouse controls: left click add, right click undo. Keyboard: 1/2/3/4/5 modes, q quit.")
	println("Zoom panel: right side shows a magnified area around the cursor.")
	session = digitize_plot_image(
		image_file = image_file,
		output_file = output_file,
		x_cal_values = x_cal_values,
		y_cal_values = y_cal_values,
		rotation = rotation,
		auto_advance = false,
	)

	session.mode[] = :xcal
	println("\nStep 1: x-calibration")
	println("Click two x-axis points in the figure.")
	wait_for_points("x-calibration", session.xcal, 2)

	session.mode[] = :ycal
	println("\nStep 2: y-calibration")
	println("Click two y-axis points in the figure.")
	wait_for_points("y-calibration", session.ycal, 2)

	session.mode[] = :data
	println("\nStep 3: data points")
	if workflow_mode == "auto"
		while true
			empty!(session.sample_pos[])
			notify(session.sample_pos)
			empty!(session.guide_pos[])
			notify(session.guide_pos)
			empty!(session.auto_preview_points[])
			notify(session.auto_preview_points)
			session.mode[] = :sample
			if auto_from_legend
				println("Auto mode: click the target curve symbol in the legend.")
			else
				println("Auto mode: click one representative point on the target curve.")
			end
			sample = wait_for_single_point("auto-sample", session.sample_pos; label = "sample point")
			guide = nothing
			if auto_from_legend
				session.mode[] = :guide
				println("Auto mode: click one point on the target curve (guide point).")
				guide = wait_for_single_point("auto-guide", session.guide_pos; label = "guide point")
			end
			auto_method = auto_from_legend ? :symbol_color : :color
			println("Auto extraction mode: $(auto_method)")
			bounds = calibrated_plot_bounds(session.xcal[], session.ycal[]; pad = 12.0)
			auto_points = auto_extract_curve_points(
				session.img,
				sample;
				method = auto_method,
				color_tol = auto_color_tol,
				plot_bounds = bounds,
				guide_pos = guide,
			)
			if isempty(auto_points) && auto_method == :symbol_color
				println("No points found with symbol+color. Retrying with color-only.")
				auto_points = auto_extract_curve_points(
					session.img,
					sample;
					method = :color,
					color_tol = auto_color_tol,
					plot_bounds = bounds,
					guide_pos = guide,
				)
			end
			if isempty(auto_points)
				println("Auto mode found no points.")
				empty!(session.auto_preview_points[])
				notify(session.auto_preview_points)
			else
				session.auto_preview_points[] = auto_points
				notify(session.auto_preview_points)
				session.pixel_points[] = auto_points
				notify(session.pixel_points)
				println("Auto mode generated $(length(auto_points)) points (shown as blue preview + red editable points).")
			end
			if !prompt_yes_no("Redo target curve selection and regenerate auto points?"; default = false)
				break
			end
		end
		session.mode[] = :data
		println("You can now refine points manually (left add, right remove).")
	else
		empty!(session.auto_preview_points[])
		notify(session.auto_preview_points)
		println("Click curve points in the figure.")
	end
	while true
		done = prompt_continue("[data] You currently have $(length(session.pixel_points[])) point(s). Finished with this step? [y/n]:")
		if !done
			continue
		end
		if isempty(session.pixel_points[])
			println("[data] Select at least one data point before finishing.")
			continue
		end
		break
	end

	save_digitized_data(
		session.output_file,
		session.pixel_points[],
		session.xcal[],
		session.ycal[],
		session.x_cal_values,
		session.y_cal_values,
	)
	println("Saved digitized data to: $(session.output_file)")
	while !prompt_continue("Close figure now? [y/n]:")
	end
	close_digitizer_window!(session.fig, session.screen_ref)
	return session
end

function run_digitizer_cli_safe()
	try
		return run_digitizer_cli()
	catch e
		if e isa UserQuit || e isa InterruptException
			println("\nDigitizer cancelled by user.")
			return nothing
		end
		rethrow(e)
	end
end


run_digitizer_cli_safe()

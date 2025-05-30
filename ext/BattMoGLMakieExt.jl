module BattMoGLMakieExt

using BattMo
using GLMakie

function BattMo.plot_dashboard(output::NamedTuple; plot_type = "line")
	BattMo.check_plotting_availability()
	return BattMo.plot_dashboard_impl(output; plot_type = plot_type)
end

function BattMo.plot_dashboard_impl(output::NamedTuple; plot_type = "line")

	time_series = get_output_time_series(output, ["Voltage", "Current"])
	t = time_series[:Time]
	I = time_series[:Current]
	E = time_series[:Voltage]

	states = get_output_states(output, ["NeAmSurfaceConcentration", "PeAmSurfaceConcentration", "ElectrolyteConcentration",
		"NeAmPotential", "PeAmPotential", "ElectrolytePotential"])

	n_steps = length(t)
	x = states[:x] * 10^6

	NeAm_conc = states[:NeAmSurfaceConcentration]
	PeAm_conc = states[:PeAmSurfaceConcentration]
	Elyte_conc = states[:ElectrolyteConcentration]

	NeAm_pot = states[:NeAmPotential]
	PeAm_pot = states[:PeAmPotential]
	Elyte_pot = states[:ElectrolytePotential]

	if plot_type == "line"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Line Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "t  /  s"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "t  /  s"
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
			ax.xlabel = "x  /  μm"
			on(ts) do i
				obs_data[] = data[i, :]
				autolimits!(ax)
			end
		end

		# Concentrations
		state_plot(Axis(grid[3, 1], title = "NeAm Surface Concentration  /  mol·L⁻¹"), NeAm_conc, "NeAm Cs")
		state_plot(Axis(grid[3, 2], title = "Electrolyte Concentration  /  mol·L⁻¹"), Elyte_conc, "Elyte C")
		state_plot(Axis(grid[3, 3], title = "PeAm Surface Concentration  /  mol·L⁻¹"), PeAm_conc, "PeAm Cs")

		# Potentials
		state_plot(Axis(grid[4, 1], title = "NeAm Potential  /  V"), NeAm_pot, "NeAm ϕ")
		state_plot(Axis(grid[4, 2], title = "Electrolyte Potential  /  V"), Elyte_pot, "Elyte ϕ")
		state_plot(Axis(grid[4, 3], title = "PeAm Potential  /  V"), PeAm_pot, "PeAm ϕ")

		display(fig)
		return fig

	elseif plot_type == "contour"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Contour Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		ax_current.xlabel = "t  /  s"
		scatterlines!(ax_current, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		ax_voltage.xlabel = "t  /  s"
		scatterlines!(ax_voltage, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

		function contour_with_labels(ax, data, title)
			contourf!(ax, t, x, data)
			ax.xlabel = "Time  /  s"
			ax.ylabel = "x  / μm"
			ax.title = title
		end

		# Concentration plots
		contour_with_labels(Axis(grid[3, 1]), NeAm_conc, "NeAm Surface Concentration  /  mol·L⁻¹")
		contour_with_labels(Axis(grid[3, 2]), Elyte_conc, "Electrolyte Concentration  /  mol·L⁻¹")
		contour_with_labels(Axis(grid[3, 3]), PeAm_conc, "PeAm Surface Concentration  /  mol·L⁻¹")

		# Potential plots
		contour_with_labels(Axis(grid[4, 1]), NeAm_pot, "NeAm Potential  /  V")
		contour_with_labels(Axis(grid[4, 2]), Elyte_pot, "Electrolyte Potential  /  V")
		contour_with_labels(Axis(grid[4, 3]), PeAm_pot, "PeAm Potential  /  V")

		display(fig)
		return fig

	else
		error("Unsupported plot_type. Use \"line\" or \"contour\".")
	end
end


function BattMo.check_plotting_availability(; throw = true)
	ok = true
	try
		ok = BattMo.check_plotting_availability_impl()
	catch e
		if throw
			if e isa MethodError
				error("Plotting is not available. You need to have a Makie backend available. For 3D plots, GLMakie is recommended. To fix: using Pkg; Pkg.add(\"GLMakie\") and then call using GLMakie to enable plotting.")
			else
				rethrow(e)
			end
		else
			ok = false
		end
	end
	return ok
end

function BattMo.check_plotting_availability_impl()
	return true
end



end # module

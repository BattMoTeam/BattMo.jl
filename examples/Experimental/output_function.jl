using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
model_settings = load_model_settings(; from_default_set = "P2D")

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim;)

time_series = get_output_time_series(output, ["Voltage", "Current"])
states = get_output_states(output, ["PeAmPotential", "NeAmPotential", "ElectrolytePotential", "PeAmSurfaceConcentration", "NeAmSurfaceConcentration", "ElectrolyteConcentration"])
metrics = get_output_metrics(output, ["DischargeEnergy", "DischargeCapacity"])

t = time_series[:Time]
I = time_series[:Current]
E = time_series[:Voltage]

using GLMakie

NeAmC_t10 = states[:NeAmSurfaceConcentration][10,:,1]
PeAmCSurf_t10 = states[:PeAmSurfaceConcentration][10,:]
ElyteC_t10 = states[:ElectrolyteConcentration][10,:]

f = Figure()
ax = Axis(f[1, 1], title = "Concentrations", xlabel = "Distance [m]", ylabel = "Concentration")
lines!(ax, states.x, NeAmC_t10, color = :red, linewidth = 2, label = "NeAm Surface Conc")
lines!(ax, states.x, PeAmCSurf_t10, color = :blue, linewidth = 2, label = "PeAm Surface Conc")
lines!(ax, states.x, ElyteC_t10, color = :green, linewidth = 2, label = "Elyte Conc")
axislegend(ax, position = :rt, valign = :center)

display(f)






function plot_dashboard(output::NamedTuple; plot_type = "line")

	time_series = get_output_time_series(output, ["Voltage", "Current"])
	t = time_series[:Time]
	I = time_series[:Current]
	E = time_series[:Voltage]

	states = output[:states]
	n_steps = length(states)

	function stack_states(key1, key2)
		return hcat([state[Symbol(key1)][Symbol(key2)] for state in states]...)'
	end

	NeAm_conc = stack_states("NeAm", "Cs")
	PeAm_conc = stack_states("PeAm", "Cs")
	Elyte_conc = stack_states("Elyte", "C")

	NeAm_pot = stack_states("NeAm", "Phi")
	PeAm_pot = stack_states("PeAm", "Phi")
	Elyte_pot = stack_states("Elyte", "Phi")

	if plot_type == "line"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		# Title row
		title_label = Label(grid[0, 1:3], "Line Dashboard", fontsize = 24, halign = :center)

		# Current plot (full width)
		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		lines!(ax_current, t, I, color = :red)

		# Voltage plot (full width)
		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		lines!(ax_voltage, t, E, color = :blue)

		# Slider
		slider = Slider(grid[6, 1:3], range = 1:n_steps, startvalue = 1)
		ts = slider.value

		# Interactive helper
		function state_plot(ax, data, label)
			obs_data = Observable(data[1, :])
			lines!(ax, obs_data, label = label)
			on(ts) do i
				obs_data[] = data[i, :]
				autolimits!(ax)
			end
		end

		# Concentrations
		ax_c1 = Axis(grid[3, 1], title = "NeAm Concentration  /  mol·L⁻¹")
		ax_c2 = Axis(grid[3, 2], title = "Elyte Concentration  /  mol·L⁻¹")
		ax_c3 = Axis(grid[3, 3], title = "PeAm Concentration  /  mol·L⁻¹")
		state_plot(ax_c1, NeAm_conc, "NeAm Cs")
		state_plot(ax_c2, Elyte_conc, "Elyte C")
		state_plot(ax_c3, PeAm_conc, "PeAm Cs")

		# Potentials
		ax_p1 = Axis(grid[4, 1], title = "NeAm Potential  /  V")
		ax_p2 = Axis(grid[4, 2], title = "Elyte Potential  /  V")
		ax_p3 = Axis(grid[4, 3], title = "PeAm Potential  /  V")
		state_plot(ax_p1, NeAm_pot, "NeAm ϕ")
		state_plot(ax_p2, Elyte_pot, "Elyte ϕ")
		state_plot(ax_p3, PeAm_pot, "PeAm ϕ")

		fig

	elseif plot_type == "contour"
		fig = Figure(size = (1200, 1000))
		grid = fig[1, 1] = GridLayout()

		Label(grid[0, 1:3], "Battery Contour Dashboard", fontsize = 24, halign = :center)

		ax_current = Axis(grid[1, 1:3], title = "Current  /  A")
		lines!(ax_current, t, I, color = :red)

		ax_voltage = Axis(grid[2, 1:3], title = "Voltage  /  V")
		lines!(ax_voltage, t, E, color = :blue)

		xs = range(0, 1, length = size(NeAm_conc, 2))  # Thickness axis

		ax_c1 = Axis(grid[3, 1], title = "NeAm Concentration  /  mol·L⁻¹")
		contourf!(ax_c1, xs, t, NeAm_conc)
		ax_c2 = Axis(grid[3, 2], title = "Elyte Concentration  /  mol·L⁻¹")
		contourf!(ax_c2, xs, t, Elyte_conc)
		ax_c3 = Axis(grid[3, 3], title = "PeAm Concentration  /  mol·L⁻¹")
		contourf!(ax_c3, xs, t, PeAm_conc)

		ax_p1 = Axis(grid[4, 1], title = "NeAm Potential  /  V")
		contourf!(ax_p1, xs, t, NeAm_pot)
		ax_p2 = Axis(grid[4, 2], title = "Elyte Potential  /  V")
		contourf!(ax_p2, xs, t, Elyte_pot)
		ax_p3 = Axis(grid[4, 3], title = "PeAm Potential  /  V")
		contourf!(ax_p3, xs, t, PeAm_pot)

		fig
	else
		error("Unsupported plot_type. Use \"line\" or \"contour\".")
	end
end


plot_dashboard(output; plot_type = "line")


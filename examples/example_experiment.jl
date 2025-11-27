using BattMo, GLMakie, Jutul

cycling_protocol = CyclingProtocol(
	Dict(
		"Protocol" => "Experiment",
		"TotalTime" => 18000000,
		"InitialStateOfCharge" => 0.01,
		"Experiment" =>
			[
				"Rest for 1 hour",
				# "Charge at 1 W for 800 s",
				# "Charge at 1/20 C until 4.0 V",
				# "Hold at 4.0 V until 0.1 mA change",
				# "Discharge at 1/2 C until 3.0 V",
				# "Rest until 1e-4 V change",
			],
	),
)

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
simulation_settings["RampUpTime"] = 100

model_setup = LithiumIonBattery()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)


struct RampUpTimestepSelector <: Jutul.AbstractTimestepSelector
	init_rel::Any
	init_abs::Any
	decrease::Any
	increase::Any
	max::Any
	min::Any
	function RampUpTimestepSelector(factor = Inf; increase = 2.0, decrease = 2.0, initial_relative = 1.0, initial_absolute = Inf, max = 500, min = 1.0)
		if isnothing(decrease)
			decrease = factor
		end
		new(initial_relative, initial_absolute, decrease, increase, max, min)
	end
end

function Jutul.pick_cut_timestep(sel::RampUpTimestepSelector, sim, config, dt, dT, forces, reports, cut_count)
	df = sel.decrease
	if dt > 10
		dt = 10
	end
	max_cuts = config[:max_timestep_cuts]
	if cut_count + 1 > max_cuts && dt <= 1.0
		dt = NaN
	else
		dt = dt/df
	end
	@info "dt =", dt
	@info "dT =", dT
	return dt
end


"""
	pick_next_timestep(sel::IterationTimestepSelector, sim, config, dt_prev, dT, forces, reports, current_reports, step_index, new_step)

Pick the next time-step for `IterationTimestepSelector`. This function uses the
number of iterations from previous timesteps to estimate the relationship
between the last and the new time step.
"""

function Jutul.pick_next_timestep(sel::RampUpTimestepSelector, sim, config, dt_prev, dT, forces, reports, current_reports, step_index, new_step)
	# If this is the first step or ramp-up phase
	@info "step_index", step_index
	if new_step && step_index == 1
		return sel.min  # Start from minimum
	end

	# Collect successful reports
	R = Jutul.successful_reports(reports, current_reports, step_index, 2)
	if length(R) == 0
		# If no previous success, ramp up from min
		@info "no succes"
		return min(min(dt_prev * sel.increase, sel.min), sel.max)
	end

	# r = R[end]
	# its_t, ϵ = sel.target, sel.offset

	# # Previous number of iterations
	# its_p = haskey(r, :stats) ? r[:stats].newtons : length(r[:steps]) - 1

	# if length(R) > 1
	# 	r0 = R[end-1]
	# 	its_p0 = haskey(r0, :stats) ? r0[:stats].newtons : length(r0[:steps]) - 1
	# 	dt0 = r0[:dt]
	# else
	# 	its_p0, dt0 = its_p, dt_prev
	# end

	# # Use iteration-based adjustment
	# dt_new = linear_timestep_selection(its_t + ϵ, its_p0 + ϵ, its_p + ϵ, dt0, dt_prev)
	@info "dt_prev", dt_prev


	# Apply ramp-up limit
	return dt_prev
end


output = solve(sim; accept_invalid = true, info_level = 2, max_timestep_cuts = 20, timestep_selectors = [RampUpTimestepSelector(
# initial_relative = 1e-3,
# initial_absolute = 1e-6,
)])

plot_dashboard(output)

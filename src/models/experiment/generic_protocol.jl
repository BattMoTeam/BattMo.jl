#######################################################################################################################
# Protocols
#
# A protocol is an implementation of a certain policy or a combination of policies.
#
# This script defines cycling protocol types:
#	- GenericProtocol: a protocol that can contain any combination and order of control steps
#
# The generic protocol is the single control framework of BattMo. Its basis is the json control step structure,
# described by the control step schema (see get_schema_control_steps). Every cycling protocol ("CC", "CCCV",
# "Function", "InputCurrentSeries", "Experiment" and "Generic") is first converted to control steps (see
# protocol_conversion.jl). The control steps are validated against the schema, the "Cycle" steps are unfolded, and
# each step is then turned into an AbstractControlStep instance.
#######################################################################################################################



"""
GenericProtocol
"""
struct GenericProtocol{V, R} <: AbstractPolicy where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	cycle_counts::V
	final_cycle_count::Int  # cycle count once the last control step has terminated
	maximum_current::R      # used to limit the Newton updates of the current, zero if unknown
	rated_capacity::R
	initial_state_of_charge::R
end


"""
	GenericProtocol(cycling_protocol, input; capacity = nothing, T = Float64)

Set up the generic protocol from a cycling protocol. The capacity (in Ah) is used for the C-rates and the state of
charge. A "Capacity" given in the cycling protocol takes precedence. If no capacity is given, the theoretical cell
capacity is computed from the cell parameters.
"""
function GenericProtocol(cycling_protocol::CyclingProtocol, input; capacity = nothing, T = Float64)

	# The CCCV protocol has never used a current ramp up, and we keep it like that so that the results are unchanged
	use_ramp_up = haskey(input.model_settings, "RampUp") && cycling_protocol["Protocol"] != "CCCV"

	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 100

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	elseif isnothing(capacity)
		capacity = compute_cell_theoretical_capacity(input.cell_parameters)
	end

	control_steps = get_control_steps(cycling_protocol)

	return GenericProtocol(control_steps, cycling_protocol["InitialStateOfCharge"];
		capacity = capacity, use_ramp_up = use_ramp_up, ramp_up_time = ramp_up_time, T = T)
end


"""
	GenericProtocol(control_steps, initial_state_of_charge; capacity, use_ramp_up = true, ramp_up_time = 100, T = Float64)

Set up the generic protocol from a list of control steps following the control step schema. The capacity (in Ah) is
used to convert C-rates to currents and to compute the state of charge.
"""
function GenericProtocol(control_steps::AbstractVector, initial_state_of_charge;
	capacity,
	use_ramp_up = true,
	ramp_up_time = 100,
	T = Float64)

	validate_control_steps(control_steps)

	unfolded_steps = unfold_control_steps(control_steps)

	for s in unfolded_steps[1:(end - 1)]
		if !haskey(s.step, "Termination")
			error("Only the last control step can be given without termination, since it then lasts until the end of the simulation.")
		end
	end

	steps = AbstractControlStep[setup_control_step(s.step, capacity, use_ramp_up, ramp_up_time) for s in unfolded_steps]
	step_indices = Int[s.step_index for s in unfolded_steps]
	cycle_counts = Int[s.cycle_count for s in unfolded_steps]

	# Once the experiment is done, the cycle count is increased if the experiment ends with a cycle, in the same way
	# as when a new cycle starts.
	final_cycle_count = last(cycle_counts) + (last(control_steps)["ControlType"] == "Cycle" ? 1 : 0)

	maximum_current_value = maximum(maximum_current(step, capacity) for step in steps)

	R = promote_type(T, typeof(capacity), typeof(initial_state_of_charge), typeof(maximum_current_value))

	return GenericProtocol{Vector{Int}, R}(steps, step_indices, cycle_counts, final_cycle_count, maximum_current_value, capacity, initial_state_of_charge)
end


"""
	validate_control_steps(control_steps)

Validate a list of control steps against the control step schema. Throws an error listing the issues if the control
steps are not valid.
"""
function validate_control_steps(control_steps)

	schema = Schema(get_schema_control_steps())
	result = validate(schema, control_steps)

	if !isempty(result.issues)
		log_schema_issues(result.issues, "ControlSteps")
		error("The control steps are not valid. See the issues listed above.")
	end

	return nothing
end


"""
	unfold_control_steps(control_steps)

Unfold the "Cycle" control steps into a flat list. Each entry of the returned list is a named tuple with the control
step dictionary, its index within the current cycle and the cycle count. Each repetition of an outermost "Cycle" step
starts a new cycle.
"""
function unfold_control_steps(control_steps)

	unfolded = NamedTuple{(:step, :step_index, :cycle_count), Tuple{Any, Int, Int}}[]
	counter = (step_index = Ref(0), cycle_count = Ref(0))

	unfold_control_steps!(unfolded, control_steps, counter, true)

	return unfolded
end

function unfold_control_steps!(unfolded, control_steps, counter, outermost)

	for step in control_steps

		if step["ControlType"] == "Cycle"

			for _ in 1:step["NumberOfCycles"]
				outermost && start_new_cycle!(unfolded, counter)
				unfold_control_steps!(unfolded, step["ControlSteps"], counter, false)
			end

			# Steps following an outermost cycle belong to a new cycle
			outermost && start_new_cycle!(unfolded, counter)

		else
			push!(unfolded, (step = step, step_index = counter.step_index[], cycle_count = counter.cycle_count[]))
			counter.step_index[] += 1
		end
	end

	return unfolded
end


function start_new_cycle!(unfolded, counter)
	# Only start a new cycle if the current one already contains steps, so that no cycle number is skipped
	if !isempty(unfolded) && last(unfolded).cycle_count == counter.cycle_count[]
		counter.cycle_count[] += 1
		counter.step_index[] = 0
	end
end


"""
	setup_control_step(step, capacity, use_ramp_up, ramp_up_time)

Create a control step instance from its json description.
"""
function setup_control_step(step::AbstractDict, capacity, use_ramp_up, ramp_up_time)

	control_type = step["ControlType"]
	termination = setup_termination(get(step, "Termination", nothing), capacity)

	# json integers are converted to floats
	value = haskey(step, "Value") ? float(step["Value"]) : nothing

	if control_type == "Current"
		if haskey(step, "CRate")
			return CurrentStep(float(step["CRate"]), step["Direction"], termination; is_c_rate = true, use_ramp_up, ramp_up_time)
		else
			return CurrentStep(value, step["Direction"], termination; use_ramp_up, ramp_up_time)
		end
	elseif control_type == "Voltage"
		return VoltageStep(value, termination)
	elseif control_type == "Power"
		return PowerStep(value, step["Direction"], termination)
	elseif control_type == "Rest"
		return RestStep(0.0, termination)
	elseif control_type == "CurrentFunction"
		current_function = setup_function_from_function_name(step["FunctionName"]; file_path = get(step, "FilePath", nothing))
		return CurrentFunctionStep(current_function, termination)
	elseif control_type == "CurrentSeries"
		return CurrentSeriesStep(float.(step["Times"]), float.(step["Currents"]),
			float(get(step, "LowerVoltageLimit", -Inf)), float(get(step, "UpperVoltageLimit", Inf)), termination)
	else
		error("Control type $control_type not recognized.")
	end

end


function setup_initial_control_policy!(policy::GenericProtocol, input, parameters)

end

function getInitCurrent(policy::GenericProtocol)
	return get_initial_current(policy.steps[1], policy.rated_capacity)
end


"""
	experiment_is_finished(protocol, controller)

The experiment is finished when the last control step has terminated.
"""
function experiment_is_finished(protocol::GenericProtocol, controller)
	return controller.step_count >= length(protocol.steps)
end


"""
Update the controller: first the control step, then the target of the control equation.
"""
function update_controller!(state, state0, protocol::GenericProtocol, dt)

	update_control_step_in_controller!(state, state0, protocol, dt)

	# Only current steps given as C-rates set this flag
	state.Controller.target_is_c_rate = false

	return update_values_in_controller!(state, state0, state.Controller.step)

end


"""
Implementation of the generic control protocol. This function is called at each Newton iteration. It updates the
quantities monitored by the terminations and decides if the control switches to the next control step.

The control only switches if the previous converged state has already entered the termination region of the control
step. Within a time step, a switch is not reverted, to avoid oscillations. The in-step constraint check (see
check_constraints) cuts the time step when a converged state has gone past the termination region, so that the switch
happens within the termination region.
"""
function update_control_step_in_controller!(state, state0, protocol::GenericProtocol, dt)

	controller = state[:Controller]
	controller0 = state0[:Controller]

	voltage = only(value(state[:ElectricPotential]))
	current = only(value(state[:Current]))
	voltage_0 = only(value(state0[:ElectricPotential]))
	current_0 = only(value(state0[:Current]))

	controller.time = controller0.time + dt
	controller.state_of_charge = compute_state_of_charge(controller0.state_of_charge, dt, protocol.rated_capacity, current)
	controller.dIdt = dt > 0 ? (abs(current) - abs(current_0)) / dt : 0.0
	controller.dEdt = dt > 0 ? (voltage - voltage_0) / dt : 0.0
	controller.current = current
	controller.voltage = voltage

	switch = false

	if !experiment_is_finished(protocol, controller0)

		termination = controller0.step.termination

		if !get_status_on_termination_region(termination, state0).before_termination_region
			# We entered the termination region in the previous time step. We consider switching control.
			if controller.step_count == controller0.step_count
				# The control has not changed in this time step. We switch if we are past the termination region.
				switch = get_status_on_termination_region(termination, state).after_termination_region
			else
				# The control has already been switched in a previous Newton iteration. We do not switch back to avoid
				# oscillations. We are anyway within the given tolerance for the control.
				switch = true
			end
		end
	end

	set_control_step!(controller, controller0, protocol, switch ? controller0.step_count + 1 : controller0.step_count)

	return nothing
end


function set_control_step!(controller, controller0, protocol::GenericProtocol, step_count)

	number_of_steps = length(protocol.steps)

	if step_count == controller0.step_count
		# The control step is kept
		controller.step = controller0.step
		controller.step_index = controller0.step_index
		controller.cycle_count = controller0.cycle_count
		controller.step_start_time = controller0.step_start_time

	elseif step_count < number_of_steps
		# Switch to the next control step
		index = step_count + 1
		controller.step = protocol.steps[index]
		controller.step_index = protocol.step_indices[index]
		controller.cycle_count = protocol.cycle_counts[index]
		controller.step_start_time = controller0.time

	else
		# The last control step has terminated. We keep its control for this time step and flag the end of the
		# experiment by setting step_count past the last step. The simulation is stopped by the post-ministep hook set
		# up in solver_configuration.
		controller.step = controller0.step
		controller.step_index = controller0.step_index
		controller.cycle_count = protocol.final_cycle_count
		controller.step_start_time = controller0.step_start_time
	end

	controller.step_count = step_count

	return controller
end


"""
When a time step has converged, the converged state may not fulfill the requirements of the control: it can be past
the termination region of the control step, meaning that the control should have switched, or the control has switched
but the state is not before the termination region of the new step. In these cases, check_constraints returns false
and the Newton iterations continue. If the control cannot switch in this time step, the time step is eventually cut.
In this way, the switches happen within the termination regions. This function is used as global convergence check.
"""
function check_constraints(model, storage)

	protocol = model[:Control].system.policy

	state = storage.state[:Control]
	controller = state[:Controller]
	controller0 = storage.state0[:Control][:Controller]

	if controller.step_count == controller0.step_count
		# The control has not switched: the state should not be past the termination region of the step
		return !get_constraint_status(controller.step.termination, state).after_termination_region
	elseif !experiment_is_finished(protocol, controller)
		# The control has switched: the state should be before the termination region of the new step
		return get_constraint_status(controller.step.termination, state).before_termination_region
	else
		return true
	end

end


"""
We need to add the specific treatment of the controller variables for GenericProtocol
"""
function Jutul.reset_state_to_previous_state!(
	storage,
	model::SimulationModel{CurrentAndVoltageDomain, <:CurrentAndVoltageSystem{<:GenericProtocol}, T3, T4},
) where {T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage), SimulationModel},
		storage,
		model)

	copyController!(storage.state[:Controller], storage.state0[:Controller])
end


"""
We limit the Newton updates of the current to a fraction of the maximum current of the protocol, to avoid
convergence problems at control switches.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::CurrentAndVoltageModel{<:GenericProtocol}, dx, w)

	entity = associated_entity(p)
	active = active_entities(model.domain, entity, for_variables = true)
	v = state[state_symbol]

	maximum_current = model.system.policy.maximum_current

	abs_max = maximum_current > 0 ? 0.2 * maximum_current : absolute_increment_limit(p)
	rel_max = relative_increment_limit(p)
	maxval = maximum_value(p)
	minval = minimum_value(p)
	scale = variable_scale(p)

	@inbounds for i in eachindex(active)
		a_i = active[i]
		v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
	end

	return v
end

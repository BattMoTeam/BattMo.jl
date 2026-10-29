#######################################################################################################################
# Protocols
#
# A protocol is an implementation of a certain policy or a combination of policies.
#
# This script defines cycling protocol types:
#	- GenericProtocol: a protocol that can contain any combination and order of control steps
#
# The basis of the generic protocol is the json control step structure, described by the control step schema (see
# get_schema_control_steps). The control steps are given either directly (Protocol "Generic", field "ControlSteps")
# or as experiment strings (Protocol "Experiment", field "Experiment") which are first converted to control steps.
# The control steps are validated against the schema, the "Cycle" steps are unfolded, and each step is then turned
# into an AbstractControlStep instance.
#######################################################################################################################



"""
GenericProtocol
"""
struct GenericProtocol{V, R} <: AbstractPolicy where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	cycle_counts::V
	rated_capacity::R
	initial_state_of_charge::R
end


"""
	GenericProtocol(cycling_protocol, input; T = Float64)

Set up the generic protocol from a cycling protocol with Protocol "Generic" or "Experiment".
"""
function GenericProtocol(cycling_protocol::CyclingProtocol, input; T = Float64)

	use_ramp_up = haskey(input.model_settings, "RampUp")

	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 100

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	else
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

	steps = AbstractControlStep[setup_control_step(s.step, capacity, use_ramp_up, ramp_up_time) for s in unfolded_steps]
	step_indices = Int[s.step_index for s in unfolded_steps]
	cycle_counts = Int[s.cycle_count for s in unfolded_steps]

	R = promote_type(T, typeof(capacity), typeof(initial_state_of_charge))

	return GenericProtocol{Vector{Int}, R}(steps, step_indices, cycle_counts, capacity, initial_state_of_charge)
end


"""
Get the list of control steps from a cycling protocol. Experiment strings are converted to control steps.
"""
function get_control_steps(cycling_protocol)

	protocol = cycling_protocol["Protocol"]

	if protocol == "Generic"
		return cycling_protocol["ControlSteps"]
	elseif protocol == "Experiment"
		return experiment_to_control_steps(cycling_protocol["Experiment"])
	else
		error("Protocol $protocol cannot be converted to control steps.")
	end

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
	termination = setup_termination(step["Termination"], capacity)

	# json integers are converted to floats
	value = haskey(step, "Value") ? float(step["Value"]) : nothing

	if control_type == "Current"
		current = haskey(step, "CRate") ? step["CRate"] * capacity : value
		return CurrentStep(current, step["Direction"], termination, use_ramp_up; ramp_up_time)
	elseif control_type == "Voltage"
		return VoltageStep(value, termination)
	elseif control_type == "Power"
		return PowerStep(value, step["Direction"], termination)
	elseif control_type == "Rest"
		return RestStep(0.0, termination)
	else
		error("Control type $control_type not recognized.")
	end

end



function add_experiment_strings!(experiment_list, cycling_protocol, direction, policy)

	if direction == "charging"
		if haskey(cycling_protocol, "CRate")
			rate = "$(cycling_protocol["CRate"]) C"
		elseif haskey(cycling_protocol, "MaximumCurrent")
			rate = "$(cycling_protocol["MaximumCurrent"]) A"
		else
			error("Both CRate and MaximumCurrent not specified in cycling protocol.")
		end
		push!(experiment_list, "Charge at $rate until $(cycling_protocol["UpperVoltageLimit"]) V")

		if policy == "CCCV"

			push!(experiment_list, "Hold at $(cycling_protocol["UpperVoltageLimit"]) V until $(cycling_protocol["CurrentChangeLimit"]) A/s")
		end

	elseif direction == "discharging"
		if haskey(cycling_protocol, "DRate")
			rate = "$(cycling_protocol["DRate"]) C"
		elseif haskey(cycling_protocol, "MaximumCurrent")
			rate = "$(cycling_protocol["MaximumCurrent"]) A"
		else
			error("Both DRate and MaximumCurrent not specified in cycling protocol.")
		end
		push!(experiment_list, "Discharge at $rate until $(cycling_protocol["LowerVoltageLimit"]) V")
		if policy == "CCCV"

			push!(experiment_list, "Rest until $(cycling_protocol["VoltageChangeLimit"]) V/s")

		end

	else
		error("direction $direction not recognized.")
	end
	return experiment_list

end



function setup_initial_control_policy!(policy::GenericProtocol, input, parameters)

end

function getInitCurrent(policy::GenericProtocol)
	return get_initial_current(policy.steps[1])
end


"""
Implementation of the generic control protocol
"""
function update_control_step_in_controller!(state, state0, protocol::GenericProtocol, dt)
	control_steps = protocol.steps
	cycle_counts = protocol.cycle_counts
	step_indices = protocol.step_indices

	number_of_control_steps = length(protocol.steps)

	# --- Helpers: mapping between controller.step_count (zero-based) and control_steps (1-based) ---

	# Map controller.step_count (which in your logs is 0 for the first step)
	# to 1-based index used for control_steps array
	stepcount_to_index(step_count::Integer) = clamp(step_count + 1, 1, number_of_control_steps)   # stepnum 0 -> index 1
	index_to_stepcount(index::Integer) = clamp(index - 1, 0, number_of_control_steps - 1)      # index 1 -> stepnum 0

	# --- Extract scalars safely ---
	voltage_values = value(state[:ElectricPotential])
	current_values = value(state[:Current])
	voltage_0_values = value(state0[:ElectricPotential])
	current_0_values = value(state0[:Current])

	@assert length(voltage_values) == 1 "Expected scalar ElectricPotential"
	@assert length(current_values) == 1 "Expected scalar Current"
	@assert length(voltage_0_values) == 1 "Expected scalar ElectricPotential (state0)"
	@assert length(current_0_values) == 1 "Expected scalar Current (state0)"

	voltage = first(voltage_values)
	current = first(current_values)
	voltage_0 = first(voltage_0_values)
	current_0 = first(current_0_values)

	# --- Time and derivatives ---
	controller = state[:Controller]

	controller.time = state0.Controller.time + dt
	controller.state_of_charge = compute_state_of_charge(state0.Controller.state_of_charge, dt, protocol.rated_capacity, current)
	controller.dIdt = dt > 0 ? (abs(current) - abs(current_0)) / dt : 0.0
	controller.dEdt = dt > 0 ? (voltage - voltage_0) / dt : 0.0
	controller.current = current
	controller.voltage = voltage

	# --- Determine previous/ current indices and types (clearly mapped) ---
	previous_step_count = state0.Controller.step_count                # e.g. 0 for first step
	previous_step_index = state0.Controller.step_index                # e.g. 0 for first step
	previous_cycle_count = state0.Controller.cycle_count                # e.g. 0 for first cycle
	previous_index = stepcount_to_index(previous_step_count)                     # 1-based index into control_steps
	previous_control_step = state0.Controller.step

	# Compute region switch flags for previous states
	# status_previous = setupRegionSwitchFlags(previous_control_step, state0, controller)
	status_previous = get_status_on_termination_region(previous_control_step.termination, state0)


	if status_previous.before_termination_region
		# We have not entered the switching region in the time step. We are not going to change control.

		step_count = previous_step_count
		step_index = previous_step_index
		cycle_count = previous_cycle_count
		control_step = previous_control_step

	else
		# We entered the switch region in the previous time step. We consider switching control

		# If controller hasn't already changed this Newton iteration, decide
		if controller.step_count == state0.Controller.step_count
			# The control has not changed from previous time step and we want to determine if we should change it.
			# status_current = setupRegionSwitchFlags(previous_control_step, state, controller)
			status = get_status_on_termination_region(previous_control_step.termination, state)

			if status.after_termination_region
				# Attempt to move forward one stepnum
				step_count = previous_step_count + 1   # still zero-based
				index = previous_index + 1


				if index <= number_of_control_steps && step_count <= (number_of_control_steps - 1)
					# 	# Copy the policy step so we can mutate termination without altering original policy
					cycle_count = cycle_counts[index]
					step_index = step_indices[index]
					control_step = control_steps[index]

					# Adjust time-based termination (if needed)
					adjust_time_based_termination_target!(control_step.termination, state0.Controller.time)

				else
					# The last control step has terminated. We keep its control for this time step and flag the end of
					# the experiment by setting step_count past the last step. The simulation is stopped by the
					# post-ministep hook set up in solver_configuration.
					step_count = number_of_control_steps
					step_index = previous_step_index
					cycle_count = previous_cycle_count
					control_step = previous_control_step
				end

			else
				step_count = previous_step_count
				step_index = previous_step_index
				cycle_count = previous_cycle_count
				control_step = previous_control_step

			end

		else
			# controller already advanced this iteration: We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
			# control so that we keep the control as it is.

			step_count = previous_step_count + 1   # still zero-based
			index = previous_index + 1

			if index <= number_of_control_steps && step_count <= (number_of_control_steps - 1)
				# 	# Copy the policy step so we can mutate termination without altering original policy
				cycle_count = cycle_counts[index]
				step_index = step_indices[index]
				control_step = control_steps[index]

				# Adjust time-based termination (if needed)
				adjust_time_based_termination_target!(control_step.termination, state0.Controller.time)

			else
				# The last control step has terminated (see above)
				step_count = number_of_control_steps
				step_index = previous_step_index
				cycle_count = previous_cycle_count
				control_step = previous_control_step
			end
		end

	end

	# --- Finalize: clamp stepnum and set controller fields ---
	# Ensure we stay within valid [0, nsteps-1] for stepnum convention
	# step_number = clamp(step_number, 0, max(0, nsteps - 1))

	controller.step_count = step_count
	controller.step_index = step_index
	controller.cycle_count = cycle_count
	controller.step = control_step

	return nothing
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

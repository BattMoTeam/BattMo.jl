export GenericProtocol



struct GenericProtocol{V} <: AbstractProtocol where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	step_counts::V
	cycle_counts::V
	maximum_current::Real
end

function GenericProtocol(protocol::C, input) where C <: AbstractPolicy

	stepper, maximum_current = setup_generic_protocol(protocol, input)
	return GenericProtocol{typeof(stepper.step_indices)}(stepper.steps, stepper.step_indices, stepper.step_counts, stepper.cycle_counts, maximum_current)
end


"""
FunctionProtocol
"""
struct FunctionProtocol <: AbstractProtocol
	current_function::Function

	function FunctionProtocol(function_name::String; file_path::Union{Nothing, String} = nothing)
		current_function = setup_function_from_function_name(function_name; file_path = file_path)
		new{}(current_function)
	end

end

function get_initial_current(policy::FunctionProtocol)
	return 0.0
end



"""
We need to add the specific treatment of the controller variables for GenericProtocol
"""
function Jutul.reset_state_to_previous_state!(
	storage,
	model::SimulationModel{CurrentAndVoltageDomain, CurrentAndVoltageSystem{GenericProtocol}, T3, T4},
) where {T3, T4}

	invoke(reset_state_to_previous_state!,
		Tuple{typeof(storage), SimulationModel},
		storage,
		model)

	copyController!(storage.state[:Controller], storage.state0[:Controller])
end



"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {Q <: GenericProtocol, P <: CurrentAndVoltageModel{Q}}

	entity = associated_entity(p)
	active = active_entities(model.domain, entity, for_variables = true)
	v = state[state_symbol]

	nu = length(active)

	time = state.Controller.time
	maximum_current = model.system.policy.maximum_current

	abs_max = 0.2 * maximum_current
	abs_max = nothing
	rel_max = relative_increment_limit(p)
	maxval = maximum_value(p)
	minval = minimum_value(p)
	scale = variable_scale(p)
	@inbounds for i in 1:nu
		a_i = active[i]
		v[a_i] = update_value(v[a_i], w * dx[i], abs_max, rel_max, minval, maxval, scale)
	end

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
					control_step = deepcopy(control_steps[index])

					# Adjust time-based termination (if needed)
					adjust_time_based_termination_target!(control_step.termination, controller.time)

				else
					step_count = step_count
					cycle_count = cycle_counts[step_count]
					step_index = step_indices[step_count]

					control_step = control_steps[1]
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
				control_step = deepcopy(control_steps[index])

				# Adjust time-based termination (if needed)
				adjust_time_based_termination_target!(control_step.termination, controller.time)

			else
				step_count = step_count
				step_index = step_indices[step_count]
				cycle_count = cycle_counts[step_count]

				control_step = control_steps[1]
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
Implementation of the function policy
"""
function update_control_type_in_controller!(state, state0, policy::FunctionProtocol, dt)
	controller                   = state.Controller
	controller.target_is_voltage = false
	controller.time              = state0.Controller.time + dt

end

function update_values_in_controller!(state, policy::FunctionProtocol)

	controller = state.Controller

	cf = policy.current_function

	I_p = cf(controller.time, value(only(state.ElectricPotential)))

	controller.target = I_p


end

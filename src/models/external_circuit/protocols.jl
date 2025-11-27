export GenericProtocol



struct GenericProtocol <: AbstractProtocol
	steps::Vector{AbstractControlStep}
	step_indices::Vector{Int}
	cycle_numbers::Vector{Int}

	function GenericProtocol(protocol::C, input) where C <: AbstractProtocol

		steps, step_indices, cycle_numbers = setup_generic_protocol(protocol, input)
		return new(steps, step_indices, cycle_numbers)
	end


end

function setup_generic_protocol(control_steps::Experiment, input)

	use_ramp_up = haskey(input.model_settings, "RampUp")
	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 0.1

	capacity = compute_cell_theoretical_capacity(input.cell_parameters)

	experiment_list = control_steps.all
	if isa(experiment_list, String)
		experiment_list = [experiment_list]
	end

	steps = []
	step_indices = []
	cycle_indices = []

	step_index = 1
	cycle_index = 1

	for step in experiment_list

		if step isa String

			step_instance = parse_experiment_step(step, capacity, use_ramp_up; ramp_up_time)

			push!(steps, step_instance)
			push!(step_indices, step_index)
			push!(cycle_indices, cycle_index)

			step_index += 1
			cycle_index += 1

		elseif step isa Dict
			number_of_cycles = step["NumberOfCycles"]
			for cycle_index in range(cycle_index, cycle_index + number_of_cycles)

				for sub_step in step["Steps"]

					step_instance = parse_experiment_step(sub_step, capacity, use_ramp_up; ramp_up_time)

					push!(steps, step_instance)
					push!(step_indices, step_index)
					push!(cycle_indices, cycle_index)

					step_index += 1
					cycle_index = cycle_index

				end
			end
		else
			error("Experiment step must be a string of dict.")

		end
	end

	return steps, step_indices, cycle_indices

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


#######################################
# Helper functions for control switch #
#######################################



"""
We need a more fine-tuned update of the variables when we use a cycling policies, to avoid convergence problem.
"""
function Jutul.update_primary_variable!(state, p::CurrentVar, state_symbol, model::P, dx, w) where {Q <: GenericProtocol, P <: CurrentAndVoltageModel{Q}}

	entity = associated_entity(p)
	active = active_entities(model.domain, entity, for_variables = true)
	v = state[state_symbol]

	nu = length(active)
	# ImaxDischarge = model.system.policy.ImaxDischarge
	# ImaxCharge    = model.system.policy.ImaxCharge

	# Imax = max(ImaxCharge, ImaxDischarge)

	# abs_max = 0.2 * Imax
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
Implementation of the generic control policy
"""
function update_control_step_in_controller!(state, state0, policy::GenericProtocol, dt)
	control_steps = policy.steps

	number_of_control_steps = length(policy.steps)

	# --- Helpers: mapping between controller.step_number (zero-based) and control_steps (1-based) ---

	# Map controller.step_number (which in your logs is 0 for the first step)
	# to 1-based index used for control_steps array
	stepnum_to_index(step_number::Integer) = clamp(step_number + 1, 1, number_of_control_steps)   # stepnum 0 -> index 1
	index_to_stepnum(index::Integer) = clamp(index - 1, 0, number_of_control_steps - 1)      # index 1 -> stepnum 0

	# --- Extract scalars safely ---
	E_vals  = value(state[:ElectricPotential])
	I_vals  = value(state[:Current])
	E0_vals = value(state0[:ElectricPotential])
	I0_vals = value(state0[:Current])

	@assert length(E_vals) == 1 "Expected scalar ElectricPotential"
	@assert length(I_vals) == 1 "Expected scalar Current"
	@assert length(E0_vals) == 1 "Expected scalar ElectricPotential (state0)"
	@assert length(I0_vals) == 1 "Expected scalar Current (state0)"

	E  = first(E_vals)
	I  = first(I_vals)
	E0 = first(E0_vals)
	I0 = first(I0_vals)

	# --- Time and derivatives ---
	controller = state[:Controller]

	controller.time = state0.Controller.time + dt
	controller.dIdt = dt > 0 ? (I - I0) / dt : 0.0
	controller.dEdt = dt > 0 ? (E - E0) / dt : 0.0
	controller.current = I
	controller.voltage = E

	# --- Determine previous/ current indices and types (clearly mapped) ---
	previous_step_number = state0.Controller.current_step_number                # e.g. 0 for first step
	previous_index = stepnum_to_index(previous_step_number)                     # 1-based index into control_steps
	previous_control_step = state0.Controller.current_step




	# Compute region switch flags for previous states
	# status_previous = setupRegionSwitchFlags(previous_control_step, state0, controller)
	status_previous = get_status_on_termination_region(previous_control_step.termination, state0)

	if status_previous.before_termination_region
		# We have not entered the switching region in the time step. We are not going to change control.
		step_number = previous_step_number
		control_step = previous_control_step

	else
		# We entered the switch region in the previous time step. We consider switching control

		# If controller hasn't already changed this Newton iteration, decide
		if controller.current_step_number == state0.Controller.current_step_number
			# The control has not changed from previous time step and we want to determine if we should change it.
			# status_current = setupRegionSwitchFlags(previous_control_step, state, controller)
			status_current = get_status_on_termination_region(previous_control_step.termination, state)

			if status_current.after_termination_region
				# Attempt to move forward one stepnum
				step_number = previous_step_number + 1   # still zero-based
				index = previous_index + 1

				if index <= number_of_control_steps && step_number <= (number_of_control_steps - 1)
					# 	# Copy the policy step so we can mutate termination without altering original policy
					control_step = deepcopy(control_steps[index])

					# Adjust time-based termination (if needed)
					if control_step.termination isa TimeTermination &&
					   control_step.termination.end_time < controller.time

						control_step.termination.end_time = controller.time + control_step.termination.end_time
					end

				else
					step_number = step_number
					control_step = control_steps[1]
				end

			else
				step_number = previous_step_number
				control_step = previous_control_step
			end

		else
			# controller already advanced this iteration: We do not switch back to avoid oscillation. We are anyway within the given tolerance for the
			# control so that we keep the control as it is.

			step_number = previous_step_number + 1   # still zero-based
			index = previous_index + 1
			if index <= number_of_control_steps && step_number <= (number_of_control_steps - 1)
				# 	# Copy the policy step so we can mutate termination without altering original policy
				control_step = deepcopy(control_steps[index])

				# Adjust time-based termination (if needed)
				if control_step.termination isa TimeTermination &&
				   control_step.termination.end_time < controller.time

					control_step.termination.end_time = controller.time + control_step.termination.end_time
				end

			else
				step_number = step_number
				control_step = control_steps[1]
			end
		end
	end

	# --- Finalize: clamp stepnum and set controller fields ---
	# Ensure we stay within valid [0, nsteps-1] for stepnum convention
	# step_number = clamp(step_number, 0, max(0, nsteps - 1))

	controller.current_step_number = step_number
	controller.current_step = control_step

	return nothing
end


function update_values_in_controller!(state, step::PowerStep)


	P = step.value
	E = state.Controller.voltage

	I = P/E

	state.Controller.target = I

end

function update_values_in_controller!(state, step::CurrentStep)


	current_function = step.current_function

	I_t = current_function(state.Controller.time)

	state.Controller.target = I_t

end

function update_values_in_controller!(state, step::VoltageStep)
	state.Controller.target = step.value

end

function update_values_in_controller!(state, step::RestStep)
	state.Controller.target = step.value

end


"""
Update controller target value (current or voltage) based on the active control step
"""
function update_values_in_controller!(state, policy::GenericProtocol)

	controller = state[:Controller]
	step_index = controller.current_step_number + 1

	control_steps = policy.steps

	# if step_index > length(control_steps)
	# 	step_index = length(control_steps)
	# end

	step = state.Controller.current_step

	if step isa CurrentStep


		control_direction = step.direction

		current_function = step.current_function


		if !ismissing(current_function)

			if current_function isa Real
				I_t = current_function
			else
				# Function of time at the end of interval
				I_t = current_function(controller.time)
			end

			if control_direction == "discharging"

				target = I_t

			elseif control_direction == "charging"

				# minus sign below follows from convention
				target = -I_t
			else
				error("Control type $control_direction not recognized")
			end
		else

			tup = state.Controller.time + 100 #Float64(AbstractInput["Control"]["rampupTime"])
			cFun(time) = get_current_value(time, step.value, tup)

			step.current_function = cFun
			current_function = step.current_function
			if current_function isa Real
				I_t = current_function
			else
				# Function of time at the end of interval
				I_t = current_function(controller.time)
			end
			if control_direction == "discharging"

				target = I_t

			elseif control_direction == "charging"

				# minus sign below follows from convention
				target = -I_t
			else
				error("Control type $ctrlType not recognized")
			end
		end

	elseif step isa VoltageStep
		target = step.value

	elseif step isa RestStep
		# Assume voltage hold during rest
		target = 0.0

	else
		error("Unsupported step type: $(typeof(step))")
	end

	controller.target = target

end

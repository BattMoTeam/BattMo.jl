
struct CycleStep <: AbstractControlStep
	number_of_cycles::Int
	termination::Union{Nothing, Termination}
	cycle_control_steps::Vector{AbstractControlStep}
end


# mutable struct GenericProtocol <: AbstractProtocol
# 	control_policy::String
# 	control_steps::Vector{AbstractControlStep}
# 	initial_control::AbstractControlStep
# 	number_of_control_steps::Int
# 	function GenericProtocol(json::Dict)
# 		steps = []
# 		for step in json["controlsteps"]
# 			parsed_step = parse_control_step(step)

# 			if isa(parsed_step, CycleStep)
# 				# If the parsed step is a compound cycle, expand it
# 				for cycle_step in parsed_step.cycle_control_steps
# 					push!(steps, cycle_step)
# 				end
# 			else
# 				# Otherwise, it's a single step — push directly
# 				push!(steps, parsed_step)
# 			end
# 		end

# 		number_of_steps = length(steps)
# 		return new(json["controlPolicy"], steps, steps[1], number_of_steps)
# 	end
# end


# function parse_control_step(json::Dict)
# 	ctype = json["controltype"]
# 	if ctype == "current"
# 		return CurrentStep(
# 			json["value"],
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
# 			get(json, "timeStepSize", nothing),
# 			missing)
# 	elseif ctype == "voltage"
# 		return VoltageStep(
# 			json["value"],
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]; comparison = json["termination"]["comparison"]),
# 			get(json, "timeStepSize", nothing),
# 		)
# 	elseif ctype == "rest"
# 		return RestStep(
# 			get(json, "value", nothing),
# 			get(json, "direction", nothing),
# 			Termination(json["termination"]["quantity"], json["termination"]["value"]),
# 			get(json, "timeStepSize", nothing),
# 		)
# 	elseif ctype == "cycle"
# 		nested = [parse_control_step(step) for step in json["cycleControlSteps"]]
# 		return CycleStep(json["numberOfCycles"], get(json, "termination", nothing), nested)
# 	else
# 		error("Unsupported controltype: $ctype")
# 	end
# end

function get_initial_current(policy::GenericProtocol)
	control = policy.steps[1]
	if isa(control, VoltageStep)
		error("Voltage control cannot be the first control step")
	elseif isa(control, CurrentStep)


	elseif isa(control, RestStep)
		return 0.0
	else
		error("initial control not recognized")
	end

end


function setup_initial_control_policy!(policy::GenericProtocol, input, parameters)
	control = policy.steps[1]

	if isa(control, VoltageStep)
		error("Voltage control cannot be the first control step")
	elseif isa(control, CurrentStep)
		if ismissing(control.current_function)
			tup = Float64(input.simulation_settings["RampUpTime"])
			Imax = control.value
			cFun(time) = currentFun(time, Imax, tup)

			control.current_function = cFun
		end


	elseif isa(control, RestStep)

	else
		error("initial control not recognized")
	end


end



@inline function Jutul.numerical_type(x::GenericController)
	return typeof(x.current_step)
end

"""
Function to create (deep) copy of generic controller
"""
function copyController!(cv_copy::GenericController, cv::GenericController)

	cv_copy.policy = cv.policy
	cv_copy.current_step = cv.current_step
	cv_copy.current_step_number = cv.current_step_number
	cv_copy.time = cv.time
	cv_copy.number_of_steps = cv.number_of_steps
	cv_copy.target = cv.target
	cv_copy.dEdt = cv.dEdt
	cv_copy.dIdt = cv.dIdt

end

"""
Overload function to copy GenericController
"""
function Base.copy(cv::GenericController)
	# Construct using the known type parameter S
	cv_copy = GenericController(cv.policy, cv.stop_simulation, cv.current_step, cv.current_step_number, cv.time, cv.number_of_steps; target = cv.target, dIdt = cv.dIdt, dEdt = cv.dEdt)

	return cv_copy
end


function Jutul.update_values!(old::GenericController, new::GenericController)

	copyController!(old, new)

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
The setupRegionSwitchFlags function detects from the current state and control, if we are in the switch region. The functions return two flags :
- beforeSwitchRegion : the state is before the switch region for the current control
- afterSwitchRegion : the state is after the switch region for the current control
"""
function setupRegionSwitchFlags(policy::P, state, controller::GenericController) where P <: AbstractControlStep

	step = policy
	termination = step.termination

	if haskey(state, :ElectricPotential)
		E = only(state.ElectricPotential)
		I = only(state.Current)
	else
		E = ForwardDiff.value(only(state.Control.ElectricPotential))
		I = ForwardDiff.value(only(state.Control.Current))
	end

	before = false
	after = false

	if termination.quantity == "voltage"

		target = termination.value
		tol = 1e-4

		if isnothing(termination.comparison) || termination.comparison == "below"
			before = E > target * (1 + tol)
			after  = E < target * (1 - tol)
		elseif termination.comparison == "above"
			before = E < target * (1 - tol)
			after  = E > target * (1 + tol)
		end

	elseif termination.quantity == "current"
		target = termination.value
		tol = 1e-4

		if isnothing(termination.comparison) || termination.comparison == "absolute value below"
			before = abs(I) > target * (1 + tol)
			after  = abs(I) < target * (1 - tol)
		elseif termination.comparison == "absolute value above"
			before = abs(I) < target * (1 - tol)
			after  = abs(I) > target * (1 + tol)
		end

	elseif termination.quantity == "time"
		t = controller.time

		target = termination.value
		tol = 0.1

		before = t < target - tol
		after  = t > target + tol


	else
		error("Unsupported termination quantity: $(termination.quantity)")
	end

	return (beforeSwitchRegion = before, afterSwitchRegion = after)

end


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
function update_control_type_in_controller!(state, state0, policy::GenericProtocol, dt)
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

	# --- Determine previous/ current indices and types (clearly mapped) ---
	previous_step_number = state0.Controller.current_step_number                # e.g. 0 for first step
	previous_index = stepnum_to_index(previous_step_number)                     # 1-based index into control_steps
	previous_control_step = state0.Controller.current_step




	# Compute region switch flags for previous states
	status_previous = setupRegionSwitchFlags(previous_control_step, state0, controller)

	if status_previous.beforeSwitchRegion
		# We have not entered the switching region in the time step. We are not going to change control.
		step_number = previous_step_number
		control_step = previous_control_step

	else
		# We entered the switch region in the previous time step. We consider switching control

		# If controller hasn't already changed this Newton iteration, decide
		if controller.current_step_number == state0.Controller.current_step_number
			# The control has not changed from previous time step and we want to determine if we should change it.
			status_current = setupRegionSwitchFlags(previous_control_step, state, controller)

			if status_current.afterSwitchRegion
				# Attempt to move forward one stepnum
				step_number = previous_step_number + 1   # still zero-based
				index = previous_index + 1

				if index <= number_of_control_steps && step_number <= (number_of_control_steps - 1)
					# 	# Copy the policy step so we can mutate termination without altering original policy
					control_step = deepcopy(control_steps[index])

					# Adjust time-based termination (if needed)
					if hasfield(typeof(control_step), :termination) &&
					   control_step.termination.quantity == "time" &&
					   (control_step.termination.value !== nothing) &&
					   control_step.termination.value < controller.time

						control_step.termination.value = controller.time + control_step.termination.value
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
				if hasfield(typeof(control_step), :termination) &&
				   control_step.termination.quantity == "time" &&
				   (control_step.termination.value !== nothing) &&
				   control_step.termination.value < controller.time

					control_step.termination.value = controller.time + control_step.termination.value
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
			cFun(time) = currentFun(time, step.value, tup)

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

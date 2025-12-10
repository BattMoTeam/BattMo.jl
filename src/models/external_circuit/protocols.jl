#######################################################################################################################
# Protocols
#
# A protocol is a instance of a certain policy or a combination of policies.
#
# This script defines cycling protocol types:
#	- GenericProtocol: a protocol that can contain any combination and order of control steps
#######################################################################################################################


abstract type AbstractProtocol end



############################################
# Define the protocol types

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
GenericProtocol
"""
struct GenericProtocol{V} <: AbstractProtocol where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	step_counts::V
	cycle_counts::V
	maximum_current::Real
end

function GenericProtocol(cycling_protocol::Experiment; use_ramp_up = true, ramp_up_time = 0.1, capacity = nothing)

	experiment_list = cycling_protocol["Experiment"]

	if isa(experiment_list, String)
		experiment_list = [experiment_list]
	end

	stepper = Stepper([], 0, 0, 0, [], [], [])

	for (idx, step) in enumerate(experiment_list)
		stepper = update_stepper!(stepper, step, idx, experiment_list, capacity, use_ramp_up, ramp_up_time)
	end

	# Get maximum current value of all steps

	current = []
	for step in stepper.steps

		if step isa CurrentStep || step isa RestStep
			push!(current, step.value)
		end

	end

	if isempty(current)
		error("..")
	else
		maximum_current = maximum(current)
	end

	return GenericProtocol{typeof(stepper.step_indices)}(stepper.steps, stepper.step_indices, stepper.step_counts, stepper.cycle_counts, maximum_current)
end

function GenericProtocol(cycling_protocol::Experiment, input)

	use_ramp_up = haskey(input.model_settings, "RampUp")
	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 0.1

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	else
		capacity = compute_cell_theoretical_capacity(input.cell_parameters)
	end

	return GenericProtocol(cycling_protocol::Experiment; use_ramp_up = use_ramp_up, ramp_up_time = ramp_up_time, capacity = capacity)
end



function GenericProtocol(cycling_protocol::ConstantCurrent, input)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []

	experiment_list = create_current_controlled_experiment_string(experiment_list, cycling_protocol, cycling_protocol["InitialControl"], "CC")


	if cycling_protocol["TotalNumberOfCycles"] > 0
		opposite_direction = get_opposite_direction(cycling_protocol["InitialControl"])
		experiment_list = create_current_controlled_experiment_string(experiment_list, cycling_protocol, opposite_direction, "CC")

		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return GenericProtocol(experiment, input)
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

function GenericProtocol(cycling_protocol::ConstantCurrentConstantVoltage, input)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []
	if cycling_protocol["InitialControl"] == "charging"
		if haskey(cycling_protocol, "CRate")
			rate = "$(cycling_protocol["CRate"]) C"
		elseif haskey(cycling_protocol, "MaximumCurrent")
			rate = "$(cycling_protocol["MaximumCurrent"]) A"
		else
			error("Both CRate and MaximumCurrent not specified in cycling protocol.")
		end
		push!(experiment_list, "Charge at $rate until $(cycling_protocol["UpperVoltageLimit"]) V")
		push!(experiment_list, "Hold at $(cycling_protocol["UpperVoltageLimit"]) V until $(cycling_protocol["CurrentChangeLimit"]) A/s")
	elseif cycling_protocol["InitialControl"] == "discharging"
		if haskey(cycling_protocol, "DRate")
			rate = "$(cycling_protocol["DRate"]) C"
		elseif haskey(cycling_protocol, "MaximumCurrent")
			rate = "$(cycling_protocol["MaximumCurrent"]) A"
		else
			error("Both DRate and MaximumCurrent not specified in cycling protocol.")
		end
		push!(experiment_list, "Discharge at $rate until $(cycling_protocol["LowerVoltageLimit"]) V")
		push!(experiment_list, "Rest until $(cycling_protocol["VoltageChangeLimit"]) V/s")

	else
		error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
	end

	if cycling_protocol["TotalNumberOfCycles"] > 0
		if cycling_protocol["InitialControl"] == "charging"
			if haskey(cycling_protocol, "DRate")
				rate = "$(cycling_protocol["DRate"]) C"
			elseif haskey(cycling_protocol, "MaximumCurrent")
				rate = "$(cycling_protocol["MaximumCurrent"]) A"
			else
				error("Both DRate and MaximumCurrent not specified in cycling protocol.")
			end
			push!(experiment_list, "Discharge at $rate until $(cycling_protocol["LowerVoltageLimit"]) V")
			push!(experiment_list, "Rest until $(cycling_protocol["VoltageChangeLimit"]) V/s")

		elseif cycling_protocol["InitialControl"] == "discharging"
			if haskey(cycling_protocol, "CRate")
				rate = "$(cycling_protocol["CRate"]) C"
			elseif haskey(cycling_protocol, "MaximumCurrent")
				rate = "$(cycling_protocol["MaximumCurrent"]) A"
			else
				error("Both CRate and MaximumCurrent not specified in cycling protocol.")
			end
			push!(experiment_list, "Charge at $rate until $(cycling_protocol["UpperVoltageLimit"]) V")
			push!(experiment_list, "Hold at $(cycling_protocol["UpperVoltageLimit"]) V until $(cycling_protocol["CurrentChangeLimit"]) A/s")

		else
			error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
		end
		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return GenericProtocol(experiment, input)
end


##############################################
# Update the control step in the controller

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
					# @info "step_count", step_count
					# @info "index", index
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

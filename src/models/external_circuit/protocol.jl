#######################################################################################################################
# Control protocol
#
# The control protocol is the sequence of control steps that drives the external circuit during a simulation. It is
# the single control framework of BattMo: every cycling protocol ("CC", "CCCV", "Function", "InputCurrentSeries",
# "Experiment" and "Generic") is first converted to the json control step structure described by the control step
# schema (see get_schema_control_steps and input/control_steps/protocol_conversion.jl). The control steps are
# validated against the schema, the "Cycle" steps are unfolded, and each step is turned into a control step instance
# (see control_steps.jl).
#
# How the controller moves through the control steps during a simulation is implemented in step_switching.jl.
#######################################################################################################################



"""
	ControlProtocol

The unfolded sequence of control steps, with for each step its index within its cycle and its cycle count.
"""
struct ControlProtocol{V <: Vector{Int}, R}
	steps::Vector{AbstractControlStep}
	step_indices::V
	cycle_counts::V
	final_cycle_count::Int  # cycle count once the last control step has terminated
	maximum_current::R      # used to limit the Newton updates of the current, zero if unknown
	rated_capacity::R
	initial_state_of_charge::R
end


"""
	ControlProtocol(cycling_protocol, input; capacity = nothing, T = Float64)

Set up the control protocol from a cycling protocol. The capacity (in Ah) is used for the C-rates and the state of
charge. A "Capacity" given in the cycling protocol takes precedence. If no capacity is given, the theoretical cell
capacity is computed from the cell parameters.
"""
function ControlProtocol(cycling_protocol::CyclingProtocol, input; capacity = nothing, T = Float64)

	use_ramp_up = haskey(input.model_settings, "RampUp")

	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 100

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	elseif isnothing(capacity)
		capacity = compute_cell_theoretical_capacity(input.cell_parameters)
	end

	control_steps = cycling_protocol_to_control_steps(cycling_protocol)

	return ControlProtocol(control_steps, cycling_protocol["InitialStateOfCharge"];
		capacity = capacity, use_ramp_up = use_ramp_up, ramp_up_time = ramp_up_time, T = T)
end


"""
	ControlProtocol(control_steps, initial_state_of_charge; capacity, use_ramp_up = true, ramp_up_time = 100, T = Float64)

Set up the control protocol from a list of control steps following the control step schema. The capacity (in Ah) is
used to convert C-rates to currents and to compute the state of charge.
"""
function ControlProtocol(control_steps::AbstractVector, initial_state_of_charge;
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

	return ControlProtocol{Vector{Int}, R}(steps, step_indices, cycle_counts, final_cycle_count, maximum_current_value, capacity, initial_state_of_charge)
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
		return RestStep(termination)
	elseif control_type == "CurrentFunction"
		current_function = setup_function_from_function_name(step["FunctionName"]; file_path = get(step, "FilePath", nothing))
		return CurrentFunctionStep(current_function, termination)
	elseif control_type == "CurrentSeries"
		return setup_current_series_step(float.(step["Times"]), float.(step["Currents"]),
			float(get(step, "LowerVoltageLimit", -Inf)), float(get(step, "UpperVoltageLimit", Inf)), termination)
	else
		error("Control type $control_type not recognized.")
	end

end


"""
Current at the start of the simulation, used to initialize the state.
"""
function initial_current(protocol::ControlProtocol)
	return initial_current(protocol.steps[1], protocol.rated_capacity)
end


"""
	experiment_is_finished(protocol, controller)

The experiment is finished when the last control step has terminated.
"""
function experiment_is_finished(protocol::ControlProtocol, controller)
	return controller.step_count >= length(protocol.steps)
end

is_last_control_step(protocol::ControlProtocol, controller) = controller.step_count == length(protocol.steps) - 1

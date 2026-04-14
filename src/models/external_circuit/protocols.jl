#######################################################################################################################
# Protocols
#
# A protocol is an implementation of a certain policy or a combination of policies.
#
# This script defines cycling protocol types:
#	- GenericProtocol: a protocol that can contain any combination and order of control steps
#######################################################################################################################


############################################
# Define the abstract type

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
Input current series protocol.

Applies a prescribed current time series (times in seconds, currents in amperes).
The `times` vector must be strictly increasing. A Jutul linear interpolator
(`get_1d_interpolator`) is used to evaluate the current at any simulation time.
Voltage limits are enforced: if the voltage response exceeds `upperCutoffVoltage` or
falls below `lowerCutoffVoltage`, the controller switches to constant-voltage control
at the respective limit. The lengths of `times` and `currents` must match.

Voltage limits may be set to `±Inf` if they should not be enforced.
"""
mutable struct InputCurrentProtocol{R} <: AbstractPolicy
	times::Vector{R}
	current_function::Any      # get_1d_interpolator(times, currents) – callable as f(t)
	lower_voltage_limit::R
	upper_voltage_limit::R

	function InputCurrentProtocol(
		times::AbstractVector,
		currents::AbstractVector,
		lower_voltage_limit::Real,
		upper_voltage_limit::Real,
	)
		@assert length(times) == length(currents) "times and currents must have the same length"
		@assert length(times) >= 1 "times and currents must be non-empty"
		@assert issorted(times, lt = <) "times must be strictly increasing"
		T = promote_type(eltype(times), eltype(currents), typeof(lower_voltage_limit), typeof(upper_voltage_limit))
		current_function = get_1d_interpolator(times, currents, cap_endpoints = true)
		return new{T}(convert(Vector{T}, times), current_function, T(lower_voltage_limit), T(upper_voltage_limit))
	end
end


function get_initial_current(policy::InputCurrentProtocol)
	# Return the current at the first time point using the interpolator
	return policy.current_function(policy.times[1])
end

"""
GenericProtocol
"""
struct GenericProtocol{V, R} <: AbstractProtocol where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	step_counts::V
	cycle_counts::V
	maximum_current::R
	rated_capacity::R
	initial_state_of_charge::R
end

function GenericProtocol(cycling_protocol::Experiment;
	use_ramp_up = true,
	ramp_up_time = 0.1,
	capacity = nothing,
	T = Float64)

	experiment_list = cycling_protocol["Experiment"]

	if isa(experiment_list, String)
		experiment_list = [experiment_list]
	end

	stepper = Stepper([], 0, 0, 0, [], [], [])

	for (idx, step) in enumerate(experiment_list)
		stepper = update_stepper!(stepper, step, idx, experiment_list, capacity, use_ramp_up, ramp_up_time; T = T)
	end

	# Get maximum current value of all steps

	current_values = []
	for step in stepper.steps

		if step isa CurrentStep || step isa RestStep
			push!(current_values, step.value)
		end

	end

	if isempty(current_values)
		error("No current values found.")
	else
		maximum_current = maximum(current_values)
	end

	T = promote_type(T, typeof(maximum_current), typeof(capacity))

	return GenericProtocol{typeof(stepper.step_indices), T}(stepper.steps, stepper.step_indices, stepper.step_counts, stepper.cycle_counts, maximum_current, capacity, cycling_protocol["InitialStateOfCharge"])
end

function GenericProtocol(cycling_protocol::AbstractPolicy, input; T = Float64)

	use_ramp_up = haskey(input.model_settings, "RampUp")

	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 100

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	else
		capacity = compute_cell_theoretical_capacity(input.cell_parameters)
	end

	return GenericProtocol(cycling_protocol; use_ramp_up = use_ramp_up, ramp_up_time = ramp_up_time, capacity = capacity, T = T)
end



function GenericProtocol(cycling_protocol::ConstantCurrent; use_ramp_up = false, ramp_up_time = 10, capacity = nothing, T = Float64)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []

	experiment_list = add_experiment_strings!(experiment_list, cycling_protocol, cycling_protocol["InitialControl"], "CC")


	if cycling_protocol["TotalNumberOfCycles"] > 0
		opposite_direction = get_opposite_direction(cycling_protocol["InitialControl"])
		experiment_list = add_experiment_strings!(experiment_list, cycling_protocol, opposite_direction, "CC")

		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return GenericProtocol(experiment; use_ramp_up, ramp_up_time, capacity, T = T)
end


function GenericProtocol(cycling_protocol::ConstantCurrentConstantVoltage; use_ramp_up = false, ramp_up_time = 10, capacity = nothing, T = Float64)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []

	experiment_list = add_experiment_strings!(experiment_list, cycling_protocol, cycling_protocol["InitialControl"], "CCCV")

	if cycling_protocol["TotalNumberOfCycles"] > 0

		opposite_direction = get_opposite_direction(cycling_protocol["InitialControl"])

		experiment_list = add_experiment_strings!(experiment_list, cycling_protocol, opposite_direction, "CCCV")

		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return GenericProtocol(experiment; use_ramp_up, ramp_up_time, capacity, T = T)
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

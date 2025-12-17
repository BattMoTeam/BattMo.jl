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
GenericProtocol
"""
struct GenericProtocol{V} <: AbstractProtocol where V <: Vector{Int}
	steps::Vector{AbstractControlStep}
	step_indices::V
	step_counts::V
	cycle_counts::V
	maximum_current::Real
	rated_capacity::Real
	initial_state_of_charge::Real
end

function GenericProtocol(cycling_protocol::Experiment;
	use_ramp_up = true,
	ramp_up_time = 0.1,
	capacity = nothing)

	experiment_list = cycling_protocol["Experiment"]

	if isa(experiment_list, String)
		experiment_list = [experiment_list]
	end

	stepper = Stepper([], 0, 0, 0, [], [], [])

	for (idx, step) in enumerate(experiment_list)
		stepper = update_stepper!(stepper, step, idx, experiment_list, capacity, use_ramp_up, ramp_up_time)
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

	return GenericProtocol{typeof(stepper.step_indices)}(stepper.steps, stepper.step_indices, stepper.step_counts, stepper.cycle_counts, maximum_current, capacity, cycling_protocol["InitialStateOfCharge"])
end

function GenericProtocol(cycling_protocol::AbstractPolicy, input)

	use_ramp_up = haskey(input.model_settings, "RampUp")

	ramp_up_time = haskey(input.simulation_settings, "RampUpTime") ? input.simulation_settings["RampUpTime"] : 100

	if haskey(cycling_protocol, "Capacity")
		capacity = cycling_protocol["Capacity"]
	else
		capacity = compute_cell_theoretical_capacity(input.cell_parameters)
	end

	return GenericProtocol(cycling_protocol; use_ramp_up = use_ramp_up, ramp_up_time = ramp_up_time, capacity = capacity)
end



function GenericProtocol(cycling_protocol::ConstantCurrent; use_ramp_up = false, ramp_up_time = 10, capacity = nothing)
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

	return GenericProtocol(experiment; use_ramp_up, ramp_up_time, capacity)
end


function GenericProtocol(cycling_protocol::ConstantCurrentConstantVoltage; use_ramp_up = false, ramp_up_time = 10, capacity = nothing)
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

	return GenericProtocol(experiment; use_ramp_up, ramp_up_time, capacity)
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

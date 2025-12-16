#######################################################################################################################
# Policies
#
# A policy is a specific type of control
#
# This script defines policies:
#	- ConstantCurrent: a constant current control
#	- ConstantCurrentConstantVoltage: a constant current constant voltage control
# 	- Experiment: a flexible experiment like control
#
# These policy types are defined to create different user APIs for the generic control. The user can use the flexible 
# experiment strings API or the specific policy ConstantCurrent or ConstantCurrentConstantVoltage API
#
#######################################################################################################################


abstract type AbstractPolicy end


##################################################
# Define the different policy types

struct Experiment <: AbstractPolicy
	all::AbstractDict
end

struct ConstantCurrent <: AbstractPolicy
	all::AbstractDict
end

struct ConstantCurrentConstantVoltage <: AbstractPolicy
	all::AbstractDict
end



#################################################################################
# Define extensions for commonly used base functions for the AbstractPolicy type

function Base.getindex(ps::AbstractPolicy, key::String)
	value = get(ps.all, key, nothing)
	if value === nothing
		error("Parameter not found: $key")
	else
		return value
	end
end

function Base.setindex!(ps::AbstractPolicy, value, key::String)
	ps.all[key] = value
end

function Base.haskey(ps::AbstractPolicy, key::String)
	return haskey(ps.all, key)
end



#################################################################################
# Functions and types used to parse the experiment cycling protocol

mutable struct Stepper
	steps::Vector{AbstractControlStep}
	step_count::Int
	step_index::Int
	cycle_count::Int
	step_counts::Vector{Int}
	step_indices::Vector{Int}
	cycle_counts::Vector{Int}
end


"""
Add a parsed step to the lists and update indices.
"""
function add_step!(stepper, step_instance)
	if !isnothing(step_instance)
		push!(stepper.steps, step_instance)
		push!(stepper.step_indices, stepper.step_index)
		push!(stepper.step_counts, stepper.step_count)
		push!(stepper.cycle_counts, stepper.cycle_count)
		stepper.step_index += 1
		stepper.step_count += 1
	end
	return stepper
end

"""
Handle repeats for a given list of previous steps.
"""
function handle_repeats!(stepper, previous_steps, number_of_repeats, experiment_list, capacity, use_ramp_up, ramp_up_time; depth = 1, max_depth = 10)
	if depth > max_depth
		error("Exceeded maximum repeat depth to prevent infinite recursion.")
	end

	for _ in 1:number_of_repeats
		for (idx, prev_step) in enumerate(previous_steps)
			stepper = update_stepper!(stepper, prev_step, idx, experiment_list, capacity, use_ramp_up, ramp_up_time; depth = depth+1, max_depth = max_depth)
		end
	end
	return stepper
end


"""
Process a single step (String or Vector).
"""

function update_stepper!(stepper, step, idx, experiment_list, capacity, use_ramp_up, ramp_up_time; depth = 1, max_depth = 10)
	if step isa String
		step_instance, increase_cycle_count, number_of_repeats = parse_experiment_step(step, capacity, use_ramp_up; ramp_up_time)
		stepper = add_step!(stepper, step_instance)
		if increase_cycle_count
			stepper.cycle_count += 1
			stepper.step_index = 0
		end
		if !isnothing(number_of_repeats)
			previous_strings = experiment_list[1:(idx-1)]
			stepper = handle_repeats!(stepper, previous_strings, number_of_repeats, experiment_list, capacity, use_ramp_up, ramp_up_time; depth = depth, max_depth = max_depth)
		end

	elseif step isa Vector
		for (idx_sub, sub_step) in enumerate(step)
			sub_instance, increase_cycle_count, number_of_repeats = parse_experiment_step(sub_step, capacity, use_ramp_up; ramp_up_time)
			stepper = add_step!(stepper, sub_instance)
			if increase_cycle_count
				stepper.cycle_count += 1
				stepper.step_index = 0

			end
			if !isnothing(number_of_repeats)
				previous_strings = step[1:(idx_sub-1)]
				stepper = handle_repeats!(stepper, previous_strings, number_of_repeats, experiment_list, capacity, use_ramp_up, ramp_up_time; depth = depth, max_depth = max_depth)
			end
		end
	else
		error("Experiment step must be a String or Vector.")
	end

	return stepper
end

function parse_experiment_step(step::String, capacity::Real, use_ramp_up::Bool; ramp_up_time = 0.1)
	increase_cycle_count = false
	number_of_repeats = nothing
	step_instance = nothing

	if containsi(step, "Rest")
		step_processed = process_values(step, capacity)

		termination = get_termination_instance(step_processed[:termination][:type], step_processed[:termination][:target])

		step_instance = RestStep(0.0, termination)

	elseif containsi(step, "Discharge") || containsi(step, "Charge")
		step_processed = process_values(step, capacity)

		control_type = step_processed[:control][:type]

		termination = get_termination_instance(step_processed[:termination][:type], step_processed[:termination][:target]; direction = step_processed[:control][:direction])

		if control_type == "Current"
			step_instance = CurrentStep(step_processed[:control][:target], step_processed[:control][:direction], termination, use_ramp_up; ramp_up_time)
		elseif control_type == "Power"
			step_instance = PowerStep(step_processed[:control][:target], step_processed[:control][:direction], termination)
		else
			error("Quantity $control_type is not recognized as control step for a charge or discharge.")
		end

	elseif containsi(step, "Hold")
		step_processed = process_values(step, capacity)

		termination = get_termination_instance(step_processed[:termination][:type], step_processed[:termination][:target])

		control_type = step_processed[:control][:type]
		if control_type == "Voltage"
			step_instance = VoltageStep(step_processed[:control][:target], termination)
		elseif control_type == "StateOfCharge"
			step_instance = StateOfChargeStep(step_processed[:control][:target], termination)
		else
			error("Quantity $control_type is not recognized as control step for a charge or discharge.")
		end


	elseif containsi(step, "Increase cycle count")
		increase_cycle_count = true

	elseif containsi(step, "Repeat")
		number_of_repeats = Base.parse(Int, match(r"\d+", step).match)
	else
		error("Unknown control step: $step")
	end

	return step_instance, increase_cycle_count, number_of_repeats

end


function parse_number_or_fraction(s::AbstractString)::Float64
	s = strip(s)
	if occursin('/', s)
		a, b = split(s, '/'; limit = 2)
		return Base.parse(Float64, strip(a)) / Base.parse(Float64, strip(b))
	else
		return Base.parse(Float64, s)  # handles "0.5", "1e-3", etc.
	end
end



function process_values(str::AbstractString, capacity)
	# Split the string into parts by spaces
	parts = split(str)

	if parts[2] == "at"
		control_target = parse_number_or_fraction(parts[3])
		control_unit = parts[4]

		control_direction = type_to_direction(parts[1])
		control_target, control_type = type_to_unit(control_target, control_unit; capacity)


		if parts[5] in ["for", "until"]
			if length(parts) <= 7
				termination_target = parse_number_or_fraction(parts[6])
				termination_unit = parts[7]

				termination_target, termination_type = type_to_unit(termination_target, termination_unit; capacity)

			elseif length(parts) > 7 && parts[8] == "or"

				termination_target = parse_number_or_fraction(parts[6])
				termination_unit = parts[7]

				termination_target, termination_type = type_to_unit(termination_target, termination_unit; capacity)

				if parts[9] in ["for", "until"]

					termination_target_2 = parse_number_or_fraction(parts[10])
					termination_unit_2 = parts[11]
					termination_target_2, termination_type_2 = type_to_unit(termination_target_2, termination_unit_2; capacity)

					termination_target = [termination_target, termination_target_2]
					termination_type = [termination_type, termination_type_2]

				else
					error("Conditional termination does not recognize $(parts[6])")
				end
			else
				error("The conditional termination does not have the correct structure.")

			end
		else
			error("$(parts[5]) in experiment string not recognized.")
		end

	elseif parts[2] in ["for", "until"]
		control_type = nothing
		control_target = nothing
		control_direction = nothing

		if length(parts) <= 4
			termination_target = parse_number_or_fraction(parts[3])
			termination_unit = parts[4]

			termination_target, termination_type = type_to_unit(termination_target, termination_unit)

		elseif length(parts) > 4 && parts[5] == "or"

			termination_target = parse_number_or_fraction(parts[3])
			termination_unit = parts[4]

			termination_target, termination_type = type_to_unit(termination_target, termination_unit)


			if parts[6] in ["for", "until"]

				termination_target_2 = parse_number_or_fraction(parts[7])
				termination_unit_2 = parts[8]

				termination_target_2, termination_type_2 = type_to_unit(termination_target_2, termination_unit_2)

				termination_target = [termination_target, termination_target_2]
				termination_type = [termination_type, termination_type_2]
			else
				error("Conditional termination does not recognize $(parts[6])")
			end
		else
			error("The conditional termination does not have the correct structure.")

		end
	else
		error("$(parts[2]) in experiment string not recognized.")
	end

	step_dict = Dict(
		:control => Dict(
			:type=>control_type,
			:target => control_target,
			:direction => control_direction,
		),
		:termination => Dict(
			:type => termination_type,
			:target => termination_target,
		))



	return step_dict
end


function type_to_direction(value::AbstractString)

	if value == "Charge"
		direction = "charging"
	elseif value == "Discharge"
		direction = "discharging"
	else
		direction = nothing
	end
	return direction
end

function type_to_unit(value::Float64, unit::AbstractString; capacity = nothing)
	if containsi(unit, "V")
		if containsi(unit, "V/")
			quantity = "VoltageChange"
			return convert_to_V_s(value, unit), quantity
		else
			quantity = "Voltage"
			return convert_to_V(value, unit), quantity
		end
	elseif containsi(unit, "A")
		if containsi(unit, "A/")
			quantity = "CurrentChange"
			return convert_to_A_s(value, unit), quantity
		else
			quantity = "Current"
			return convert_to_A(value, unit), quantity
		end
	elseif any(tu -> lowercase(unit) == lowercase(tu), time_units())
		return convert_to_seconds(value, unit), "Time"
	elseif containsi(unit, "C")
		if containsi(unit, "SOC")
			return value, "StateOfCharge"
		else
			return convert_to_A(value, unit; capacity), "Current"
		end
	elseif containsi(unit, "W")
		return convert_to_W(value, unit), "Power"
	else
		error("Unknown unit: $unit")
	end
end

function time_units()
	return ["s", "second", "seconds", "min", "minute", "minutes", "mins", "h", "hour", "hours"]
end

function convert_to_seconds(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit_lower = lowercase(unit)
	if unit_lower in ["s", "second", "seconds"]
		return value
	elseif unit_lower in ["min", "minute", "minutes", "mins"]
		return value * 60
	elseif unit_lower in ["h", "hour", "hours"]
		return value * 3600
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_V(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit_part = unit

	if unit_part == "V"
		return value
	elseif unit_part == "mV"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_A(value::Float64, unit::AbstractString; capacity = nothing)
	@assert isa(value, Number)
	unit_part = unit
	if unit_part == "A"
		return value
	elseif unit_part == "mA"
		return value * 1e-3
	elseif unit_part == "C"
		con = Constants()

		value = capacity * value

		return value
	else
		error("Unknown unit: $unit")
	end
end

function convert_to_W(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	if unit == "W"
		return value
	elseif unit == "mW"
		return value * 1e-3
	else
		error("Unknown unit: $unit")
	end
end


function convert_to_V_s(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit = strip(unit)

	parts = split(unit, '/')
	if length(parts) != 2
		error("Invalid unit format for voltage change: $unit")
	end

	voltage_unit = parts[1]
	time_unit = parts[2]

	# Use existing conversion functions
	voltage_in_volts = convert_to_V(1.0, voltage_unit)  # scale factor for voltage
	time_in_seconds = convert_to_seconds(1.0, time_unit) # scale factor for time

	return value * voltage_in_volts / time_in_seconds
end


function convert_to_A_s(value::Float64, unit::AbstractString)
	@assert isa(value, Number)
	unit = strip(unit)

	parts = split(unit, '/')
	if length(parts) != 2
		error("Invalid unit format for current change: $unit")
	end

	current_unit = parts[1]
	time_unit = parts[2]

	# Use existing conversion functions
	current_in_amperes = convert_to_A(1.0, current_unit)  # scale factor for current
	time_in_seconds = convert_to_seconds(1.0, time_unit) # scale factor for time

	return value * current_in_amperes / time_in_seconds
end


function containsi(a::AbstractString, b::AbstractString)
	return occursin(Regex(b, "i"), a)
end

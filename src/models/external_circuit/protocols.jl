export GenericProtocol

abstract type AbstractProtocol end

struct GenericProtocol <: AbstractProtocol
	steps::Vector{AbstractControlStep}
	step_indices::Vector{Int}
	cycle_numbers::Vector{Int}

	function GenericProtocol(cycling_protocol)
		experiment_list = cycling_protocol["Experiment"]
		if isa(experiment_list, String)
			experiment_list = [experiment_list]
		end

		steps = []
		step_indices = []
		cycle_numbers = []

		index = 0
		for step in experiment_list

			index += 1

			push!(step_indices, index)
			push!(cycle_numbers, index)

			if containsi(step, "Rest")
				values, units = extract_numeric_values(step)
				value = convert_to_seconds(values[1], units[1])

				time_termination = Termination("time", value)
				rest_step = RestStep(value, time_termination)

				push!(steps, rest_step)

			elseif containsi(step, "Discharge") || containsi(step, "Charge")
				direction = containsi(step, "Discharge") ? "discharging" : "charging"
				comparison = containsi(step, "Discharge") ? "below" : "above"

				values, units = extract_numeric_values(step)
				value1, quantity1 = type_to_unit(values[1], units[1])
				@assert lowercase(quantity1) == "current" "Cannot $direction with $quantity1, can only use current"

				value2, quantity2 = type_to_unit(values[2], units[2])

				termination = Termination(quantity2, value2; comparison = comparison)
				current_step = CurrentStep(value1, direction, termination, missing)

				push!(steps, current_step)

			elseif containsi(step, "Hold")
				values, units = extract_numeric_values(step)
				value1 = convert_to_V(values[1], units[1])
				value2, quantity2 = type_to_unit(values[2], units[2])

				termination = Termination(quantity2, value2; comparison = "absolute value below")
				voltage_step = VoltageStep(value1, termination)

				push!(steps, voltage_step)

			else
				error("Unknown control step: $step")
			end

		end

		return new(steps, step_indices, cycle_numbers)
	end


end



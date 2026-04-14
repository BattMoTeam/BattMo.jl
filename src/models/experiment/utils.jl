#######################################################################################################################
# External circuit utils
#
# This script defines some helper function used within the external circuit model
#######################################################################################################################

function calculate_total_time(cycling_protocol)
	number_of_cycles = cycling_protocol["TotalNumberOfCycles"]
	d_rate = haskey(cycling_protocol, "DRate") ? cycling_protocol["DRate"] : nothing
	c_rate = haskey(cycling_protocol, "CRate") ? cycling_protocol["CRate"] : nothing

	con = Constants()
	if number_of_cycles == 0

		if !isnothing(d_rate)
			total_time = 1.1 * con.hour / d_rate
		elseif !isnothing(c_rate)
			total_time = 1.1 * con.hour / c_rate
		end

	else
		total_time = number_of_cycles * 2.5 * (1 * con.hour / c_rate + 1 * con.hour / d_rate)
	end
	return total_time

end

function get_opposite_direction(direction)
	return isequal(direction, "charging") ? "discharging" : "charging"
end

function adjust_current_sign(I, direction)
	if direction == "discharging"
		val = I
	elseif direction == "charging"
		val = -I
	else
		error("The direction $direction is not recognized.")
	end

	return val
end

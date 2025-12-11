#######################################################################################################################
# Ramp up
#
# A ramp up is a slow increase of current at the start of a simulation to reduce convergence issues.
#
#######################################################################################################################


"""
Sonusoidal current rampup function
"""
function sineup(y1, y2, x1, x2, x)
	#SINEUP Creates a sine ramp function
	#
	#   res = sineup(y1, y2, x1, x2, x) creates a sine ramp
	#   starting at value y1 at point x1 and ramping to value y2 at
	#   point x2 over the vector x.
	y1, y2, x1, x2, x = promote(y1, y2, x1, x2, x)
	T = typeof(x)

	dy = y1 - y2
	dx = abs(x1 - x2)

	res = zero(T)

	if (x >= x1) && (x <= x2)
		res = dy / 2.0 .* cos(pi .* (x - x1) ./ dx) + y1 - (dy / 2)
	end

	if (x > x2)
		res .+= y2
	end

	if (x < x1)
		res .+= y1
	end

	return res

end


function compute_rampup_timesteps(time::Real, dt::Real, n::Integer = 8)

	ind = collect(range(n, 1, step = -1))
	dt_init = [dt / 2^k for k in ind]
	cs_time = cumsum(dt_init)
	if any(cs_time .> time)
		dt_init = dt_init[cs_time .< time]
	end
	dt_left = time .- sum(dt_init)

	# Even steps
	dt_rem = dt * ones(floor(Int64, dt_left / dt))
	# Final ministep if present
	dt_final = time - sum(dt_init) - sum(dt_rem)
	# Less than to account for rounding errors leading to a very small
	# negative time-step.
	if dt_final <= 0
		dt_final = []
	end
	# Combined timesteps
	dT = [dt_init; dt_rem; dt_final]

	return dT
end

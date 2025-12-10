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

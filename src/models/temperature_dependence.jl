""" Arrhenius model for temperature dependence of diffusion coefficients and reaction rates
"""
function arrhenius(T, A0, Ea)

	F = FARADAY_CONSTANT
	refT = 298.15

	val = A0 .* exp(-Ea ./ F .* (1.0 ./ T - 1 / refT))
	return val

end
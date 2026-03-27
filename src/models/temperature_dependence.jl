""" Arrhenius model for temperature dependence of diffusion coefficients and reaction rates
"""
@noinline function arrhenius(T, A0, Ea)

	R = GAS_CONSTANT
	refT = 298.15
	val = A0 .* exp(-Ea ./ R .* (1.0 ./ T - 1 / refT))
	return val

end

@inline function temperature_dependent(T, A0, Ea, dependent)

	if dependent == :Arrhenius
		val = arrhenius(T, A0, Ea)
	else
		val = A0
	end
	return val

end

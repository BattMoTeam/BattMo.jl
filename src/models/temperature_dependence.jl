""" Default reference temperature, used when "ReferenceTemperature" is not given in the "Cell" parameters
"""
const DEFAULT_REFERENCE_TEMPERATURE = 298.15

""" Reference temperature of an active material system, falling back to the default if not set
"""
function get_reference_temperature(system)
    params = system.params
    return haskey(params, :reference_temperature) ? params[:reference_temperature] : DEFAULT_REFERENCE_TEMPERATURE
end

""" Arrhenius model for temperature dependence of diffusion coefficients and reaction rates
"""
@noinline function arrhenius(T, A0, Ea, refT = DEFAULT_REFERENCE_TEMPERATURE)

    R = GAS_CONSTANT
    val = A0 .* exp(-Ea ./ R .* (1.0 ./ T - 1 / refT))
    return val

end

@inline function temperature_dependent(T, A0, Ea, dependent, refT = DEFAULT_REFERENCE_TEMPERATURE)

    if dependent == :Arrhenius
        val = arrhenius(T, A0, Ea, refT)
    else
        val = A0
    end
    return val

end

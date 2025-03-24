export 
    computeDiffusionCoefficient_default,
    computeDiffusionCoefficient_Chen2020,
    computeDiffusionCoefficient_Xu2015

const diff_params = [
    -4.43   -54 ;
    -0.22   0.0 ;
]
const Tgi = [229 5.0]

@inline function computeDiffusionCoefficient_default(c::Real, T::Real)
    """ Compute the diffusion coefficient as a function of temperature and concentration
    """
    return (
        1e-4 * 10 ^ ( 
            diff_params[1,1] + 
            diff_params[1,2]/(T - Tgi[1] - Tgi[2]*c* 1e-3) + 
            diff_params[2,1]*c*1e-3
            )
        )
end

@inline function computeDiffusionCoefficient_Chen2020(c::Real, T::Real)
    """ Compute the diffusion coefficient as a function of concentration
    """
    c = c/1000
    return 8.794*10^(-11)*c^2 - 3.972*10^(-10)*c + 4.862*10^(-10)
end


@inline function computeDiffusionCoefficient_Xu2015(c::Real, T::Real)
    """ Compute the diffusion coefficient as a function of concentration
    """
    # Calculate diffusion coefficients constant for the diffusion coefficient calculation
    cnst = [ -4.43 -54 
             -0.22 0.0 ]

    Tgi = [ 229 5.0 ]
    
    # Diffusion coefficient, [m^2 s^-1]
    #Removed 10⁻⁴ otherwise the same
    D = 10^( ( cnst[1,1] + cnst[1,2] / ( T - Tgi[1] - Tgi[2] * c * 1e-3) + cnst[2,1] * c * 1e-3) )
    return D
end
def electrolyte_conductivity_Xu_2015(c, T):
    """Compute the electrolyte conductivity as a function of concentration"""
    conductivity = (
        c
        * 1e-4
        * 1.2544
        * (
            -8.2488
            + 0.053248 * T
            - 2.987e-5 * (T**2)
            + 0.26235e-3 * c
            - 9.3063e-6 * c * T
            + 8.069e-9 * c * (T**2)
            + 2.2002e-7 * (c**2)
            - 1.765e-10 * T * (c**2)
        )
    )
    return conductivity


def electrolyte_diffusivity_Xu_2015(c, T):
    """Compute diffusion coefficient as a function of concentration and temperature"""
    cnst = [[-4.43, -54.0], [-0.22, 0.0]]
    Tgi = [229, 5.0]
    D = 10 ** (cnst[0][0] + cnst[0][1] / (T - Tgi[0] - Tgi[1] * c * 1e-3) + cnst[1][0] * c * 1e-3)
    return D

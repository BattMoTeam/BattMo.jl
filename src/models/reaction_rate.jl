export reaction_rate, compute_reaction_rate_constant, reaction_rate_coefficient

function butler_volmer_equation(j0, alpha, n, eta, T)

    F = FARADAY_CONSTANT
    R = GAS_CONSTANT
    
    val = j0*(exp(alpha*n*F*eta/(R*T)) - exp(-(1-alpha)*n*F*eta/(R*T)))
   
    return val
    
end

function regularized_sqrt(x::T, th::Float64) where {T<:Any}
    x, th = promote(x, th)
    y = zero(T)
    if x <= th
        y = x/th*sqrt(th)
    else
        y = x^0.5
    end
    return y
end

function reaction_rate_coefficient(R0,
                                   c_e,
                                   c_a,
                                   activematerial)
    
    F = FARADAY_CONSTANT
    
    n    = activematerial.params[:n_charge_carriers]
    cmax = activematerial.params[:maximum_concentration]
    
    th = 1e-3*cmax
    j0 = R0*regularized_sqrt(c_e*(cmax - c_a)*c_a, th)*n*F
    
    return j0
    
end

## Defines standard exchange current density

function compute_reaction_rate_constant(c, T, k0, Eak)

    F = FARADAY_CONSTANT
    refT = 298.15

    val = k0.*exp(-Eak./F.*(1.0./T - 1/refT));
    return val
    
end


function compute_reaction_rate_constant_graphite(c, T)

    refT = 298.15
    k0   = 5.0310e-11
    Eak  = 5000
    val  = k0.*exp(-Eak./FARADAY_CONSTANT .*(1.0./T - 1/refT));
    
    return val
    
end

function reaction_rate(eta           ,
                       c_a           ,
                       R0            ,
                       T             ,
                       c_e           ,
                       activematerial,
                       electrolyte
                       )

    F = FARADAY_CONSTANT

    n = activematerial.params[:n_charge_carriers]
    
    j0 = reaction_rate_coefficient(R0, c_e, c_a, activematerial)
    R  = butler_volmer_equation(j0, 0.5, n, eta, T)

    return R/(n*F)
    
end
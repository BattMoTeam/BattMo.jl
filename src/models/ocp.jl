export ocp_form

## Defines OCP and entropy change (dUdT) for graphite using polynomials
using Interpolations
const coeff1_graphite = Polynomial([
	+ 0.005269056,
	+ 3.299265709,
	- 91.79325798,
	+ 1004.911008,
	- 5812.278127,
	+ 19329.75490,
	- 37147.89470,
	+ 38379.18127,
	- 16515.05308
]);

const coeff2_graphite = Polynomial([
	1,
	- 48.09287227,
	+ 1017.234804,
	- 10481.80419,
	+ 59431.30000,
	- 195881.6488,
	+ 374577.3152,
	- 385821.1607,
	+ 165705.8597
]);


############## Lorena ##############

# function compute_ocp_function_from_data(x,y, extrapolate)
#     """Compute the OCP interpolated function for a material based on the given data"""
   
#     if extrapolate
#         interp_linear_extrap = linear_interpolation(x, y,extrapolation_bc=Line())
#     end

# end

# macro evaluate_ocp_function(ex, c, T, cmax)
#     quote
#         Tref = 298.15
#         ex = "f(c,T,cmax,Tref) = " + $esc(ex)
#         :(eval(Meta.parse($esc(ex))))
#         return f(c,T,cmax,Tref)
#     end
    #Tref = 298.15
# end
# c = 1
# T = 298
# cmax = 1
# Tref = 299
function compute_ocp_function(ocp_eq)
    
    eval(Meta.parse(ocp_eq))
end


function compute_ocp_from_function(ocp_eq)
    """Compute OCP for a material as function of temperature and concentration"""
    
    #print("ex = ", f(c,T,cmax,Tref))
    return compute_ocp_function(ocp_eq)
    #@evaluate_ocp_function $esc(ex) c T cmax
    #eval(Meta.parse(ex))

end




####################################


function compute_ocp_graphite(c, T, cmax)
    """Compute OCP for GenericGraphite as function of temperature and concentration"""
    theta  = c./cmax
    refT   = 298.15
    refOCP = (0.7222
              + 0.1387 * theta
              + 0.0290 * theta^0.5
              - 0.0172 / theta
              + 0.0019 / theta^1.5
              + 0.2808 * exp(0.9 - 15.0*theta)
              - 0.7984 * exp(0.4465*theta - 0.4108)
	      );

    dUdT = 1e-3*coeff1_graphite(theta)/ coeff2_graphite(theta);
    
    ocp = refOCP + (T - refT) * dUdT;
    
    return ocp
    
end


function compute_reaction_rate_constant_graphite(c, T)

    refT = 298.15
    k0   = 5.0310e-11
    Eak  = 5000
    val  = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
    
end

## Define OCP and entropy change (dUdT) for NMC111 using polynomials

const coeff1_refOCP_nmc111 = Polynomial([
    -4.656,
    0,
    + 88.669,
    0,
    - 401.119,
    0,
    + 342.909,
    0,
    - 462.471,
    0,
    + 433.434
]);

const coeff2_refOCP_nmc111 =Polynomial([
    -1,
    0 ,
    + 18.933,
    0,
    - 79.532,
    0,
    + 37.311,
    0,
    - 73.083,
    0,
    + 95.960
])

const coeff1_dUdT_nmc111 = Polynomial([
    0.199521039,
    - 0.928373822,
    + 1.364550689000003,
    - 0.611544893999998
]);

const coeff2_dUdT_nmc111 = Polynomial([
    1,
    - 5.661479886999997,
    + 11.47636191,
    - 9.82431213599998,
    + 3.048755063
])

function compute_ocp_nmc111(c, T, cmax)
    
    """Compute OCP for GenericNMC111 as function of temperature and concentration"""
    refT   = 298.15
    theta  = c/cmax
    refOCP = coeff1_refOCP_nmc111(theta)/coeff2_refOCP_nmc111(theta)
    dUdT   = -1e-3*coeff1_dUdT_nmc111(theta)/coeff2_dUdT_nmc111(theta)
    ocp    = refOCP + (T - refT) * dUdT
    
    return ocp
    
end

## Defines standard exchange current density

function compute_reaction_rate_constant(c, T, k0, Eak)
    
    refT = 298.15

    val = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
    
end





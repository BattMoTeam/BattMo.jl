## Defines OCP and entropy change (dUdT) for graphite using polynomials

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

function compute_ocp_graphite(T, c, cmax)
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

function compute_reaction_rate_constant_graphite(T, c)

    refT = 298.15
    k0   = 5.0310e-11
    Eak  = 5000
    val  = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
    
end

## Define solid diffusion coefficient for GenericGraphite

function compute_diffusion_coef_graphite(T, c)
    
    refT = 298.15
    D0   = 3.9e-12
    Ead  = 5000
    val  = D0.*exp(-Ead./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end


graphite_params = Dict{Symbol, Any}()

graphite_params[:ocp_func]                    = getfield(BattMo, :compute_ocp_graphite)
graphite_params[:n_charge_carriers]           = 1
graphite_params[:reaction_rate_constant_func] = getfield(BattMo, :compute_reaction_rate_constant_graphite)
graphite_params[:maximum_concentration]       = 30555
graphite_params[:volumetric_surface_area]     = 723600
graphite_params[:diffusion_coef_func]         = compute_diffusion_coef_graphite


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

function compute_ocp_nmc111(T, c, cmax)
    
    """Compute OCP for GenericNMC111 as function of temperature and concentration"""
    refT   = 298.15
    theta  = c/cmax
    refOCP = coeff1_refOCP_nmc111(theta)/coeff2_refOCP_nmc111(theta)
    dUdT   = -1e-3*coeff1_dUdT_nmc111(theta)/coeff2_dUdT_nmc111(theta)
    ocp    = refOCP + (T - refT) * dUdT
    
    return ocp
    
end


## Defines exchange current density for GenericGraphite

function compute_reaction_rate_constant_nmc111(T, c)
    
    refT = 298.15
    k0   = 2.3300e-11
    Eak  = 5000

    val = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end


## Define solid diffusion coefficient for NMC

function compute_diffusion_coef_nmc111(T, c)
    
    refT = 298.15
    D0   = 1e-12
    Ead  = 5000

    val = D0.*exp(-Ead./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end

nmc111_params = Dict{Symbol, Any}()

nmc111_params[:ocp_func]                    = compute_ocp_nmc111
nmc111_params[:n_charge_carriers]           = 1
nmc111_params[:reaction_rate_constant_func] = compute_reaction_rate_constant_nmc111
nmc111_params[:maximum_concentration]       = 55554.0
nmc111_params[:volumetric_surface_area]     = 885000.0
nmc111_params[:diffusion_coef_func]         = compute_diffusion_coef_nmc111


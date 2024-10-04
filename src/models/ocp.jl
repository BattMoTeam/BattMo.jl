using Polynomials
## Defines OCP and entropy change (dUdT) for graphite using polynomials

export AbstractOcp

abstract type AbstractOcp <: Potential end

con = Constants()
const FARADAY_CONSTANT = con.F

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

function computeOCP_Graphite_Torchio(c, T, cmax)
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
    val  = k0.*exp(-Eak./FARADAY_CONSTANT .*(1.0./T - 1/refT));
    
    return val
    
end


## Define OCP for Graphite-SiOx (Chen2020) using polynomials

function computeOCP_Graphite_SiOx_Chen2020(c, T, cmax)
    x = c./cmax

    ocp = 1.9793 * exp(-39.3631 * x) + 0.2482 - 0.0909 * tanh(29.8538 * (x - 0.1234)) - 0.04478 * tanh(14.9159 * (x - 0.2769))  - 0.0205 * tanh(30.4444 * (x - 0.6103))


    return ocp
end

## Define OCP for NMC811 (Chen2020) using polynomials

function computeOCP_NMC811_Chen2020(c, T, cmax)
    x = c./cmax

    ocp = -0.8090 * x + 4.4875 - 0.0428 * tanh(18.5138 * (x - 0.5542)) - 17.7326 * tanh(15.7890 * (x - 0.3117)) + 17.5842 * tanh(15.9308 * (x - 0.3120))


    return ocp
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

function computeOCP_Graphite_Xu2015(c, T, cmax)

    """Compute OCP for LFP as function of temperature and concentration"""
    refT   = 298.15
    theta  = c./cmax

    data1 = [0.00 1.28683
            0.01 0.65272
            0.02 0.52621
            0.03 0.44128
            0.04 0.37552
            0.05 0.32567
            0.10 0.21665
            0.15 0.18623
            0.20 0.16445
            0.25 0.14548
            0.30 0.13293
            0.35 0.12635
            0.40 0.12300
            0.45 0.12036
            0.50 0.11606
            0.55 0.10811
            0.60 0.09833
            0.65 0.09146
            0.70 0.08829
            0.75 0.08696
            0.80 0.08592
            0.85 0.08369
            0.90 0.07698
            0.95 0.05692
            0.96 0.04980
            0.97 0.04118
            0.98 0.03086
            0.99 0.01865
            1.00 0.00443]

    x1 = data1[:, 1]
    y1 = data1[:, 2]

    itp_refOCP = get_1d_interpolator(x1,y1, cap_endpoints=false)

    refOCP = itp_refOCP(theta)

    data2 = [0.01049 3.00E-04
            0.03146 2.47E-04
            0.05244 1.95E-04
            0.07711 1.33E-04
            0.1006  7.21E-05
            0.1302  5.09E-05
            0.145   3.38E-05
            0.1672  2.46E-06
            0.2153  -6.32E-05
            0.2696  -1.36E-04
            0.3399  -1.55E-04
            0.3991  -1.45E-04
            0.4497  -1.25E-04
            0.4806  -8.22E-05
            0.5484  -7.41E-05
            0.6292  -7.31E-05
            0.7199  -9.32E-05
            0.76    -1.14E-04]

    x2 = data2[:, 1]
    y2 = data2[:, 2]

    itp_dUdT = get_1d_interpolator(x2,y2,cap_endpoints = false)
    dUdT = itp_dUdT(theta)

    ocp    = refOCP + (T - refT) * dUdT
    
    return ocp
    
end


function computeOCP_LFP_Xu2015(c, T, cmax)
    
    """Compute OCP for LFP as function of temperature and concentration"""
    refT   = 298.15
    theta  = c./cmax

    data1 = [
        0.00 4.1433
        0.01 3.9121
        0.02 3.7272
        0.03 3.6060
        0.04 3.5326
        0.05 3.4898
        0.10 3.4360
        0.15 3.4326
        0.20 3.4323
        0.25 3.4323
        0.30 3.4323
        0.35 3.4323
        0.40 3.4323
        0.45 3.4323
        0.50 3.4323
        0.55 3.4323
        0.60 3.4323
        0.65 3.4323
        0.70 3.4323
        0.75 3.4323
        0.80 3.4322
        0.85 3.4311
        0.90 3.4142
        0.95 3.2515
        0.96 3.1645
        0.97 3.0477
        0.98 2.8999
        0.99 2.7312
        1.00 2.5895
    ]
    x1 = data1[:, 1]
    y1 = data1[:, 2]

    itp_refOCP = get_1d_interpolator(x1,y1, cap_endpoints=false)

    refOCP = itp_refOCP(theta)

    data2 = [
        9.51362e-3 -4.04346e-4
        1.47563e-2 -2.98844e-4
        1.88127e-2 -2.07750e-4
        2.96637e-2 -1.51978e-4
        3.93120e-2 -1.03643e-4
        4.33465e-2 -3.25336e-6
        4.85859e-2  1.03643e-4
        7.50118e-2  2.27735e-5
        9.89830e-2 -5.20537e-5
        1.48402e-1 -5.15890e-5
        1.98433e-1 -5.15890e-5
        2.46058e-1 -6.64615e-5
        2.98568e-1 -8.31930e-5
        3.76665e-1 -8.31930e-5
        4.72455e-1 -8.31930e-5
        5.49330e-1 -8.27282e-5
        5.99287e-1 -5.15890e-5
        6.48694e-1 -4.60118e-5
        6.99324e-1 -4.13641e-5
        7.49958e-1 -3.85755e-5
        7.99373e-1 -3.62517e-5
        8.48853e-1 -6.18138e-5
        8.98889e-1 -6.41376e-5
        9.48941e-1 -7.29682e-5
        9.62152e-1 -2.42143e-4
        9.79765e-1 -4.67089e-4
        9.84685e-1 -2.24482e-4
        9.89111e-1 -3.11393e-5
    ]

    x2 = data2[:, 1]
    y2 = data2[:, 2]

    itp_dUdT = get_1d_interpolator(x2,y2,cap_endpoints = false)
    dUdT = itp_dUdT(theta)

    ocp    = refOCP + (T - refT) * dUdT
    
    return ocp
    
end

function computeOCP_LFP_Gerver2011(c, T, cmax)

    ocp = 3.41285712e+00 - 1.49721852e-02 * c/cmax + 3.54866018e+14 * exp(-3.95729493e+02 * c/cmax) - 1.45998465e+00 * exp(-1.10108622e+02 * (1 - c/cmax))
    return ocp
end

function computeOCP_NMC111(c, T, cmax)
    
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

    F = FARADAY_CONSTANT
    refT = 298.15

    val = k0.*exp(-Eak./F.*(1.0./T - 1/refT));
    return val
    
end





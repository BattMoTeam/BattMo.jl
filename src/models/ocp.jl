export Graphite, NMC111, ocp, n_charge_carriers, volumetric_surface_area

solid_diffusion_discretization_number(system::ActiveMaterial) = system[:N]

function Base.getindex(system::ActiveMaterial, key::Symbol)
    return system.data[key]
end

struct Graphite <: ActiveMaterial

    data::Dict{Symbol, Any}
    # At the moment the following keys are included :
    # N::Integer                   # Discretization size for solid diffusion
    # R::Real                      # Particle radius
    # A::Vector{Float64}           # vector of coefficients for harmonic average (half-transmissibility for spherical coordinate)
    # v::Vector{Float64}           # vector of volumes (volume of spherical layer)
    # div::Vector{Vector{Float64}} # Helping structure to compute divergence operator for particle diffusion
    
    function Graphite(R, N)
        data = setupSolidDiffusionDiscretization(R, N)
        new(data)
    end
    
        
end

struct NMC111 <: ActiveMaterial

    data::Dict{Symbol, Any}
    
    function  NMC111(R, N)
        data = setupSolidDiffusionDiscretization(R, N)
        new(data)
    end   

end

function setupSolidDiffusionDiscretization(R, N)

    N = Int64(N)
    R = Float64(N)
    
    A    = zeros(Float64, N)
    vols = zeros(Float64, N)

    dr   = R/N
    rc   = [dr*(i - 1/2) for i  = 1 : N]
    rf   = [dr*i for i  = 0 : (N + 1)]
    for i = 1 : N
        vols[i] = 4*pi/3*(rf[i + 1]^3 - rf[i]^3)
        A[i]    = 4*pi*rc[i]^2/dr
    end

    div = Vector{Tuple{Int64, Int64, Float64}}(undef, 2*(N - 1))

    k = 1
    for j = 1 : N - 1
        div[k] = (j, j, 1)
        k += 1
        div[k] = (j + 1, j, -1)
        k += 1
    end
        
    data = Dict(:N => N      ,
                :R => R      ,
                :A => A      ,
                :vols => vols,
                :div => div  ,
                )
    
    return data
        
end


## Define OCP and entropy change (dUdT) for graphite using polynomials

const coeff1_refOCP = Polynomial([
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

const coeff2_refOCP =Polynomial([
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

const coeff1_dUdT = Polynomial([
	0.199521039,
	- 0.928373822,
	+ 1.364550689000003,
	- 0.611544893999998
]);

const coeff2_dUdT = Polynomial([
	1,
	- 5.661479886999997,
	+ 11.47636191,
	- 9.82431213599998,
	+ 3.048755063
])

function ocp(T,c, material::NMC111)
    """Compute OCP for NMC111 as function of temperature and concentration"""
    refT   = 298.15
    cmax   = maximum_concentration(material)
    theta  = c/cmax
    refOCP = coeff1_refOCP(theta)/coeff2_refOCP(theta)
    dUdT   = -1e-3*coeff1_dUdT(theta)/coeff2_dUdT(theta)
    vocp   = refOCP + (T - refT) * dUdT
    
    return vocp
    
end

## Defines OCP and entropy change (dUdT) for graphite using polynomials

const coeff1 = Polynomial([
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

const  coeff2= Polynomial([
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

function ocp(T, c, material::Graphite)
    """Compute OCP for Graphite as function of temperature and concentration"""
    cmax   = maximum_concentration(material)
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

    dUdT = 1e-3*coeff1(theta)/ coeff2(theta);
    
    vocp = refOCP + (T - refT) * dUdT;
    return vocp
    
end

function n_charge_carriers(::Graphite)
    return 1
end

function n_charge_carriers(::NMC111)
    return 1
end

maximum_concentration(::Graphite) = 30555.0
maximum_concentration(::NMC111)   = 55554.0

volumetric_surface_area(::Graphite) = 723600.0
volumetric_surface_area(::NMC111)   = 885000.0

## Defines exchange current density for Graphite

function reaction_rate_const(T, c, ::Graphite)

    refT = 298.15
    k0   = 5.0310e-11
    Eak  = 5000
    val  = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
    
end

## Defines exchange current density for NMC

function reaction_rate_const(T, c, ::NMC111)
    refT = 298.15
    k0 = 2.3300e-11
    Eak = 5000
    val = k0.*exp(-Eak./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end

## Define solid diffusion coefficient for Graphite

function diffusion_rate(T, c, ::Graphite)
    
    refT = 298.15
    D0   = 3.9e-14
    Ead  = 5000
    val  = D0.*exp(-Ead./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end

## Define solid diffusion coefficient for NMC

function diffusion_rate(T, c, ::NMC111)
    
    refT = 298.15
    D0   = 1e-14
    Ead  = 5000
    val = D0.*exp(-Ead./FARADAY_CONST .*(1.0./T - 1/refT));
    
    return val
end


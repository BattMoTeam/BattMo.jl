## Defines OCP and entropy change (dUdT) for graphite using polynomials

con = Constants()
const FARADAY_CONSTANT = con.F

const coeff1_graphite = Polynomial([
	+0.005269056,
	+3.299265709,
	-91.79325798,
	+1004.911008,
	-5812.278127,
	+19329.75490,
	-37147.89470,
	+38379.18127,
	-16515.05308,
]);

const coeff2_graphite = Polynomial([
	1,
	-48.09287227,
	+1017.234804,
	-10481.80419,
	+59431.30000,
	-195881.6488,
	+374577.3152,
	-385821.1607,
	+165705.8597,
]);


function computeOCP_Graphite_Torchio(c, T, refT, cmax)
	"""Compute OCP for GenericGraphite as function of temperature and concentration"""
	theta  = c ./ cmax
	refT   = 298.15
	refOCP = (0.7222
	+ 0.1387 * theta
	+ 0.0290 * theta^0.5
	- 0.0172 / theta
	+ 0.0019 / theta^1.5
	+ 0.2808 * exp(0.9 - 15.0 * theta)
	- 0.7984 * exp(0.4465 * theta - 0.4108)
)

	dUdT = 1e-3 * coeff1_graphite(theta) / coeff2_graphite(theta)

	ocp = refOCP + (T - refT) * dUdT

	return ocp

end


function compute_reaction_rate_constant_graphite(c, T, refT, cmax)

	refT = 298.15
	k0   = 5.0310e-11
	Eak  = 5000
	val  = k0 .* exp(-Eak ./ FARADAY_CONSTANT .* (1.0 ./ T - 1 / refT))

	return val

end


## Define OCP for Graphite-SiOx (chen_2020) using polynomials

function computeOCP_Graphite_SiOx_chen_2020(c, T, refT, cmax)
	x = c ./ cmax

	ocp = 1.9793 * exp(-39.3631 * x) + 0.2482 - 0.0909 * tanh(29.8538 * (x - 0.1234)) - 0.04478 * tanh(14.9159 * (x - 0.2769)) - 0.0205 * tanh(30.4444 * (x - 0.6103))


	return ocp
end

## Define OCP for NMC811 (chen_2020) using polynomials

function computeOCP_NMC811_chen_2020(c, T, refT, cmax)
	x = c ./ cmax

	ocp = -0.8090 * x + 4.4875 - 0.0428 * tanh(18.5138 * (x - 0.5542)) - 17.7326 * tanh(15.7890 * (x - 0.3117)) + 17.5842 * tanh(15.9308 * (x - 0.3120))


	return ocp
end


## Define OCP and entropy change (dUdT) for NMC111 using polynomials

const coeff1_refOCP_nmc111 = Polynomial([
	-4.656,
	0,
	+88.669,
	0,
	-401.119,
	0,
	+342.909,
	0,
	-462.471,
	0,
	+433.434,
]);

const coeff2_refOCP_nmc111 = Polynomial([
	-1,
	0,
	+18.933,
	0,
	-79.532,
	0,
	+37.311,
	0,
	-73.083,
	0,
	+95.960,
])

const coeff1_dUdT_nmc111 = Polynomial([
	0.199521039,
	-0.928373822,
	+1.364550689000003,
	-0.611544893999998,
]);

const coeff2_dUdT_nmc111 = Polynomial([
	1,
	-5.661479886999997,
	+11.47636191,
	-9.82431213599998,
	+3.048755063,
])


function computeOCP_LFP_Gerver2011(c, T, refT, cmax)

	ocp = 3.41285712e+00 - 1.49721852e-02 * c / cmax + 3.54866018e+14 * exp(-3.95729493e+02 * c / cmax) - 1.45998465e+00 * exp(-1.10108622e+02 * (1 - c / cmax))
	return ocp
end

function computeOCP_NMC111(c, T, refT, cmax)

	"""Compute OCP for GenericNMC111 as function of temperature and concentration"""
	refT   = 298.15
	theta  = c / cmax
	refOCP = coeff1_refOCP_nmc111(theta) / coeff2_refOCP_nmc111(theta)
	dUdT   = -1e-3 * coeff1_dUdT_nmc111(theta) / coeff2_dUdT_nmc111(theta)
	ocp    = refOCP + (T - refT) * dUdT

	return ocp

end





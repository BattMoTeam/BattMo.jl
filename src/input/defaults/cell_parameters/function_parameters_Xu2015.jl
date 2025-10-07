using Jutul: get_1d_interpolator

function open_circuit_potential_graphite_Xu_2015(c, T, refT, cmax)

	"""Compute OCP for LFP as function of temperature and concentration"""
	refT  = 298.15
	theta = c ./ cmax

	data1 = [                                                                                                                                                  0.00 1.28683
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

	itp_refOCP = get_1d_interpolator(x1, y1, cap_endpoints = false)

	refOCP = itp_refOCP(theta)

	data2 = [                                                                                                                                                  0.01049 3.00E-04
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

	itp_dUdT = get_1d_interpolator(x2, y2, cap_endpoints = false)
	dUdT = itp_dUdT(theta)

	ocp = refOCP + (T - refT) * dUdT

	return ocp

end


function open_circuit_potential_lfp_Xu_2015(c, T, refT, cmax)

	"""Compute OCP for LFP as function of temperature and concentration"""
	refT  = 298.15
	theta = c ./ cmax

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

	itp_refOCP = get_1d_interpolator(x1, y1, cap_endpoints = false)

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

	itp_dUdT = get_1d_interpolator(x2, y2, cap_endpoints = false)
	dUdT = itp_dUdT(theta)

	ocp = refOCP + (T - refT) * dUdT

	return ocp

end


function electrolyte_conductivity_Xu_2015(c::Real, T::Real)
	""" Compute the electrolyte conductivity as a function of concentration
	"""
	conductivityFactor = 1e-4

	conductivity = c * 1e-4 * 1.2544 * (-8.2488 + 0.053248 * T - 2.987e-5 * (T^2) + 0.26235e-3 * c - 9.3063e-6 * c * T + 8.069e-9 * c * T^2 + 2.2002e-7 * c^2 - 1.765e-10 * T * c^2)
	return conductivity
end

function electrolyte_diffusivity_Xu_2015(c::Real, T::Real)
	""" Compute the diffusion coefficient as a function of concentration
	"""
	# Calculate diffusion coefficients constant for the diffusion coefficient calculation
	cnst = [                                                                -4.43  -54.0;
		-0.22   0.0]

	Tgi = [229 5.0]

	# Diffusion coefficient, [m^2 s^-1]
	#Removed 10⁻⁴ otherwise the same
	D = 10^((cnst[1, 1] + cnst[1, 2] / (T - Tgi[1] - Tgi[2] * c * 1e-3) + cnst[2, 1] * c * 1e-3))
	return D
end

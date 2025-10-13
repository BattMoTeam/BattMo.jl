################################
# DUDT SiC 

function compute_dUdT_SiC_paper(c, cmax)
	# % @article{Sturm_2019,
	# %   title =        {Modeling and simulation of inhomogeneities in a 18650 nickel-rich, silicon-graphite lithium-ion cell
	# %                   during fast charging},
	# %   volume =       412,
	# %   ISSN =         {0378-7753},
	# %   url =          {http://dx.doi.org/10.1016/j.jpowsour.2018.11.043},
	# %   DOI =          {10.1016/j.jpowsour.2018.11.043},
	# %   journal =      {Journal of Power Sources},
	# %   publisher =    {Elsevier BV},
	# %   author =       {Sturm, J. and Rheinfeld, A. and Zilberman, I. and Spingler, F.B. and Kosch, S. and Frie, F. and
	# %                   Jossen, A.},
	# %   year =         2019,
	# %   month =        feb,
	# %   pages =        {204–223}
	# % }
	# % Unit is [mV/K]

	data = [0 0.00357143
		0.211765 0.00357143
		0.265882 -0.0125
		0.324706 -0.0267857
		0.376471 -0.196429
		0.430588 -0.216071
		0.487059 -0.196429
		0.538824 -0.0285714
		0.595294 -0.0517857
		0.644706 -0.0607143
		0.698824 -0.0696429
		0.752941 -0.0767857
		0.802353 -0.0928571
		0.858824 -0.108929
	]

	data_y = data(:, 2) * milli * volt

	stoc = c ./ cmax

	dUdT = interpTable(data(:, 1), data_y, stoc)

	return dUdT

end



################################
# OCP graphite

function open_circuit_potential_graphite_Ank_2023(c, T, refT, cmax)

	# Reference :
	# Authors : Ank, Manuel and Sommer, Alessandro and Abo Gamra, Kareem and Schöberl, Jan and Leeb, Matthias and Schachtl, Johannes and Streidel, Noah and Stock, Sandro and Schreiber, Markus and Bilfinger, Philip and Allgäuer, Christian and Rosner, Philipp and Hagemeister, Jan and Rößle, Matti and Daub, Rüdiger and Lienkamp, Markus
	# Title : Lithium-Ion Cells in Automotive Applications: Tesla 4680 Cylindrical Cell Teardown and Characterization


	refT  = 298.15
	theta = c ./ cmax

	data1 = [
		0.00112867 1.0445
		0.00778984 0.7565
		0.0111049 0.5524
		0.0188711 0.412133
		0.0320813 0.315165
		0.0337326 0.303635
		0.0353839 0.292696
		0.0370352 0.282402
		0.0386865 0.272803
		0.0403378 0.263897
		0.041989 0.255509
		0.0436403 0.247479
		0.0452916 0.239904
		0.0469429 0.233055
		0.0485942 0.226877
		0.0502455 0.221269
		0.0518966 0.216244
		0.0535479 0.211818
		0.0551992 0.207841
		0.0568505 0.204308
		0.0585017 0.201218
		0.060153 0.198572
		0.0618043 0.196365
		0.0634556 0.194596
		0.0651069 0.193267
		0.0667582 0.192342
		0.0684094 0.191815
		0.0700607 0.191588
		0.0865736 0.190156
		0.0915274 0.189507
		0.09483 0.188836
		0.0981326 0.187927
		0.103086 0.18612
		0.10804 0.183796
		0.112994 0.18108
		0.122902 0.174683
		0.132809 0.167647
		0.141066 0.161102
		0.155927 0.148768
		0.160881 0.14489
		0.165835 0.141218
		0.187302 0.126627
		0.190605 0.124624
		0.193907 0.122836
		0.19721 0.121263
		0.200512 0.119904
		0.203815 0.11876
		0.208769 0.117446
		0.236841 0.112202
		0.243446 0.111242
		0.251702 0.110371
		0.322706 0.106419
		0.395363 0.104358
		0.408573 0.103829
		0.431691 0.102444
		0.436645 0.101966
		0.44325 0.101088
		0.448204 0.100248
		0.451506 0.0994756
		0.45646 0.0975449
		0.459763 0.0959175
		0.464717 0.0930551
		0.46967 0.0896039
		0.476276 0.0844563
		0.481229 0.0814558
		0.484532 0.0798546
		0.489486 0.0779722
		0.492788 0.0771046
		0.496091 0.0765806
		0.504347 0.0759713
		0.514255 0.0755982
		0.586912 0.0754924
		0.600122 0.0751734
		0.644707 0.0735591
		0.656266 0.0733773
		0.677732 0.0733614
		0.945599 0.0733
		0.968664 0.0707
		0.98927 0.0628
		0.995262 0.0497
		0.997814 0.0393
		0.999526 0.0236
	]

	x1 = data1[:, 1]
	y1 = data1[:, 2]

	itp_ref_ocp = get_1d_interpolator(x1, y1, cap_endpoints = false)

	ref_ocp = itp_ref_ocp(theta)

	

	x2 = data2[:, 1]
	y2 = data2[:, 2]

	itp_dUdT = get_1d_interpolator(x2, y2, cap_endpoints = false)
	dUdT = itp_dUdT(theta)

	ocp = refOCP + (T - refT) * dUdT

	return ocp

end
Jutul.cross_term_entities(ct::TPFAInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::TPFAInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.source_cells

function Jutul.update_cross_term_in_entity!(out,
	ind,
	state_t,
	state0_t,
	state_s,
	state0_s,
	model_t,
	model_s,
	ct::TPFAInterfaceFluxCT,
	eq,
	dt,
	ldisc = local_discretization(ct, ind))

	trans = ct.trans[ind]
	ind_t = ct.target_cells[ind]
	ind_s = ct.source_cells[ind]
	phi_t = state_t.Voltage[ind_t]
	phi_s = state_s.Voltage[ind_s]

	out[] = trans * (phi_t - phi_s)

end

function Jutul.update_cross_term_in_entity!(out,
	ind,
	state_t,
	state0_t,
	state_s,
	state0_s,
	model_t,
	model_s,
	ct::AccumulatorInterfaceFluxCT,
	eq,
	dt,
	ldisc = local_discretization(ct, ind))
	trans = ct.trans
	ind_t = ct.target_cell
	phi_t = state_t.Voltage[ind_t]
	phi_s = state_s.Voltage
	v = 0
	for (i, ind_s) in enumerate(ct.source_cells)
		v += trans[i] * (phi_t - phi_s[ind_s])
	end

	out[] = v
end

Jutul.cross_term_entities(ct::AccumulatorInterfaceFluxCT, eq::JutulEquation, model) = [ct.target_cell]

function regularized_sqrt(x, th)
	x, th = promote(x, th)
	T = typeof(x)
	y = zero(T)
	if x <= th
		y = x / th * sqrt(th)
	else
		y = x^0.5
	end
	return y
end

function safe_div(x, y; th = 1e-8)

	return x / y
end

function save_sqrt(x)

	if x < 0
		return zero(x)
	else
		return sqrt(x)
	end
end

function butler_volmer_equation(j0, alpha, n, eta, T)

	F = FARADAY_CONSTANT
	R = GAS_CONSTANT

	val = j0 * (exp(alpha * n * F * eta / (R * T)) - exp(-(1 - alpha) * n * F * eta / (R * T)))

	return val

end

function reaction_rate_coefficient(R0,
	c_e,
	c_a,
	activematerial)

	F = FARADAY_CONSTANT

	n    = activematerial.params[:n_charge_carriers]
	cmax = activematerial.params[:maximum_concentration]

	th = 1e-3 * cmax
	j0 = R0 * regularized_sqrt(c_e * (cmax - c_a) * c_a, th) * n * F

	return j0

end

function reaction_rate(eta,
	c_a,
	R0,
	T,
	c_e,
	activematerial,
	electrolyte,
)

	F = FARADAY_CONSTANT

	n = activematerial.params[:n_charge_carriers]

	j0 = reaction_rate_coefficient(R0, c_e, c_a, activematerial)
	R  = butler_volmer_equation(j0, 0.5, n, eta, T)

	return R / (n * F)

end

function butler_volmer_equation_chayambuka(j0, alpha, n, eta, T, cmax, c_a_surf, c_e, c_a, c_av, c_av_e)

	F = FARADAY_CONSTANT
	R = GAS_CONSTANT

	th = 1e-2

	val = j0 * (safe_div(c_a_surf, c_av; th) * exp(alpha * n * F * eta / (R * T)) - (safe_div((cmax - c_a_surf), (cmax - c_av); th) * safe_div(c_e, c_av_e; th)) * exp(-(1 - alpha) * n * F * eta / (R * T)))

	return val

end

function reaction_rate_coefficient_chayambuka(R0,
	c_e,
	c_a,
	activematerial,
	c_av,
	c_av_e)

	F = FARADAY_CONSTANT

	n    = activematerial.params[:n_charge_carriers]
	cmax = activematerial.params[:maximum_concentration]

	th = 1e-2 * cmax

	j0 = R0 * save_sqrt(c_av_e * (cmax - c_a) * c_a) * n * F

	return j0

end

function reaction_rate_chayambuka(eta,
	c_a_surf,
	R0,
	T,
	c_e,
	activematerial,
	electrolyte,
	c_a,
	c_av,
	c_av_e)

	F = FARADAY_CONSTANT

	n = activematerial.params[:n_charge_carriers]
	cmax = activematerial.params[:maximum_concentration]
	alpha = 0.5
	j0 = reaction_rate_coefficient_chayambuka(R0, c_e, c_a, activematerial, c_av, c_av_e)
	R = butler_volmer_equation_chayambuka(j0, alpha, n, eta, T, cmax, c_a_surf, c_e, c_a, c_av, c_av_e)

	return R / (n * F)

end



############################
# cross-term for 2pd model #
############################

Jutul.cross_term_entities(ct::ButlerVolmerActmatToElyteCT, eq::JutulEquation, model)        = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerActmatToElyteCT, eq::JutulEquation, model) = ct.source_cells

function Jutul.update_cross_term_in_entity!(out,
	ind,
	state_t,
	state0_t,
	state_s,
	state0_s,
	model_t,
	model_s,
	ct::ButlerVolmerActmatToElyteCT,
	eq,
	dt,
	ldisc = local_discretization(ct, ind),
)


	activematerial = model_s.system
	electrolyte    = model_t.system

	n   = activematerial.params[:n_charge_carriers]
	vsa = activematerial.params[:volumetric_surface_area]

	ind_t = ct.target_cells[ind]
	ind_s = ct.source_cells[ind]

	vols = state_t.Volume[ind_t]

	phi_e = state_t.Voltage[ind_t]
	phi_a = state_s.Voltage[ind_s]
	ocp = state_s.OpenCircuitPotential[ind_s]
	R0 = state_s.ReactionRateConstant[ind_s]
	c_e = state_t.Concentration[ind_t]
	c_a_surf = state_s.SurfaceConcentration[ind_s]
	c_a = state_s.ParticleConcentration[ind_s]
	T = state_s.Temperature[ind_s]
	c_av = mean(c_a)
	c_av_e = mean(state_t.Concentration)

	# overpotential
	eta = phi_a - phi_e - ocp

	if activematerial.params[:setting_butler_volmer] == "Chayambuka"
		R = reaction_rate_chayambuka(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte,
			c_a,
			c_av,
			c_av_e)
	else
		R = reaction_rate(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte)
	end

	cs = conserved_symbol(eq)

	if cs == :Mass
		v = 1.0 * vols * vsa * R
	else
		@assert cs == :Charge
		v = 1.0 * vols * vsa * R * n * FARADAY_CONSTANT
	end
	out[] = -v

end

Jutul.cross_term_entities(ct::ButlerVolmerElyteToActmatCT, eq::JutulEquation, model)        = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerElyteToActmatCT, eq::JutulEquation, model) = ct.source_cells

function Jutul.update_cross_term_in_entity!(out,
	ind,
	state_t,
	state0_t,
	state_s,
	state0_s,
	model_t,
	model_s,
	ct::ButlerVolmerElyteToActmatCT,
	eq,
	dt,
	ldisc = local_discretization(ct, ind),
)

	electrolyte    = model_s.system
	activematerial = model_t.system

	n   = activematerial.params[:n_charge_carriers]
	vsa = activematerial.params[:volumetric_surface_area]

	ind_t = ct.target_cells[ind]
	ind_s = ct.source_cells[ind]

	vols = state_t.Volume[ind_t]

	phi_e = state_s.Voltage[ind_s]
	phi_a = state_t.Voltage[ind_t]
	ocp = state_t.OpenCircuitPotential[ind_t]
	R0 = state_t.ReactionRateConstant[ind_t]
	c_e = state_s.Concentration[ind_s]
	c_a_surf = state_t.SurfaceConcentration[ind_t]
	c_a = state_t.ParticleConcentration[ind_t]
	T = state_t.Temperature[ind_t]
	c_av = mean(c_a)
	c_av_e = mean(state_s.Concentration)

	# overpotential
	eta = phi_a - phi_e - ocp

	if activematerial.params[:setting_butler_volmer] == "Chayambuka"
		R = reaction_rate_chayambuka(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte,
			c_a,
			c_av,
			c_av_e)
	else
		R = reaction_rate(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte)
	end

	if eq isa SolidDiffusionBc

		rp  = activematerial.discretization[:rp] # particle radius
		vf  = state_t.VolumeFraction[ind_t]
		avf = activematerial.params.volume_fractions[1]

		v = vsa * R * (4 * pi * rp^3) / (3 * vf * avf)

		out[] = -v

	else

		cs = conserved_symbol(eq)
		@assert cs == :Charge
		v = 1.0 * vols * vsa * R * n * FARADAY_CONSTANT

		out[] = v

	end

end

###############################################
# cross-terms for no particle diffusion model #
###############################################

function source_electric_material(vols,
	T,
	phi_a,
	c_a_surf,
	R0,
	ocp,
	phi_e,
	c_e,
	activematerial,
	electrolyte,
	c_a,
	c_av,
	c_av_e,
)

	n   = activematerial.params[:n_charge_carriers]
	vsa = activematerial.params[:volumetric_surface_area]

	if activematerial.params[:setting_butler_volmer] == "Chayambuka"
		R = reaction_rate_chayambuka(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte,
			c_a,
			c_av,
			c_av_e)
	else
		R = reaction_rate(eta,
			c_a_surf,
			R0,
			T,
			c_e,
			activematerial,
			electrolyte)
	end

	eS = 1.0 * vols * vsa * R * n * FARADAY_CONSTANT
	eM = 1.0 * vols * vsa * R

	return (eS, eM)

end


Jutul.cross_term_entities(ct::ButlerVolmerInterfaceFluxCT, eq::JutulEquation, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerInterfaceFluxCT, eq::JutulEquation, model) = ct.source_cells

Jutul.symmetry(::ButlerVolmerInterfaceFluxCT) = CTSkewSymmetry()

function Jutul.update_cross_term_in_entity!(out,
	ind,
	state_t,
	state0_t,
	state_s,
	state0_s,
	model_t,
	model_s,
	ct::ButlerVolmerInterfaceFluxCT,
	eq,
	dt,
	ldisc = local_discretization(ct, ind))

	activematerial = model_s.system
	electrolyte = model_t.system

	ind_t = ct.target_cells[ind]
	ind_s = ct.source_cells[ind]
	#NB probably wrong use
	vols = model_s.domain.representation[:volumes][ind_s]

	phi_e = state_t.Voltage[ind_t]
	phi_a = state_s.Voltage[ind_s]
	ocp = state_s.OpenCircuitPotential[ind_s]
	R = state_s.ReactionRateConstant[ind_s]
	c_e = state_t.Concentration[ind_t]
	c_a_surf = state_s.SurfaceConcentration[ind_s]
	c_a = state_s.ParticleConcentration[ind_s]
	T = state_s.Temperature[ind_s]
	c_av = mean(c_a)
	c_av_e = mean(state_t.Concentration)

	eS, eM = source_electric_material(vols,
		T,
		phi_a,
		c_a_surf,
		R,
		ocp,
		phi_e,
		c_e,
		activematerial,
		electrolyte,
		c_a,
		c_av,
		c_av_e,
	)

	cs = conserved_symbol(eq)
	if cs == :Mass
		v = eM
	else
		@assert cs == :Charge
		v = eS
	end

	out[] = -v

end
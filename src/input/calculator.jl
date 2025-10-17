
using Optim

function calculate_mass_fractions_and_effective_density_from_volume_fractions!(input::CellParameters, pe_vf, ne_vf, ne_am_vf, pe_am_vf; ne_b_vf = nothing, pe_b_vf = nothing, ne_add_vf = nothing, pe_add_vf = nothing)

	ne_am_density = input["NegativeElectrode"]["ActiveMaterial"]["density"]
	pe_am_density = input["PositiveElectrode"]["ActiveMaterial"]["density"]
	ne_b_density = input["NegativeElectrode"]["Binder"]["density"]
	pe_b_density = input["PositiveElectrode"]["Binder"]["density"]
	ne_add_density = input["NegativeElectrode"]["ConductiveAdditive"]["density"]
	pe_add_density = input["PositiveElectrode"]["ConductiveAdditive"]["density"]


	# --- Negative electrode mass fractions ---
	ne_mass_AM  = ne_am_vf * ne_am_density
	ne_mass_B   = ne_b_vf * ne_b_density
	ne_mass_Add = ne_add_vf * ne_add_density
	ne_mass_sum = ne_mass_AM + ne_mass_B + ne_mass_Add

	ne_am_mf  = ne_mass_AM / ne_mass_sum
	ne_b_mf   = ne_mass_B / ne_mass_sum
	ne_add_mf = ne_mass_Add / ne_mass_sum

	# --- Positive electrode mass fractions ---
	pe_mass_AM  = pe_am_vf * pe_am_density
	pe_mass_B   = pe_b_vf * pe_b_density
	pe_mass_Add = pe_add_vf * pe_add_density
	pe_mass_sum = pe_mass_AM + pe_mass_B + pe_mass_Add

	pe_am_mf  = pe_mass_AM / pe_mass_sum
	pe_b_mf   = pe_mass_B / pe_mass_sum
	pe_add_mf = pe_mass_Add / pe_mass_sum

	# --- Effective densities ---
	ne_effective_density = 1.0 / (ne_am_vf / ne_am_density + ne_b_vf / ne_b_density + ne_add_vf / ne_add_density)
	pe_effective_density = 1.0 / (pe_am_vf / pe_am_density + pe_b_vf / pe_b_density + pe_add_vf / pe_add_density)

	# Store results back into the input dictionary
	input["NegativeElectrode"]["ActiveMaterial"]["MassFraction"] = ne_am_mf
	input["PositiveElectrode"]["ActiveMaterial"]["MassFraction"] = pe_am_mf
	input["NegativeElectrode"]["Binder"]["MassFraction"] = ne_b_mf
	input["PositiveElectrode"]["Binder"]["MassFraction"] = pe_b_mf
	input["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"] = ne_add_mf
	input["PositiveElectrode"]["ConductiveAdditive"]["MassFraction"] = pe_add_mf

	input["NegativeElectrode"]["effective_density"] = ne_effective_density
	input["PositiveElectrode"]["effective_density"] = pe_effective_density

	return input

end

function infer_binder_additive_by_np_ratio!(
	input::CellParameters,
	pe_vf, ne_vf,
	pe_am_vf, ne_am_vf;
	target_np_ratio,
	verbose = true,
)
	# Objective: squared error between simulated and target N/P ratio
	function objective(x)
		x_ne, x_pe = clamp.(x, 0.0, 1.0)

		ne_rem = ne_vf - ne_am_vf
		pe_rem = pe_vf - pe_am_vf

		ne_b_vf   = x_ne * ne_rem
		ne_add_vf = (1 - x_ne) * ne_rem
		pe_b_vf   = x_pe * pe_rem
		pe_add_vf = (1 - x_pe) * pe_rem

		# Update mass fractions and densities
		calculate_mass_fractions_and_effective_density_from_volume_fractions!(
			input, pe_vf, ne_vf, ne_am_vf, pe_am_vf;
			ne_b_vf = ne_b_vf, pe_b_vf = pe_b_vf,
			ne_add_vf = ne_add_vf, pe_add_vf = pe_add_vf,
		)

		np_ratio_calc = compute_np_ratio(input)
		loss = (np_ratio_calc - target_np_ratio)^2

		if verbose
			println("x_ne=$(round(x_ne, digits=3)), x_pe=$(round(x_pe, digits=3)), N/P=$(round(np_ratio_calc, digits=3)), loss=$(round(loss, digits=5))")
		end

		return loss
	end

	# Two-variable bounded optimization
	res = optimize(objective, [0.0, 0.0], [1.0, 1.0], [0.5, 0.5], Fminbox(BFGS()))
	x_opt = Optim.minimizer(res)
	x_ne_opt, x_pe_opt = x_opt

	# Compute final fractions
	ne_rem    = ne_vf - ne_am_vf
	pe_rem    = pe_vf - pe_am_vf
	ne_b_vf   = x_ne_opt * ne_rem
	ne_add_vf = (1 - x_ne_opt) * ne_rem
	pe_b_vf   = x_pe_opt * pe_rem
	pe_add_vf = (1 - x_pe_opt) * pe_rem

	# Recalculate with optimal fractions
	calculate_mass_fractions_and_effective_density_from_volume_fractions!(
		input, pe_vf, ne_vf, ne_am_vf, pe_am_vf;
		ne_b_vf = ne_b_vf, pe_b_vf = pe_b_vf,
		ne_add_vf = ne_add_vf, pe_add_vf = pe_add_vf,
	)

	np_ratio_final = n_p_ratio(input)

	return input, Dict(
		"x_ne" => x_ne_opt,
		"x_pe" => x_pe_opt,
		"ne_b_vf" => ne_b_vf,
		"ne_add_vf" => ne_add_vf,
		"pe_b_vf" => pe_b_vf,
		"pe_add_vf" => pe_add_vf,
		"N/P_final" => np_ratio_final,
		"objective_value" => Optim.minimum(res),
	)
end

export calculate_mass_fractions_and_effective_density_from_volume_fractions!, infer_binder_additive_by_np_ratio!, calculate_effective_density

function calculate_effective_density(input::CellParameters, ne_vf, pe_vf)

    ne_am_density = input["NegativeElectrode"]["ActiveMaterial"]["Density"]
    pe_am_density = input["PositiveElectrode"]["ActiveMaterial"]["Density"]
    ne_b_density = input["NegativeElectrode"]["Binder"]["Density"]
    pe_b_density = input["PositiveElectrode"]["Binder"]["Density"]
    ne_add_density = input["NegativeElectrode"]["ConductiveAdditive"]["Density"]
    pe_add_density = input["PositiveElectrode"]["ConductiveAdditive"]["Density"]

    ne_am_mf = input["NegativeElectrode"]["ActiveMaterial"]["MassFraction"]
    pe_am_mf = input["PositiveElectrode"]["ActiveMaterial"]["MassFraction"]
    ne_b_mf = input["NegativeElectrode"]["Binder"]["MassFraction"]
    pe_b_mf = input["PositiveElectrode"]["Binder"]["MassFraction"]
    ne_add_mf = input["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"]
    pe_add_mf = input["PositiveElectrode"]["ConductiveAdditive"]["MassFraction"]

    ne_effective_density = ne_vf * (ne_am_mf * ne_am_density + ne_b_mf * ne_b_density + ne_add_mf * ne_add_density)
    pe_effective_density = pe_vf * (pe_am_mf * pe_am_density + pe_b_mf * ne_b_density + pe_add_mf * pe_add_density)

    return ne_effective_density, pe_effective_density

end
function calculate_mass_fractions_and_effective_density_from_volume_fractions!(input::CellParameters, pe_vf, ne_vf, ne_am_vf, pe_am_vf; ne_b_vf = nothing, pe_b_vf = nothing, ne_add_vf = nothing, pe_add_vf = nothing)

    ne_am_density = input["NegativeElectrode"]["ActiveMaterial"]["Density"]
    pe_am_density = input["PositiveElectrode"]["ActiveMaterial"]["Density"]
    ne_b_density = input["NegativeElectrode"]["Binder"]["Density"]
    pe_b_density = input["PositiveElectrode"]["Binder"]["Density"]
    ne_add_density = input["NegativeElectrode"]["ConductiveAdditive"]["Density"]
    pe_add_density = input["PositiveElectrode"]["ConductiveAdditive"]["Density"]


    # --- Negative electrode mass fractions ---
    ne_mass_AM = ne_am_vf * ne_am_density
    ne_mass_B = ne_b_vf * ne_b_density
    ne_mass_Add = ne_add_vf * ne_add_density
    ne_mass_sum = ne_mass_AM + ne_mass_B + ne_mass_Add

    ne_am_mf = ne_mass_AM / ne_mass_sum
    ne_b_mf = ne_mass_B / ne_mass_sum
    ne_add_mf = ne_mass_Add / ne_mass_sum

    # --- Positive electrode mass fractions ---
    pe_mass_AM = pe_am_vf * pe_am_density
    pe_mass_B = pe_b_vf * pe_b_density
    pe_mass_Add = pe_add_vf * pe_add_density
    pe_mass_sum = pe_mass_AM + pe_mass_B + pe_mass_Add

    pe_am_mf = pe_mass_AM / pe_mass_sum
    pe_b_mf = pe_mass_B / pe_mass_sum
    pe_add_mf = pe_mass_Add / pe_mass_sum

    # --- Effective densities ---
    ne_effective_density = ne_vf * (ne_am_mf * ne_am_density + ne_b_mf * ne_b_density + ne_add_mf * ne_add_density)
    pe_effective_density = pe_vf * (pe_am_mf * pe_am_density + pe_b_mf * ne_b_density + pe_add_mf * pe_add_density)

    # Store results back into the input dictionary
    input["NegativeElectrode"]["ActiveMaterial"]["MassFraction"] = ne_am_mf
    input["PositiveElectrode"]["ActiveMaterial"]["MassFraction"] = pe_am_mf
    input["NegativeElectrode"]["Binder"]["MassFraction"] = ne_b_mf
    input["PositiveElectrode"]["Binder"]["MassFraction"] = pe_b_mf
    input["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"] = ne_add_mf
    input["PositiveElectrode"]["ConductiveAdditive"]["MassFraction"] = pe_add_mf

    input["NegativeElectrode"]["Coating"]["EffectiveDensity"] = ne_effective_density
    input["PositiveElectrode"]["Coating"]["EffectiveDensity"] = pe_effective_density

    return input

end

function infer_binder_additive_by_np_ratio!(
        input::CellParameters,
        pe_vf, ne_vf,
        pe_am_vf, ne_am_vf;
        target_np_ratio,
        verbose = true,
    )
    function update_fractions!(candidate_input, x)
        x_ne, x_pe = x
        ne_rem = ne_vf - ne_am_vf
        pe_rem = pe_vf - pe_am_vf

        calculate_mass_fractions_and_effective_density_from_volume_fractions!(
            candidate_input, pe_vf, ne_vf, ne_am_vf, pe_am_vf;
            ne_b_vf = x_ne * ne_rem,
            pe_b_vf = x_pe * pe_rem,
            ne_add_vf = (1 - x_ne) * ne_rem,
            pe_add_vf = (1 - x_pe) * pe_rem,
        )
        return candidate_input
    end

    function objective(x)
        candidate_input = update_fractions!(deepcopy(input), x)
        return (compute_np_ratio(candidate_input) - target_np_ratio)^2
    end

    function objective_and_gradient(x)
        return objective(x), ForwardDiff.gradient(objective, x)
    end

    objective_value, x_opt, _ = unit_box_bfgs(
        [0.5, 0.5],
        objective_and_gradient;
        step_init = 1.0,
        grad_tol = 1.0e-8,
        obj_change_tol = 1.0e-12,
        max_it = 100,
        print = verbose ? 1 : 0,
    )
    x_ne_opt, x_pe_opt = x_opt

    # Compute final fractions
    ne_rem = ne_vf - ne_am_vf
    pe_rem = pe_vf - pe_am_vf
    ne_b_vf = x_ne_opt * ne_rem
    ne_add_vf = (1 - x_ne_opt) * ne_rem
    pe_b_vf = x_pe_opt * pe_rem
    pe_add_vf = (1 - x_pe_opt) * pe_rem

    update_fractions!(input, x_opt)

    np_ratio_final = compute_np_ratio(input)

    return input, Dict(
            "x_ne" => x_ne_opt,
            "x_pe" => x_pe_opt,
            "ne_b_vf" => ne_b_vf,
            "ne_add_vf" => ne_add_vf,
            "pe_b_vf" => pe_b_vf,
            "pe_add_vf" => pe_add_vf,
            "N/P_final" => np_ratio_final,
            "objective_value" => objective_value,
        )
end

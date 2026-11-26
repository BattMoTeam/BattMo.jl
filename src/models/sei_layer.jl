##################
# SEI model type #
##################

# Create a type for the model with SEI layer. It will be used to specialize the function
const SEImodel = SimulationModel{O, S, F, C} where {
    O <: JutulDomain,
    S <: BattMo.ActiveMaterialP2D{:sei, D, T} where {D, T},
    F <: JutulFormulation,
    C <: JutulContext,
}

##################################################
# Variable for SEI model added to ActiveMaterial #
##################################################

struct NormalizedSEIThickness <: ScalarVariable end
struct NormalizedSEIVoltageDrop <: ScalarVariable end
struct SEIThickness <: ScalarVariable end
struct SEIVoltageDrop <: ScalarVariable end

# The growth law divides by thickness. This floor is far below the normalized BOL value 1.
Jutul.minimum_value(::NormalizedSEIThickness) = 1.0e-12


###################################################
# Equations for SEI model added to ActiveMaterial #
###################################################

# SEI mass conservation equation

struct SEIMassConservation <: JutulEquation end

Jutul.local_discretization(::SEIMassConservation, i) = nothing

function Jutul.number_of_equations_per_entity(model::SEImodel, ::SEIMassConservation)
    return 1
end

# SEI voltage drop equation

struct SEIVoltageDropEquation <: JutulEquation end
Jutul.local_discretization(::SEIVoltageDropEquation, i) = nothing

function Jutul.number_of_equations_per_entity(model::SEImodel, ::SEIVoltageDropEquation)
    return 1
end


###################################
# Declare variables for sei model #
###################################

function Jutul.select_primary_variables!(
        S,
        system::ActiveMaterialP2D,
        model::SEImodel,
    )

    S[:ElectricPotential] = ElectricPotential()
    S[:ParticleConcentration] = ParticleConcentration()
    S[:SurfaceConcentration] = SurfaceConcentration()
    S[:NormalizedSEIThickness] = NormalizedSEIThickness()
    return S[:NormalizedSEIVoltageDrop] = NormalizedSEIVoltageDrop()

end

function Jutul.select_secondary_variables!(
        S,
        system::ActiveMaterialP2D,
        model::SEImodel,
    )

    S[:Charge] = Charge()
    S[:OpenCircuitPotential] = OpenCircuitPotential()
    S[:ReactionRateConstant] = ReactionRateConstant()
    S[:DiffusionCoefficient] = DiffusionCoefficient()
    S[:EntropyChange] = EntropyChange()
    S[:SolidDiffFlux] = SolidDiffFlux()
    S[:SEIThickness] = SEIThickness()
    return S[:SEIVoltageDrop] = SEIVoltageDrop()

end


function Jutul.select_minimum_output_variables!(
        outputs,
        system::ActiveMaterialP2D,
        model::SEImodel,
    )
    push!(outputs, :Charge)
    push!(outputs, :OpenCircuitPotential)
    push!(outputs, :Temperature)
    push!(outputs, :ElectricPotential)
    push!(outputs, :ReactionRateConstant)
    push!(outputs, :DiffusionCoefficient)
    push!(outputs, :SEIThickness)
    return push!(outputs, :SEIVoltageDrop)

end


###################################
# Declare equations for sei model #
###################################

function Jutul.select_equations!(
        eqs,
        system::ActiveMaterialP2D,
        model::SEImodel,
    )
    disc = model.domain.discretizations.flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation] = SolidMassCons()
    eqs[:solid_diffusion_bc] = SolidDiffusionBc()
    eqs[:sei_mass_cons] = SEIMassConservation()
    return eqs[:sei_voltage_drop] = SEIVoltageDropEquation()

end

function Jutul.update_equation_in_entity!(
        eq_buf,
        self_cell,
        state,
        state0,
        eq::SEIMassConservation,
        model,
        dt,
        ldisc = nothing,
    )
    # do nothing
end

function Jutul.update_equation_in_entity!(
        eq_buf,
        self_cell,
        state,
        state0,
        eq::SEIVoltageDropEquation,
        model,
        dt,
        ldisc = nothing,
    )
    # do nothing
end

function apply_bc_to_equation!(storage, parameters, model::SEImodel, eq::SEIMassConservation, eq_s)
    # do nothing
end

function apply_bc_to_equation!(storage, parameters, model::SEImodel, eq::SEIVoltageDropEquation, eq_s)
    # do nothing
end

##############################
# update secondary variables #
##############################

@jutul_secondary(
    function update_sei_thickness!(
            SEIThickness,
            tv::SEIThickness,
            model::SEImodel,
            NormalizedSEIThickness,
            ix,
        )
        scaling = model.system.params[:InitialThickness]

        for cell in ix
            @inbounds SEIThickness[cell] = scaling * NormalizedSEIThickness[cell]
        end

    end
)

@jutul_secondary(
    function update_sei_voltage_drop!(
            SEIVoltageDrop,
            tv::SEIVoltageDrop,
            model::SEImodel,
            NormalizedSEIVoltageDrop,
            ix,
        )

        scaling = model.system.params[:InitialPotentialDrop]
        for cell in ix
            @inbounds SEIVoltageDrop[cell] = scaling * NormalizedSEIVoltageDrop[cell]
        end
    end
)


"""
    sei_molar_flux(params, thickness, temperature, solid_potential, electrolyte_potential, voltage_drop)

Irreversible Bolay lithium consumption flux in mol/(m^2 s), positive into the SEI.
The stoichiometric coefficient belongs in the thickness balance, not in this flux or its
current `-F*N`. The migration approximation is clipped at zero to prevent SEI dissolution.
"""
function sei_molar_flux(
        params, thickness, temperature, solid_potential, electrolyte_potential, voltage_drop,
    )
    thermal_factor = FARADAY_CONSTANT / (GAS_CONSTANT * temperature)
    overpotential = solid_potential - electrolyte_potential - voltage_drop
    prefactor = params[:ElectronicDiffusionCoefficient] * params[:InterstitialConcentration]
    flux = prefactor / thickness * exp(-thermal_factor * overpotential) *
        (1 - thermal_factor * voltage_drop / 2)
    return max(flux, zero(flux))
end

"""Evaluate intercalation with the SEI voltage drop, consistently for both coupling directions."""
function sei_intercalation_rate(
        electrode_state, electrolyte_state, active_material, electrolyte,
        electrode_cell, electrolyte_cell,
    )
    overpotential = electrode_state.ElectricPotential[electrode_cell] -
        electrolyte_state.ElectricPotential[electrolyte_cell] -
        electrode_state.OpenCircuitPotential[electrode_cell] -
        electrode_state.SEIVoltageDrop[electrode_cell]
    surface_concentration = electrode_state.SurfaceConcentration[electrode_cell]
    rate_constant = electrode_state.ReactionRateConstant[electrode_cell]
    temperature = electrode_state.Temperature[electrode_cell]
    electrolyte_concentration = electrolyte_state.ElectrolyteConcentration[electrolyte_cell]
    if active_material.params[:setting_butler_volmer] == "Chayambuka"
        concentration = electrode_state.ParticleConcentration[electrode_cell]
        return reaction_rate_chayambuka(
            overpotential, surface_concentration, rate_constant, temperature,
            electrolyte_concentration, active_material, electrolyte, concentration,
            mean(concentration), mean(electrolyte_state.ElectrolyteConcentration),
        )
    else
        return reaction_rate(
            overpotential, surface_concentration, rate_constant, temperature,
            electrolyte_concentration, active_material, electrolyte,
        )
    end
end

function Jutul.update_cross_term_in_entity!(
        out, ind, state_t, state0_t, state_s, state0_s, model_t, model_s::SEImodel,
        ct::ButlerVolmerActmatToElyteCT, eq, dt,
        ldisc = local_discretization(ct, ind),
    )
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    params = model_s.system.params
    rate = sei_intercalation_rate(
        state_s, state_t, model_s.system, model_t.system, ind_s, ind_t,
    )
    consumption = sei_molar_flux(
        params, state_s.SEIThickness[ind_s], state_s.Temperature[ind_s],
        state_s.ElectricPotential[ind_s], state_t.ElectricPotential[ind_t],
        state_s.SEIVoltageDrop[ind_s],
    )
    # Use the electrode interface area in both directions of the coupling.
    area = state_s.Volume[ind_s] * params[:volumetric_surface_area]
    conserved = conserved_symbol(eq)
    if conserved == :Mass
        return out[] = -area * (rate - consumption)
    else
        @assert conserved == :Charge
        return out[] = -area * FARADAY_CONSTANT * (params[:n_charge_carriers] * rate - consumption)
    end
end

function Jutul.update_cross_term_in_entity!(
        out, ind, state_t, state0_t, state_s, state0_s, model_t::SEImodel, model_s,
        ct::ButlerVolmerElyteToActmatCT, eq, dt,
        ldisc = local_discretization(ct, ind),
    )
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    active_material = model_t.system
    params = active_material.params
    rate = sei_intercalation_rate(
        state_t, state_s, active_material, model_s.system, ind_t, ind_s,
    )
    if eq isa SolidDiffusionBc
        # Only intercalation crosses the particle boundary; SEI consumes electrolyte lithium.
        radius = active_material.discretization[:rp]
        active_fraction = state_t.VolumeFraction[ind_t] * params[:volume_fractions][1]
        particle_volume = 4 * pi * radius^3 / 3
        return out[] = -params[:volumetric_surface_area] * rate * particle_volume / active_fraction
    else
        @assert conserved_symbol(eq) == :Charge
        consumption = sei_molar_flux(
            params, state_t.SEIThickness[ind_t], state_t.Temperature[ind_t],
            state_t.ElectricPotential[ind_t], state_s.ElectricPotential[ind_s],
            state_t.SEIVoltageDrop[ind_t],
        )
        area = state_t.Volume[ind_t] * params[:volumetric_surface_area]
        return out[] = area * FARADAY_CONSTANT * (params[:n_charge_carriers] * rate - consumption)
    end
end

function Jutul.update_cross_term_in_entity!(
        out, ind, state_t, state0_t, state_s, state0_s, model_t::SEImodel, model_s,
        ct::ButlerVolmerElyteToActmatCT, eq::SEIMassConservation, dt,
        ldisc = local_discretization(ct, ind),
    )
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    params = model_t.system.params
    thickness = state_t.SEIThickness[ind_t]
    previous_thickness = state0_t.SEIThickness[ind_t]
    consumption = sei_molar_flux(
        params, thickness, state_t.Temperature[ind_t],
        state_t.ElectricPotential[ind_t], state_s.ElectricPotential[ind_s],
        state_t.SEIVoltageDrop[ind_t],
    )
    return out[] = params[:StoichiometricCoefficient] / params[:MolarVolume] *
        (thickness - previous_thickness) / dt - consumption
end

function Jutul.update_cross_term_in_entity!(
        out, ind, state_t, state0_t, state_s, state0_s, model_t::SEImodel, model_s,
        ct::ButlerVolmerElyteToActmatCT, eq::SEIVoltageDropEquation, dt,
        ldisc = local_discretization(ct, ind),
    )
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    rate = sei_intercalation_rate(
        state_t, state_s, model_t.system, model_s.system, ind_t, ind_s,
    )
    thickness = state_t.SEIThickness[ind_t]
    conductivity = model_t.system.params[:IonicConductivity]
    # The ionic film drop is driven by intercalation, not the total electronic current.
    return out[] = state_t.SEIVoltageDrop[ind_t] - FARADAY_CONSTANT * rate * thickness / conductivity
end

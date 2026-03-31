##################
# SEI model type #
##################

# Create a type for the model with SEI layer. It will be used to specialize the function
SEImodel = SimulationModel{O, S, F, C} where {
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
        ldisc = nothing
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
        ldisc = nothing
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
    function update_vocp!(
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
    function update_vocp!(
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


###################################
# setup update of the cross terms #
###################################

function Jutul.update_cross_term_in_entity!(
        out,
        ind,
        state_t,
        state0_t,
        state_s,
        state0_s,
        model_t,
        model_s::SEImodel,
        ct::ButlerVolmerActmatToElyteCT,
        eq,
        dt,
        ldisc = local_discretization(ct, ind),
    )

    activematerial = model_s.system
    electrolyte = model_t.system

    n = activematerial.params[:n_charge_carriers]
    vsa = activematerial.params[:volumetric_surface_area]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_a = state_s.ElectricPotential[ind_s]
    seiU = state_s.SEIVoltageDrop[ind_s]
    ocp = state_s.OpenCircuitPotential[ind_s]
    R0 = state_s.ReactionRateConstant[ind_s]
    c_a_surf = state_s.SurfaceConcentration[ind_s]
    c_a = state_s.ParticleConcentration[ind_s]
    T = state_s.Temperature[ind_s]

    vols = state_t.Volume[ind_t]
    phi_e = state_t.ElectricPotential[ind_t]
    c_e = state_t.ElectrolyteConcentration[ind_t]
    c_av = mean(c_a)
    c_av_e = mean(state_t.ElectrolyteConcentration)

    # overpotential include SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU

    if activematerial.params[:setting_butler_volmer] == "Chayambuka"
        R = reaction_rate_chayambuka(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte,
            c_a,
            c_av,
            c_av_e
        )
    else
        R = reaction_rate(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte
        )
    end

    cs = conserved_symbol(eq)

    if cs == :Mass
        v = 1.0 * vols * vsa * R
    else
        @assert cs == :Charge
        v = 1.0 * vols * vsa * R * n * FARADAY_CONSTANT
    end
    return out[] = -v

end


function Jutul.update_cross_term_in_entity!(
        out,
        ind,
        state_t,
        state0_t,
        state_s,
        state0_s,
        model_t::SEImodel,
        model_s,
        ct::ButlerVolmerElyteToActmatCT,
        eq,
        dt,
        ldisc = local_discretization(ct, ind),
    )

    electrolyte = model_s.system
    activematerial = model_t.system

    n = activematerial.params[:n_charge_carriers]
    vsa = activematerial.params[:volumetric_surface_area]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_e = state_s.ElectricPotential[ind_s]
    c_e = state_s.ElectrolyteConcentration[ind_s]

    vols = state_t.Volume[ind_t]
    c_a_surf = state_t.SurfaceConcentration[ind_t]
    c_a = state_t.ParticleConcentration[ind_t]
    phi_a = state_t.ElectricPotential[ind_t]
    seiU = state_t.SEIVoltageDrop[ind_t]
    ocp = state_t.OpenCircuitPotential[ind_t]
    R0 = state_t.ReactionRateConstant[ind_t]
    T = state_t.Temperature[ind_t]
    c_av = mean(c_a)
    c_av_e = mean(state_s.ElectrolyteConcentration)

    # overpotential include SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU

    if activematerial.params[:setting_butler_volmer] == "Chayambuka"
        R = reaction_rate_chayambuka(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte,
            c_a,
            c_av,
            c_av_e
        )
    else
        R = reaction_rate(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte
        )
    end

    return if eq isa SolidDiffusionBc

        rp = activematerial.discretization[:rp] # particle radius
        vf = state_t.VolumeFraction[ind_t]
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

#################################################
# update the equations that are specific to SEI #
#################################################

function Jutul.update_cross_term_in_entity!(
        out,
        ind,
        state_t,
        state0_t,
        state_s,
        state0_s,
        model_t::SEImodel,
        model_s,
        ct::ButlerVolmerElyteToActmatCT,
        eq::SEIMassConservation,
        dt,
        ldisc = local_discretization(ct, ind),
    )

    F = FARADAY_CONSTANT
    R = GAS_CONSTANT

    params = model_t.system.params

    s = params[:StoichiometricCoefficient]
    V = params[:MolarVolume]
    De = params[:ElectronicDiffusionCoefficient]
    ce0 = params[:InterstitialConcentration]
    Lref = params[:InitialThickness]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    L0 = state0_t.SEIThickness[ind_t]

    L = state_t.SEIThickness[ind_t]
    T = state_t.Temperature[ind_t]
    phi_a = state_t.ElectricPotential[ind_t]
    Usei = state_t.SEIVoltageDrop[ind_t]
    L = state_t.SEIThickness[ind_t]

    phi_e = state_s.ElectricPotential[ind_s]

    # compute SEI flux (called N)
    eta = phi_a - phi_e - Usei

    N = De * ce0 / L * exp(-(F / (R * T)) * eta) * (1 - (F / (2 * R * T)) * Usei)

    # Evolution equation for the SEI length
    return out[] = (s / V) * (L - L0) / dt - N

end

function Jutul.update_cross_term_in_entity!(
        out,
        ind,
        state_t,
        state0_t,
        state_s,
        state0_s,
        model_t::SEImodel,
        model_s,
        ct::ButlerVolmerElyteToActmatCT,
        eq::SEIVoltageDropEquation,
        dt,
        ldisc = local_discretization(ct, ind),
    )

    F = FARADAY_CONSTANT

    electrolyte = model_s.system
    activematerial = model_t.system
    params = activematerial.params

    k = params[:IonicConductivity]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_a = state_t.ElectricPotential[ind_t]
    seiU = state_t.SEIVoltageDrop[ind_t]
    ocp = state_t.OpenCircuitPotential[ind_t]
    R0 = state_t.ReactionRateConstant[ind_t]
    c_a_surf = state_t.SurfaceConcentration[ind_t]
    c_a = state_t.ParticleConcentration[ind_t]
    T = state_t.Temperature[ind_t]
    L = state_t.SEIThickness[ind_t]

    phi_e = state_s.ElectricPotential[ind_s]
    c_e = state_s.ElectrolyteConcentration[ind_s]
    c_av = mean(c_a)
    c_av_e = mean(state_s.ElectrolyteConcentration)

    # Overpotential definition  includes SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU

    if activematerial.params[:setting_butler_volmer] == "Chayambuka"
        R = reaction_rate_chayambuka(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte,
            c_a,
            c_av,
            c_av_e
        )
    else
        R = reaction_rate(
            eta,
            c_a_surf,
            R0,
            T,
            c_e,
            activematerial,
            electrolyte
        )
    end

    # Definition of the SEI voltage drop is implicit (because reaction rate R depends on seiU) and is given as follow
    return out[] = seiU - F * R * L / k

end

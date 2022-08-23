export ECComponent

struct ECComponent <: ElectroChemicalComponent end # Not a good name

function minimum_output_variables(
    system::ElectroChemicalComponent, primary_variables
    )
    [:Charge, :Mass, :Energy]
end

function select_primary_variables!(
    S, system::ElectroChemicalComponent, model
    )
    S[:Phi] = Phi()
    S[:C] = C()
    S[:T] = T()
end

function select_secondary_variables!(
    S, system::ElectroChemicalComponent, model
    )
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    # S[:TPkGrad_C] = TPkGrad{C}()
    # S[:TPkGrad_T] = TPkGrad{T}()
    
    S[:Charge] = Charge()
    S[:Mass] = Mass()
    S[:Energy] = Mass()

    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
    S[:ThermalConductivity] = ThermalConductivity()
end

function select_equations!(
    eqs, system::ElectroChemicalComponent, model
    )
    disc = model.domain.discretizations.charge_flow
    T = typeof(disc)

    eqs[:charge_conservation] =  Conservation{Charge, T}(Charge())
    eqs[:mass_conservation] =  Conservation{Mass, T}(Mass())
    eqs[:energy_conservation] =  Conservation{Energy, T}(Energy())
end


export ECComponent

struct ECComponent <: ElectroChemicalComponent end # Not a good name

function select_minimum_output_variables!(out,
                                          system::ElectroChemicalComponent,
                                          model::SimulationModel)
    for k in [:Charge, :Mass, :Energy]
        push!(out, k)
    end
end

function select_primary_variables!(S,
                                   system::ElectroChemicalComponent,
                                   model::SimulationModel)
    
    S[:Phi] = Phi()
    S[:C] = C()
    S[:Temperature] = Temperature()
    
end

function select_secondary_variables!(S,
                                     system::ElectroChemicalComponent,
                                     model::SimulationModel)
    
    S[:Charge] = Charge()
    S[:Mass] = Mass()
    S[:Energy] = Mass()

    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
    S[:ThermalConductivity] = ThermalConductivity()
    
end

function select_equations!(eqs,
                           system::ElectroChemicalComponent,
                           model::SimulationModel)
    
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] =  ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   =  ConservationLaw(disc, :Mass)
    eqs[:energy_conservation] =  ConservationLaw(disc, :Energy)
    
end


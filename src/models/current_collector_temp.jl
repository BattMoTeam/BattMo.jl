export CurrentCollectorT

struct CurrentCollectorTemperature <: ElectroChemicalComponent end
const CCT = SimulationModel{<:Any, <:CurrentCollectorT, <:Any, <:Any}

function select_minimum_output_variables!(out,
    system::CurrentCollectorT, model
    )
    for k in [:Charge, :Energy]#, :EDensityDiag]
        push!(out, k)
    end
end

function select_primary_variables!(
    S, system::CurrentCollectorT, model
    )
    S[:Phi] = Phi()
    S[:Temperature] = Temperature()
end

function select_secondary_variables!(
    S, system::CurrentCollectorT, model
    )
    S[:Charge] = Charge()
    S[:Energy] = Energy()

    S[:Conductivity] = Conductivity()
    S[:ThermalConductivity] = ThermalConductivity()

    S[:BoundaryPhi] = BoundaryPotential(:Phi)
    S[:BoundaryTemperature] = BoundaryPotential(:Temperature)
end


function select_equations!(
    eqs, system::CurrentCollectorT, model
    )
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation] = ConservationLaw(disc, :Mass)
end

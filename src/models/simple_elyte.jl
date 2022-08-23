#=
A simple model of electrolyte without energy conservation
=#

export SimpleElyte

struct SimpleElyte <: Electrolyte end
const SimpleElyteModel = SimulationModel{<:Any, <:SimpleElyte, <:Any, <:Any}


function select_primary_variables!(S, system::SimpleElyte, model)
    S[:Phi] = Phi()
    S[:C] = C()
end

function select_equations!(eqs, system::SimpleElyte, model)
    disc = model.domain.discretizations.charge_flow
    T = typeof(disc)

    eqs[:charge_conservation] =  Conservation{Charge, T}(disc)
    eqs[:mass_conservation] = Conservation{Mass, T}(disc)
end


function select_secondary_variables!(S, system::SimpleElyte, model)
    # S[:TPkGrad_Phi] = TPkGrad{Phi}()
    # S[:TPkGrad_C] = TPkGrad{C}()

    S[:T] = T()
    S[:Conductivity] = Conductivity()
    S[:Diffusivity] = Diffusivity()
    S[:DmuDc] = DmuDc()
    S[:ConsCoeff] = ConsCoeff()

    #S[:TotalCurrent] = TotalCurrent()
    #S[:ChargeCarrierFlux] = ChargeCarrierFlux()

    S[:Charge] = Charge()
    S[:Mass] = Mass()
end

function minimum_output_variables(system::SimpleElyte, primary_variables)
    return [
        :Charge, :Mass, :Conductivity, :Diffusivity
        ]
end

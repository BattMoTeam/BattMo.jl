#=
A simple model of electrolyte without energy conservation
=#

export SimpleElyte

struct SimpleElyte <: Electrolyte
    t::Float64
    z::Float64
    function SimpleElyte(; t = 1, z = 1)
        new(t, z)
    end
end

const SimpleElyteModel = SimulationModel{<:Any, <:SimpleElyte, <:Any, <:Any}


function select_primary_variables!(S, system::SimpleElyte, model)
    S[:Phi] = Phi()
    S[:C] = C()
end

function select_equations!(eqs, system::SimpleElyte, model)
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] =  ConservationLaw(disc, :Charge)
    eqs[:mass_conservation] = ConservationLaw(disc, :Mass)
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

function select_minimum_output_variables!(out, system::SimpleElyte, model)
    for k in [:Charge, :Mass, :Conductivity, :Diffusivity]
        push!(out, k)
    end
end

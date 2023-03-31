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


function select_primary_variables!(S, system::SimpleElyte, model::SimulationModel)
    
    S[:Phi] = Phi()
    S[:C]   = C()
    
end

function select_equations!(eqs, system::SimpleElyte, model::SimulationModel)
    
    disc = model.domain.discretizations.charge_flow

    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)
    
end


function select_secondary_variables!(S, system::SimpleElyte, model::SimulationModel)

    S[:DmuDc]        = DmuDc()
    S[:ConsCoeff]    = ConsCoeff()
    S[:Charge]       = Charge()
    S[:Mass]         = Mass()
    S[:Conductivity] = Conductivity()
    S[:Diffusivity]  = Diffusivity()
    
end

function Jutul.select_parameters!(S, system::SimpleElyte, model::SimulationModel)
    
    S[:Temperature] = Temperature()
    
end

function select_minimum_output_variables!(out, system::SimpleElyte, model::SimulationModel)
    
    for k in [:Charge, :Mass, :Diffusivity, :Conductivity]
        push!(out, k)
    end
    
end

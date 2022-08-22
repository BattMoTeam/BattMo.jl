#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#
using Jutul, BattMo
using MAT
using Test
include("mrstTestUtils.jl")
ENV["JULIA_DEBUG"] = 0;

##
modelnames =[
    "model1D_50",
    #"model1D_500",
    #"model3D_3936",
    #"sector_1656",
    #"sector_1656_org"
    ]

allfine = Vector{Bool}();
@testset "battery" begin
    for modelname in modelnames
        @testset "$modelname" begin
            states, grids, state0, stateref, parameters, exported_all, model, timesteps, cfg, report, sim = test_battery(modelname);
            steps = size(states, 1)
            E = Matrix{Float64}(undef,steps,2)
            for step in 1:steps
                phi = states[step][:BPP][:Phi][1]
                E[step,1] = phi
                phi_ref = stateref[step]["PositiveElectrode"]["CurrentCollector"]["E"]
                E[step,2] = phi_ref
            end
            #append!(allfine,steps == 65)
            #append!(allfine,all(abs.(E[:,1]-E[:,2])./E[:,1] .< 0.1))
            @test isapprox(E[:, 1], E[:, 2], rtol = 0.1)
        end
    end
end

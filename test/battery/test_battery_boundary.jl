#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#
using Jutul, BattMo
using MAT
using Test
# include("mrstTestUtils.jl")
ENV["JULIA_DEBUG"] = 0;

##
testcases  =[
    ("model1D_50", nothing),
    ("model1Dmod_50", nothing),
    ("model1Dmod_500", nothing),
    ("model3D_492", nothing),
  #  ("sector_7920", nothing),
  #  ("sector_1656_org", nothing)
    ]

allfine = Vector{Bool}();
@testset "battery" begin
    for (modelname, max_step) in testcases
        @testset "$modelname" begin
            states, report, extra = test_battery(modelname, max_step = max_step, info_level = -1);
            stateref = extra[:states_ref]
            steps = size(states, 1)
            E = Matrix{Float64}(undef,steps,2)
            for step in 1:steps
                phi = states[step][:BPP][:Phi][1]
                E[step,1] = phi
                phi_ref = stateref[step]["Control"]["E"]
                E[step,2] = phi_ref
            end
            #append!(allfine,steps == 65)
            #append!(allfine,all(abs.(E[:,1]-E[:,2])./E[:,1] .< 0.1))
            @test isapprox(E[:, 1], E[:, 2], rtol = 0.1)
        end
    end
end

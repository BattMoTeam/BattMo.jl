using BattMo
using Test

testcases  =[
    "p2d_40",
    "3d_demo_case"
    ]

@testset "battery" begin
    for modelname in testcases
        @testset "$modelname" begin
            for use_general_ad in [false, true]
                states, report, extra = run_battery(modelname, info_level = -1, general_ad = use_general_ad);
                stateref = extra[:init].object["states"]
                steps = size(states, 1)
                E = Matrix{Float64}(undef, steps, 2)
                for step in 1:steps
                    phi = states[step][:BPP][:Phi][1]
                    E[step, 1] = phi
                    phi_ref = stateref[step]["Control"]["E"]
                    E[step, 2] = phi_ref
                end
                @test isapprox(E[:, 1], E[:, 2], rtol = 0.1)
            end
        end
    end
end

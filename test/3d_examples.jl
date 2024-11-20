using BattMo
using Test


@testset "3d" begin
    
    @test begin
        
        name = "p2d_40_jl_chen2020"

        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
        inputparams = readBattMoJsonInputFile(fn)

        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
        inputparams_geometry = readBattMoJsonInputFile(fn)

        inputparams = mergeInputParams(inputparams_geometry, inputparams)

        output = run_battery(inputparams);
        Cc = map(x -> x[:Control][:Current][1], output.states)
        Phi = map(x -> x[:Control][:Phi][1], output.states)
        @test length(output.states) == 77
        @test Cc[1] ≈ 0.00058 atol = 1e-2
        for i in 3:length(Cc)
            @test Cc[i] ≈ 0.008165 atol = 1e-2
        end
        @test Phi[1] ≈ 4.175 atol = 1e-2
        @test Phi[end] ≈ 2.76 atol = 1e-2
        @test Phi[30] ≈ 3.67 atol = 1e-2
        true
        
    end
    
end


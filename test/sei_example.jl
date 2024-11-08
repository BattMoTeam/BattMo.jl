using BattMo
using Test


@testset "sei layer" begin
    
    @test begin
        
        name = "bolay"

        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
        inputparams = readBattMoJsonInputFile(fn)

        output = run_battery(inputparams);

        true
        
    end
    
end


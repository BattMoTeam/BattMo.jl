using BattMo
using Test

names  =[
    "p2d_40",
    "p2d_40_jl_chen2020",
    "p2d_40_jl_ud_func",
    "p2d_40_jl_ud_tab",
    "p2d_40_no_cc",
    "p2d_40_cccv"
]

names = ["p2d_40_no_cc"]

@testset  begin
    for name in names
        @test begin
            fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
            inputparams = readBattMoJsonInputFile(fn)
            function hook(simulator,
                          model,
                          state0,
                          forces,
                          timesteps,
                          cfg)
                cfg[:error_on_incomplete] = true
            end
            output = run_battery(inputparams; hook = hook)
            true
        end
    end
end
using BattMoDemoApp

empty!(ARGS)
push!(ARGS, "data/p2d_40_jl.json")
# push!(ARGS, "--help")

BattMoDemoApp.julia_main()

# getfile(filename) = JSONFile(string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/", filename))

# fast : functions are given within julia
# init = getfile("p2d_40_jl.json")
# states, reports, extra = run_battery(init);

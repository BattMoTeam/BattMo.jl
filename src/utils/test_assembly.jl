using Jutul, BattMo, GLMakie

doinit = false

if doinit
    
    # ## Setup input parameters
    name = "p2d_40_jl_chen2020"

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
    inputparams = readBattMoJsonInputFile(fn)

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
    inputparams_geometry = readBattMoJsonInputFile(fn)

    inputparams = mergeInputParams(inputparams_geometry, inputparams)

    # ## Setup and run simulation

    output = run_battery(inputparams);

    return
    
end

model      = output[:extra][:model][:Elyte]
state      = output[:states][end][:Elyte]
parameters = output[:extra][:parameters][:Elyte]

operators = BattMo.setupFluxOperator(model.domain.representation)

fluxVector = fluxReconstruction(model, state, parameters, operators)

using Jutul, BattMo, GLMakie

doinit = true

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

    model  = output[:extra][:model]
    maps   = output[:extra][:global_maps]
    states = output[:states]
    
end

doinitthermal = true

if doinitthermal

    using Jutul, BattMo, GLMakie, Statistics

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
    inputparams_geometry = readBattMoJsonInputFile(fn)

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
    inputparams_thermal = readBattMoJsonInputFile(fn)

    inputparams = mergeInputParams(inputparams_geometry, inputparams_thermal)

    inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
    inputparams["ThermalModel"]["source"]                          = 1e4
    inputparams["ThermalModel"]["conductivity"]                    = 12

    # model, parameters = BattMo.setup_thermal_model(inputparams)
    thermal_model, thermal_parameters = BattMo.setup_thermal_model(Val(:simple), inputparams; N = 3, Nz = 3)

    nc = number_of_cells(thermal_model.domain)

    src = Vector{Float64}(undef, nc)
    
end


if doinitthermal | doinit

    return
    
end


state = states[1]
state = BattMo.getStateWithSecondaryVariables(model, state, parameters)

BattMo.getEnergySource!(thermal_model, model, state, maps)

return
models = output[:extra][:model].models


# operators = BattMo.setupFluxOperator(model.domain.representation)

# fluxVector = fluxReconstruction(model, state, parameters, operators)

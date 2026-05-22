using BattMo, Jutul, Test


@testset "thermal" begin

    @test begin

        # ## Setup input parameters
        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
        inputparams_material = load_advanced_dict_input(fn)

        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
        inputparams_geometry = load_advanced_dict_input(fn)

        inputparams = merge_input_params([inputparams_material, inputparams_geometry])

        # Add control parameters
        fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
        inputparams_control = load_advanced_dict_input(fn)

        inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

        # Add thermal parameters
        fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
        inputparams_thermal = load_advanced_dict_input(fn)

        inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

        # Add Thermal Model
        inputparams["use_thermal"] = true

        # Add thermal parameters
        # inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 1e20
        # inputparams["ThermalModel"]["source"]                          = 1e4
        # inputparams["ThermalModel"]["conductivity"]                    = 12

        output = run_simulation(inputparams; accept_invalid = true)

        model = output.model
        multimodel = model.multimodel
        states = output.jutul_output.states
        parameters = output.simulation.parameters
        grids = output.simulation.grids
        maps = output.simulation.global_maps
        timesteps = output.simulation.time_steps[1:length(states)]

        t = output.time_series["Time"]
        E = output.time_series["Voltage"]
        I = output.time_series["Current"]


        tstates = output.jutul_output.states
        elyte_temp = map(s -> maximum(s[:Electrolyte][:Temperature]), tstates)

        @test length(elyte_temp) ≈ 73 atol = 0
        @test elyte_temp[2] ≈ 298.2655978676414 atol = 1.0e-1
        @test elyte_temp[end] ≈ 319.1879488728503 atol = 1.0e-1

        true

    end

end

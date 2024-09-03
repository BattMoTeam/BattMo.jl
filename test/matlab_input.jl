using BattMo, MAT, Test

names = ["p2d_40",
         "p2d_40_no_cc"]


@testset "matlab tests" begin

    for name in names
        
        @test begin
            
            fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", name, ".mat")
            inputparams = readBattMoMatlabInputFile(fn)
            inputparams.dict["use_state_ref"] = true
            states, cellSpecifications, reports, extra = run_battery(inputparams, max_step = nothing);

            t = [state[:Control][:ControllerCV].time for state in states]
            E = [state[:Control][:Phi][1] for state in states]
            I = [state[:Control][:Current][1] for state in states]

            nsteps = size(states, 1)

            statesref = extra[:inputparams].dict["states"]
            timeref   = t
            Eref      = [state["Control"]["E"] for state in statesref[1 : nsteps]]

            true

        end
        
    end
    
end


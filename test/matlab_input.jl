using BattMo, MAT, Test

tests = [(name = "p2d_40", errval = 2e-3)
	(name = "p2d_40_no_cc", errval = 2e-3)
	(name = "3d_demo_case", errval = 7e-3)]

@testset "matlab tests" begin

	for test in tests

		@testset "$(test[:name])" begin

			@test begin

				fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", test[:name], ".mat")
				inputparams = load_parameters(fn, MatlabBattMoInput)
				inputparams.dict["use_state_ref"] = true
				states, cellSpecifications, reports, extra = run_battery(inputparams, max_step = nothing)

				t = [state[:Control][:ControllerCV].time for state in states]
				E = [state[:Control][:Phi][1] for state in states]
				I = [state[:Control][:Current][1] for state in states]

				nsteps = size(states, 1)

				statesref = inputparams["states"]
				timeref   = t
				Eref      = [state["Control"]["E"] for state in statesref[1:nsteps]]

				isapprox(E, Eref, rtol = test[:errval])

			end

		end

	end

end


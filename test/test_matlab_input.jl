using BattMo, MAT, Test

@testset "matlab test" begin

	@test begin

        errval = 1e-5
        
        fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/p2d_40.mat")
        inputparams = load_matlab_input(fn)

        output = BattMo.get_simulation_input(inputparams::MatlabInput)

        simulator  = output[:simulator]
        model      = output[:model]
        parameters = output[:parameters]
        state0     = output[:state0]
        timesteps  = output[:timesteps]
        forces     = output[:forces]

        ##############################
        # Setup solver configuration #
        ##############################

        cfg = simulator_config(simulator)
        cfg[:info_level] = 0

        use_model_scaling = true
        if use_model_scaling
	        scalings = BattMo.get_matlab_scalings(model, parameters)
	        tol_default = 1e-5
	        for scaling in scalings
		        model_label = scaling[:model_label]
		        equation_label = scaling[:equation_label]
		        value = scaling[:value]
		        cfg[:tolerances][model_label][equation_label] = value * tol_default
	        end
        else
	        for key in submodels_symbols(model)
		        cfg[:tolerances][key][:default] = 1e-5
	        end
        end

        states, = simulate(state0, simulator, timesteps; forces = forces, config = cfg)


        t = [state[:Control][:Controller].time[1] for state in states]
        E = [state[:Control][:ElectricPotential][1] for state in states]

        matlab_states = inputparams["states"]

        tref = vec([state["time"][1] for state in matlab_states])
        Eref = vec([state["Control"]["E"][1] for state in matlab_states])

		isapprox(E, Eref[1 : length(t)], rtol = errval)

	end

end



module BattMoDemoApp
    using BattMo, ArgParse, GLMakie

    function parse_commandline()
        s = ArgParseSettings(
            description = "BattMo demo app",
            version = "0.0.1",
            add_version = true
        )
        s.autofix_names = true

        @add_arg_table s begin
            "filename"
            help = ".json file to simulate."
            required = true
        end

        add_arg_group(s, "nonlinear solver");
        @add_arg_table s begin
            "--max-nonlinear-iterations"
                help = "maximum number of nonlinear iterations before time-step is cut"
                arg_type = Int
                default = 15
            "--max-timestep-cuts"
                help = "maximum number of time-step cuts in a single report step solve"
                arg_type = Int
                default = 20
        end

        add_arg_group(s, "output and printing");
        @add_arg_table s begin
            "--info-level"
            help = "level out output. Set to -1 for no output."
            arg_type = Int
            default = 0
            "--verbose"
                help = "extra output from the app itself. For simulation convergence reporting, see --info-level"
                arg_type = Bool
                default = true
            "--output-path"
                help = "path where output results are to be written. A random temporary folder will be created if not provided."
                default = ""
        end

        return parse_args(s)
    end

    function julia_main()::Cint
        args = parse_commandline()
        if isnothing(args)
            return 0
        end
        init = JSONFile(args["filename"]) # "p2d_40_jl.json"
        states, reports, extra = run_battery(init,
            max_nonlinear_iterations = args["max_nonlinear_iterations"],
            max_timestep_cuts = args["max_timestep_cuts"],
            info_level = args["info_level"]
        );
        voltage = map(state -> state[:BPP][:Phi][1], states)
        t = cumsum(extra[:timesteps])
        fig = Figure()
        ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
        lines!(ax, t, voltage)
        wait(display(fig))
        return 0
    end

end # module BattMoDemoApp

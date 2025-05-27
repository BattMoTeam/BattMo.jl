abstract type AbstractCalibration end

struct VoltageCalibration <:AbstractCalibration
    t
    v
    sim
    parameter_targets
    function VoltageCalibration(t, v, sim)
        @assert length(t) == length(v)
        for i in 2:length(t)
            @assert t[i] > t[i - 1]
        end
        return new(t, v, deepcopy(sim), Dict{Vector{String}, Any}())
    end
end

function VoltageCalibration(t_and_v, sim; normalize_time = false)
    t = t_and_v[:, 1]
    v = t_and_v[:, 2]
    if normalize_time
        t = t .- minimum(t)  # Normalize time to start at zero
    end
    return VoltageCalibration(t, v, sim)
end

function free_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String};
            initial_value = missing,
            lower_bound = missing,
            upper_bound = missing
        )

    if ismissing(lower_bound) || ismissing(upper_bound)
        throw(ArgumentError("$parameter_name: Bounds must be set for free parameters (defaults not implemented)"))
    end
    if !ismissing(initial_value)
        set_calibration_parameter!(vc, parameter_name, initial_value)
    end
    initial_value = get_nested_json_value(vc.sim.cell_parameters, parameter_name)
    if initial_value < lower_bound || initial_value > upper_bound
        throw(ArgumentError("Initial value for for $parameter_name $initial_value out of bounds [$lower_bound, $upper_bound]"))
    end
    if lower_bound >= upper_bound
        throw(ArgumentError("Lower bound for $parameter_name $lower_bound must be less than upper bound $upper_bound"))
    end
    vc.parameter_targets[parameter_name] = (v0 = initial_value, vmin = lower_bound, vmax = upper_bound)
    return vc
end

function freeze_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, val = missing)
    if !ismissing(val)
        set_calibration_parameter!(vc, parameter_name, val)
    end
    delete!(vc.parameter_targets, parameter_name)
end

function print_calibration_overview(vc::AbstractCalibration)
        function print_table(subkeys, t)
        header = ["Parameter name", "Initial Value", "Lower Bound", "Upper Bound", "Optimized value", "Change"]
        tab = Matrix{Any}(undef, length(subkeys), 6)
        # widths = zeros(Int, size(tab, 2))
        # widths[1] = 40
        for (i, k) in enumerate(subkeys)
            v0 = pt[k].v0
            v = value(get_nested_json_value(vc.sim.cell_parameters, k))
            perc = round(100*(v-v0)/max(v0, 1e-20), digits = 2)
            tab[i, 1] = join(k[2:end], ".")
            tab[i, 2] = v0
            tab[i, 3] = pt[k].vmin
            tab[i, 4] = pt[k].vmax
            tab[i, 5] = v
            tab[i, 6] = "$perc%"
        end
        # TODO: Do this properly instead of via Jutul's import...
        Jutul.PrettyTables.pretty_table(tab, header=header, title = t)#,autowrap=true,columns_width=widths)
    end

    pt = vc.parameter_targets
    pkeys = keys(pt)
    outer_keys = String[]
    for k in pkeys
        push!(outer_keys, first(k))
    end
    outer_keys = unique!(outer_keys)
    for outer_key in outer_keys
        subkeys = filter(x -> x[1] == outer_key, pkeys)
        print_table(subkeys, "$outer_key: Active calibration parameters")
    end
end

function set_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, value)
    set_nested_json_value!(vc.sim.cell_parameters, parameter_name, value)
end

function setup_calibration_objective(vc::VoltageCalibration)
    # Set up the objective function
    V_fun = get_1d_interpolator(vc.t, vc.v, cap_endpoints = true)
    total_time = vc.t[end]
    function objective(model, state, dt, step_info, forces)
        # t = step_info[:time]
        t = state[:Control][:Controller].time
        V_obs = V_fun(t)
        V_sim = state[:Control][:Phi][1]
        return voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
    end
    return objective
end

function voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
    return dt * (V_obs - V_sim)^2/total_time
end

function evaluate_calibration_objective(vc::VoltageCalibration, objective, case, states, dt)
    f = Jutul.evaluate_objective(objective, case.model, states, dt, case.forces)
    # Time varies - so add in a term if the simulation ends early.
    # total_time = sum(dt)
    # time_delta = max(vc.t[end] - total_time, 0)
    # V_end = states[end][:Control][:Phi][1]
    # # time_delta*(vc.v[end] - V_end)^2
    # f += voltage_squared_error(vc., )
    return f
end

function solve(vc::AbstractCalibration)
    pt = vc.parameter_targets
    pkeys = collect(keys(pt))
    if length(pkeys) == 0
        throw(ArgumentError("No free parameters set, unable to calibrate."))
    end
    sim = vc.sim
    # Set up the objective function
    objective = setup_calibration_objective(vc)

    # Set up the functions to serialize
    x0, x_setup = Jutul.AdjointsDI.vectorize_nested(sim.cell_parameters.all,
        active = pkeys,
        active_type = Real
    )

    ub = similar(x0)
    lb = similar(x0)
    offsets = x_setup.offsets
    for (i, k) in enumerate(x_setup.names)
        (; vmin, vmax) = pt[k]
        for j in offsets[i]:(offsets[i+1]-1)
            lb[j] = vmin
            ub[j] = vmax
        end
    end

    # @info "Set up calibration" x0 ub lb

    setup_battmo_case(X, step_info = missing) = setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
    function solve_and_differentiate(x)
        case = setup_battmo_case(x)
        states, dt = simulate_battmo_case_for_calibration(case)
        # Evaluate the objective function
        f = evaluate_calibration_objective(vc, objective, case, states, dt)
        # @info "Objective function value" f x x_setup.names
        # error()
        # Solve adjoints
        g = Jutul.AdjointsDI.solve_adjoint_generic(
            x, setup_battmo_case, states, dt, objective,
            use_sparsity = false,
            single_step_sparsity = false,
            do_prep = false
        )
        # @info "Updated" f g
        if false
            # ϵ = 1e-10*only(x)
            ϵ = 1e-3
            case_delta = setup_battmo_case(x .+ ϵ)
            states2, dt2, = simulate_battmo_case_for_calibration(case_delta)
            f_delta = Jutul.evaluate_objective(objective, case_delta.model, states2, dt2, case_delta.forces)
            d_num = (f_delta - f)/ϵ
            @info "Numerical gradient" d_num only(g) length(dt)
            # g[1] = d_num
            # g = [d_num]
        end
        return (f, g)
    end

    if true
        v, x, history = Jutul.LBFGS.box_bfgs(x0, solve_and_differentiate, lb, ub; maximize = false, print = 1)
    else
        self_cache = Dict()
        function f!(x)
            f, g = solve_and_differentiate(x)
            self_cache[:f] = f
            self_cache[:g] = g
            self_cache[:x] = x
            return f
        end

        function g!(z, x)
            if self_cache[:x] !== x
                f!(x)  # Update the cache if the vector has changed
            end
            g = self_cache[:g]
            return z .= g
        end
        history, x = Main.lbfgsb(f!, g!, x0, lb = lb, ub = ub, iprint = 1, maxfun = 200, maxiter = 100)
    end
    # Also remove AD from the internal ones and update them
    Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, x, x_setup)
    cell_prm_out = deepcopy(sim.cell_parameters)
    return (cell_prm_out, history)
end

function setup_battmo_case_for_calibration(X, sim, x_setup, step_info = missing)
    T = eltype(X)
    Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, X, x_setup)
    inputparams = convert_parameter_sets_to_battmo_input(
        sim.model_setup.model_settings,
        sim.cell_parameters,
        sim.cycling_protocol,
        sim.simulation_settings
    )
    model, parameters = setup_model(inputparams, T = T)
    state0 = BattMo.setup_initial_state(inputparams, model)
    forces = setup_forces(model)
    timesteps = BattMo.setup_timesteps(inputparams)

    return Jutul.JutulCase(model, timesteps, forces, parameters = parameters, state0 = state0, input_data = inputparams)
end

function simulate_battmo_case_for_calibration(case;
        simulator = missing,
        config = missing
    )
    if ismissing(simulator)
        simulator = Simulator(case)
    end
    if ismissing(config)
        config = setup_config(simulator,
            case.model,
            case.parameters,
            :direct,
            false,
            true,
            info_level = -1
        )
    end
    
    result = Jutul.simulate!(simulator,
        case.dt,
        state0 = case.state0,
        parameters = case.parameters,
        forces = case.forces,
        config = config,
    )
    # last_solves = result.reports[end][:ministeps][end]
    # if !result.reports[end][:ministeps][end][:success]
        # TODO: handle case where the solver fails.
    #    g = fill(1e20, length(x))
    #    return (1e20, g)
    #end
    states, dt, = Jutul.expand_to_ministeps(result)
    return (states, dt)
end

struct VoltageCalibration
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

function free_calibration_parameter!(vc::VoltageCalibration, parameter_name::Vector{String};
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

function freeze_calibration_parameter!(vc::VoltageCalibration, parameter_name::Vector{String}, val = missing)
    if !ismissing(val)
        set_calibration_parameter!(vc, parameter_name, val)
    end
    delete!(vc.parameter_targets, parameter_name)
end

function print_calibration_overview(vc::VoltageCalibration)
    header = ["Parameter name", "Initial Value", "Lower Bound", "Upper Bound"]
    pt = vc.parameter_targets
    pkeys = keys(pt)

    tab = Matrix{Any}(undef, length(pkeys), 4)
    for (i, k) in enumerate(pkeys)
        tab[i, 1] = join(k, ".")
        tab[i, 2] = pt[k].v0
        tab[i, 3] = pt[k].vmin
        tab[i, 4] = pt[k].vmax
    end
    # TODO: Do this properly instead of via Jutul's import...
    Jutul.PrettyTables.pretty_table(tab, header=header)
end

function set_calibration_parameter!(vc::VoltageCalibration, parameter_name::Vector{String}, value)
    set_nested_json_value!(vc.sim.cell_parameters, parameter_name, value)
end

function solve(vc::VoltageCalibration)
    pt = vc.parameter_targets
    pkeys = collect(keys(pt))
    if length(pkeys) == 0
        throw(ArgumentError("No free parameters set, unable to calibrate."))
    end
    sim = vc.sim
    # Set up the objective function
    V_fun = get_1d_interpolator(vc.t, vc.v, cap_endpoints = false)
    function objective(model, state, dt, step_info, forces)
        t = step_info[:time] + dt
        V_obs = V_fun(t)
        V_sim = state[:Control][:Phi][1]
        return dt * (V_obs - V_sim)^2
    end

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
    function setup_battmo_case(X, step_info = nothing)
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

    simulator = cfg = missing
    function solve_and_differentiate(x)
        case = setup_battmo_case(x)
        if ismissing(simulator)
            simulator = Simulator(case)
            cfg = setup_config(simulator,
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
            config = cfg
        )
        states, dt, = Jutul.expand_to_ministeps(result)
        # Evaluate the objective function
        f = Jutul.evaluate_objective(objective, case.model, states, dt, case.forces)
        # @info "Objective function value" f
        # Solve adjoints
        g = Jutul.AdjointsDI.solve_adjoint_generic(x, setup_battmo_case, states, dt, objective)
        if false
            ϵ = 1e-12*only(x)
            case_delta = setup_battmo_case(x .+ ϵ)
            result_delta = Jutul.simulate!(simulator,
                case_delta.dt,
                state0 = case_delta.state0,
                parameters = case_delta.parameters,
                forces = case_delta.forces,
                config = cfg
            )
            states2, dt2, = Jutul.expand_to_ministeps(result_delta)
            f_delta = Jutul.evaluate_objective(objective, case_delta.model, states2, dt2, case_delta.forces)
            # @info "Numerical gradient" (f_delta - f)/ϵ
        end
        return (f, g)
    end
    v, x, history = Jutul.LBFGS.box_bfgs(x0, solve_and_differentiate, lb, ub; maximize = false, print = 1)
    cell_prm_out = deepcopy(sim.cell_parameters)
    Jutul.AdjointsDI.devectorize_nested!(cell_prm_out.all, x, x_setup)
    return (cell_prm_out, history)
end

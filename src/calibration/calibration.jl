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
        throw(ArgumentError("Bounds must be set for free parameters (defaults not implemented)"))
    end
    if !ismissing(initial_value)
        set_calibration_parameter!(vc, parameter_name, initial_value)
    end
    initial_value = get_nested_json_value(vc.sim.cell_parameters, parameter_name)
    if initial_value < lower_bound || initial_value > upper_bound
        throw(ArgumentError("Initial value $initial_value out of bounds [$lower_bound, $upper_bound]"))
    end
    if lower_bound >= upper_bound
        throw(ArgumentError("Lower bound $lower_bound must be less than upper bound $upper_bound"))
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
    V_fun = get_1d_interpolator(vc.t, vc.v)
    function objective(model, state, dt, step_info, forces)
        t = step_info[:time]
        V_obs = V_fun(t)
        V_sim = state[:Control][:Phi][1]
        return dt * (V_obs - V_sim)^2
    end

    # Set up the functions to serialize
    x, x_setup = Jutul.AdjointsDI.vectorize_nested(sim.cell_parameters.all,
        active = pkeys,
        active_type = Real
    )

    function setup_battmo_case(X)
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
        output = setup_simulation(deepcopy(inputparams), use_p2d = true)

        return Jutul.JutulCase(model, timesteps, forces, parameters = parameters, state0 = state0, input_data = inputparams)
    end
    case = setup_battmo_case(x)

    simulator = Simulator(case)
	cfg = setup_config(simulator,
        case.model,
        case.parameters,
        :direct,
        false,
        true
    )

    result = Jutul.simulate!(simulator, case.dt, forces = case.forces, config = cfg)
    # Solve adjoints
    dg = Jutul.AdjointsDI.solve_adjoint_generic(x, setup_battmo_case, result.states, result.reports, objective)
    # Scaling of dg...
    # Put inside optimizer unit_box_bfgs
end

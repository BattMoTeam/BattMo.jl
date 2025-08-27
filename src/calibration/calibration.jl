export VoltageCalibration
export free_calibration_parameter!, freeze_calibration_parameter!, set_calibration_parameter!
export print_calibration_overview


abstract type AbstractCalibration end

mutable struct VoltageCalibration <:AbstractCalibration
    "Time vector for the calibration data."
    t
    "Voltage vector for the calibration data."
    v
    "The simulation object used for calibration. This is a copy of the original simulation object, so that the original simulation can be reused."
    sim
    "A dictionary containing the calibration parameters and their targets. The keys are vectors of strings representing the parameter names, and the values are tuples with the initial value, lower bound, and upper bound."
    parameter_targets
    "The calibrated cell parameters (once solved)."
    calibrated_cell_parameters
    "History of the optimization process, containing information about the optimization steps."
    history

    "Prior distribution for the calibration parameters, if any. The parameters are considered to be drawn from independant lognormal distributions"
    parameter_priors

    "Gaussian noise of the data (used for MAP estimation with priors)"
    σ2::Float64

    """
        VoltageCalibration(t, v, sim)

    Set up calibration for a voltage calibration problem for given time vector
    `t` and voltage vector `v` and a `Simulation` instance `sim`
    """
    function VoltageCalibration(t, v, sim)
        @assert length(t) == length(v)
        for i in 2:length(t)
            @assert t[i] > t[i - 1]
        end
        return new(t, v, deepcopy(sim), Dict{Vector{String}, Any}(), missing, missing, Dict{Vector{String}, Any}(),1)
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

"""
    free_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String};
            initial_value = missing,
            lower_bound = missing,
            upper_bound = missing
            prior_mean = missing,
            prior_std = missing
        )

Set a calibration parameter to be free for optimization. The parameter is
specified by `parameter_name`, which is a vector of strings representing the
nested structure of the parameter in the simulation's cell parameters.

# Notes
- The `initial_value` is optional and can be set to `missing` if not provided.
- The `lower_bound` and `upper_bound` must be provided and cannot be `missing`.
- Optionally, a prior distribution (gaussian) can be specified via `prior_mean` and `prior_std`.
"""
function free_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String};
            initial_value = missing,
            lower_bound = missing,
            upper_bound = missing,
            prior_mean = missing,
            prior_std = missing
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
    if !ismissing(prior_mean) && !ismissing(prior_std)
        vc.parameter_priors[parameter_name] = (prior_mean, prior_std)
    end
    return vc
end

"""
    freeze_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, val = missing)

Remove a calibration parameter from the optimization process, optionally setting
its value to `val`.
"""
function freeze_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, val = missing)
    if !ismissing(val)
        set_calibration_parameter!(vc, parameter_name, val)
    end
    delete!(vc.parameter_targets, parameter_name)
end

"""
    print_calibration_overview(vc::AbstractCalibration)

Print an overview of the calibration parameters and their current values. If the
calibration has been performed, the table will also include the optimized values
and the percentage change from the initial values.
"""
function print_calibration_overview(vc::AbstractCalibration)
        function print_table(subkeys, t)
            opt_cell = vc.calibrated_cell_parameters
            is_optimized = !ismissing(opt_cell)
            header = ["Name", "Initial value", "Bounds"]
            if is_optimized
                push!(header, "Optimized value")
                push!(header, "Change")
            end
            tab = Matrix{Any}(undef, length(subkeys), length(header))
            # widths = zeros(Int, size(tab, 2))
            # widths[1] = 40
            for (i, k) in enumerate(subkeys)
                v0 = pt[k].v0
                tab[i, 1] = join(k[2:end], ".")
                tab[i, 2] = v0
                tab[i, 3] = "$(pt[k].vmin) - $(pt[k].vmax)"
                if is_optimized
                    v = value(get_nested_json_value(opt_cell, k))
                    perc = round(100*(v-v0)/max(v0, 1e-20), digits = 2)
                    tab[i, 4] = v
                    tab[i, 5] = "$perc%"
                end
            end
            # TODO: Do this properly instead of via Jutul's import...
            Jutul.PrettyTables.pretty_table(tab, header=header, title = t)
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

"""
    set_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, value)

Set a calibration parameter to a specific value.
"""
function set_calibration_parameter!(vc::AbstractCalibration, parameter_name::Vector{String}, value)
    set_nested_json_value!(vc.sim.cell_parameters, parameter_name, value)
end

function setup_calibration_objective(vc::VoltageCalibration)
    # Set up the objective function
    V_fun = get_1d_interpolator(vc.t, vc.v, cap_endpoints = true)
    total_time = vc.t[end]
    function objective(model, state, dt, step_info, forces)
        t = state[:Control][:Controller].time
        if step_info[:step] == step_info[:Nstep]
            dt = max(dt, total_time - t)
        end
        V_obs = V_fun(t)
        V_sim = state[:Control][:Phi][1]
        

        return voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
    end
    return objective
end


function voltage_squared_error(V_obs, V_sim, dt, step_info, total_time)
    return dt * (V_obs - V_sim)^2 #/total_time
end

function evaluate_calibration_objective(vc::VoltageCalibration, objective, case, states, dt)
    f = Jutul.evaluate_objective(objective, case.model, states, dt, case.forces)
    return f
end

function prior_regularization_term(x,mean,std)
    # Returns the regularization term for the prior distribution and its gradient (assuming gaussian priors)
    return (sum((x .- mean).^2 ./ (2 .* std.^2)), (x .- mean) ./ std.^2)
end




function solve(vc::AbstractCalibration;
        grad_tol = 1e-6,
        obj_change_tol = 1e-6,
        opt_fun = missing,
        scaling = :linear,
        backend_arg = (
            use_sparsity = false,
            di_sparse = true,
            single_step_sparsity = false,
            do_prep = true,
        ),
        kwarg...
        
        
    )
    sim = deepcopy(vc.sim)
    x0, x_setup = vectorize_cell_parameters_for_calibration(vc, sim)
    

    ub = similar(x0)
    lb = similar(x0)
    """
    log_lb = log.(lb)
    log_ub = log.(ub)
    δ_log = log_ub .- log_lb
    """

    
    offsets = x_setup.offsets
    for (i, k) in enumerate(x_setup.names)
        (; vmin, vmax) = vc.parameter_targets[k]
        
        
        for j in offsets[i]:(offsets[i+1]-1)
            lb[j] = vmin
            ub[j] = vmax
            
        end
    end
  
    adj_cache = Dict()

    # Set up the objective function
    objective = setup_calibration_objective(vc)
    
  
    setup_battmo_case(X, step_info = missing) = setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
    
    solve_and_differentiate(x) = solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
            adj_cache = adj_cache,
            backend_arg
        )
        


    jutul_message("Calibration", "Starting calibration of $(length(x0)) parameters.", color = :green)

    t_opt = @elapsed if ismissing(opt_fun)
        if scaling == :log
            # Use log-scaled BFGS optimization
            @info "log scaled BFGS optimization started."
        v, x, history = Jutul.LBFGS.log_box_bfgs(x0, solve_and_differentiate, lb, ub;
            maximize = false,
            print = 1,
            grad_tol = grad_tol,
            obj_change_tol = obj_change_tol,
            output_hessian = true,
            limited_memory = false,
            kwarg...
        )
        
        else
            # Use standard BFGS optimization
            @info "BFGS optimization started."
            
        v, x, history = Jutul.LBFGS.box_bfgs(x0, solve_and_differentiate, lb, ub;
            maximize = false,
            print = 1,
            grad_tol = grad_tol,
            obj_change_tol = obj_change_tol,
            kwarg...
        )
        end   
        
        
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
        x, history = opt_fun(f!, g!, x0, lb, ub)
    end
    jutul_message("Calibration", "Calibration finished in $t_opt seconds.", color = :green)
    # Also remove AD from the internal ones and update them
    Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, x, x_setup)
    cell_prm_out = deepcopy(sim.cell_parameters)
    vc.calibrated_cell_parameters = cell_prm_out
    vc.history = history
    return (cell_prm_out, history)
end


function solve_with_priors(vc::AbstractCalibration;
        grad_tol = 1e-6,
        obj_change_tol = 1e-6,
        opt_fun = missing,
        scaling = :linear,
        backend_arg = (
            use_sparsity = false,
            di_sparse = true,
            single_step_sparsity = false,
            do_prep = true,
        ),
        
        kwarg...
        
        
    )
    sim = deepcopy(vc.sim)
    x0, x_setup = vectorize_cell_parameters_for_calibration(vc, sim)
    
    vc.σ2 = 0.0001* maximum(vc.v)

    ub = similar(x0)
    lb = similar(x0)
    """
    log_lb = log.(lb)
    log_ub = log.(ub)
    δ_log = log_ub .- log_lb
    """
    #Mean and std of the prior distributions
    mean = similar(x0)
    std = similar(x0)

    
    offsets = x_setup.offsets
    for (i, k) in enumerate(x_setup.names)
        (; vmin, vmax) = vc.parameter_targets[k]
        (mean_k, std_k) = vc.parameter_priors[k]
        
        for j in offsets[i]:(offsets[i+1]-1)
            lb[j] = vmin
            ub[j] = vmax
            mean[j] = mean_k
            std[j] = std_k
        end
    end
    """
    for j in 1:length(x0)
        if scaling == :log
            # Use log scaling for the bounds
            mean[j] = (mean[j] - log_lb[j])/ δ_log[j]
            std[j] = std[j] / δ_log[j]
        end
    end
    """
    adj_cache = Dict()

    # Set up the objective function
    objective = setup_calibration_objective(vc)
    
    function solve_and_differentiate_with_priors(x)
            f, g = solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
                adj_cache = adj_cache,
                backend_arg,
                gradient = true
            )
            # Add the prior regularization term
            f_r, g_r = prior_regularization_term(x, mean, std)
            f += f_r* vc.σ2
            g .+= g_r * vc.σ2
           
            return (f, g)
        end

    setup_battmo_case(X, step_info = missing) = setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
    
   
        


    jutul_message("Calibration", "Starting calibration of $(length(x0)) parameters.", color = :green)

    t_opt = @elapsed if ismissing(opt_fun)
        if scaling == :log
            # Use log-scaled BFGS optimization
            @info "log scaled BFGS optimization started."
        v, x, history = Jutul.LBFGS.log_box_bfgs(x0, solve_and_differentiate_with_priors, lb, ub;
            maximize = false,
            print = 1,
            grad_tol = grad_tol,
            obj_change_tol = obj_change_tol,
            output_hessian = true,
            limited_memory = false,
            kwarg...
        )
        
        else
            # Use standard BFGS optimization
            @info "BFGS optimization started."
            
        v, x, history = Jutul.LBFGS.box_bfgs(x0, solve_and_differentiate_with_priors, lb, ub;
            maximize = false,
            print = 1,
            grad_tol = grad_tol,
            obj_change_tol = obj_change_tol,
            kwarg...
        )
        end   
        
        
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
        x, history = opt_fun(f!, g!, x0, lb, ub)
    end
    jutul_message("Calibration", "Calibration finished in $t_opt seconds.", color = :green)
    # Also remove AD from the internal ones and update them
    Jutul.AdjointsDI.devectorize_nested!(sim.cell_parameters.all, x, x_setup)
    cell_prm_out = deepcopy(sim.cell_parameters)
    vc.calibrated_cell_parameters = cell_prm_out
    vc.history = history
    return (cell_prm_out, history)
end

#Solves the calibration problem for multiple random initializations around the initial guess
function solve_random_init(vc::AbstractCalibration;
        n_samples = 10,
        grad_tol = 1e-6,
        obj_change_tol = 1e-6,
        opt_fun = missing,
        scaling = :linear,
        backend_arg = (
            use_sparsity = false,
            di_sparse = true,
            single_step_sparsity = false,
            do_prep = true,
        ),

        kwarg...
        
        
    )

    results = []
    sim = deepcopy(vc.sim)
    x0, x_setup = vectorize_cell_parameters_for_calibration(vc, sim)
    
   

    ub = similar(x0)
    lb = similar(x0)


    
    offsets = x_setup.offsets
    for (i, k) in enumerate(x_setup.names)
        (; vmin, vmax) = vc.parameter_targets[k]
        
        
        for j in offsets[i]:(offsets[i+1]-1)
            lb[j] = vmin
            ub[j] = vmax
           
        end
    end
    
    adj_cache = Dict()

    # Set up the objective function
    objective = setup_calibration_objective(vc)
    

    setup_battmo_case(X, step_info = missing) = setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
    
    solve_and_differentiate(x) = solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
            adj_cache = adj_cache,
            backend_arg
        )
    
        


    jutul_message("Calibration", "Starting calibration of $(length(x0)) parameters.", color = :green)

    for i in 1:n_samples
        @info "Calibration: Sample $i of $n_samples"
        x_i = x0 + rand(length(x0)) .* (ub .- lb)/100  # Random initialization within bounds
        @info x_i
        @info x_i .- x0
        try
            if ismissing(opt_fun)
            if scaling == :log
                # Use log-scaled BFGS optimization
                @info "log scaled BFGS optimization started."
            v, x, history = Jutul.LBFGS.log_box_bfgs(x_i, solve_and_differentiate, lb, ub;
                maximize = false,
                print = 1,
                grad_tol = grad_tol,
                obj_change_tol = obj_change_tol,
                output_hessian = true,
                limited_memory = false,
                kwarg...
            )
            if v<=10
                push!(results,(x,v))
            end
            else
                # Use standard BFGS optimization
                @info "BFGS optimization started."
            
            v, x, history = Jutul.LBFGS.box_bfgs(x_i, solve_and_differentiate, lb, ub;
                maximize = false,
                print = 1,
                grad_tol = grad_tol,
                obj_change_tol = obj_change_tol,
                kwarg...
            )
            end   
        
        
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
            x, history = opt_fun(f!, g!, x0, lb, ub)
        end
        catch e
            
            @error "Calibration failed for sample $i: $(e)"
            continue  # Skip to the next sample if an error occurs
        end
    end
    jutul_message("Calibration", "Calibration finished", color = :green)
    
    return results
end

function solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
        adj_cache = Dict(),
        backend_arg = NamedTuple(),
        gradient = true
    )
    case = setup_battmo_case(x)
    states, dt = simulate_battmo_case_for_calibration(case)
    # Evaluate the objective function
    f = evaluate_calibration_objective(vc, objective, case, states, dt)
    # Solve adjoints
    if gradient
        if !haskey(adj_cache, :storage)
            adj_cache[:storage] = Jutul.AdjointsDI.setup_adjoint_storage_generic(
                x, setup_battmo_case, states, dt, objective;
                backend_arg...,
                info_level = 0
            )
        end
        S = adj_cache[:storage]
        g = similar(x)
        Jutul.AdjointsDI.solve_adjoint_generic!(
            g, x, setup_battmo_case, S, states, dt, objective,
        )
        # g = Jutul.AdjointsDI.solve_adjoint_generic(
        #     x, setup_battmo_case, states, dt, objective,
        #     use_sparsity = false,
        #     di_sparse = false,
        #     single_step_sparsity = false,
        #     do_prep = false
        # )
    else
        g = missing
    end
    return (f, g)
end



function vectorize_cell_parameters_for_calibration(vc, sim)
    pt = vc.parameter_targets
    pkeys = collect(keys(pt))
    if length(pkeys) == 0
        throw(ArgumentError("No free parameters set, unable to calibrate."))
    end
    # Set up the functions to serialize
    x0, x_setup = Jutul.AdjointsDI.vectorize_nested(sim.cell_parameters.all,
        active = pkeys,
        active_type = Real
    )
    return (x0, x_setup)
end

function setup_battmo_case_for_calibration(X, sim, x_setup, step_info = missing; stepix = missing)
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
    if !ismissing(stepix)
        timesteps = timesteps[stepix]
    end

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
                              case.parameters;
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


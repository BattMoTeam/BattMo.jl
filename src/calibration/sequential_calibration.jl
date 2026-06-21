export SequentialCalibrationParameter, SequentialParameterGroup
export sequential_parameter_catalog, create_clustered_parameter_groups
export evaluate_sequential_sensitivities, calibrate_sequential_group

"""
    SequentialCalibrationParameter

BattMo.jl representation of one short parameter name from the MATLAB
`ParamSetter`. A parameter may update one or more cell-parameter paths.
"""
struct SequentialCalibrationParameter
    shortname::String
    paths::Vector{Vector{String}}
    bounds::Tuple{Float64, Float64}
    scaling::Symbol
end

struct SequentialParameterGroup
    name::String
    parameters::Vector{String}
    mean_sensitivity::Float64
    priority::Int
end

function sequential_parameter_catalog()
    ne = "NegativeElectrode"
    pe = "PositiveElectrode"
    am = "ActiveMaterial"
    co = "Coating"

    return Dict(
        "ne_j0" => SequentialCalibrationParameter(
            "ne_j0", [[ne, am, "ReactionRateConstant"]], (1.0e-13, 1.0e-6), :log,
        ),
        "pe_j0" => SequentialCalibrationParameter(
            "pe_j0", [[pe, am, "ReactionRateConstant"]], (1.0e-13, 1.0e-9), :log,
        ),
        "ne_vsa" => SequentialCalibrationParameter(
            "ne_vsa", [[ne, am, "VolumetricSurfaceArea"]], (1.0e5, 1.0e7), :log,
        ),
        "pe_vsa" => SequentialCalibrationParameter(
            "pe_vsa", [[pe, am, "VolumetricSurfaceArea"]], (1.0e4, 1.0e10), :log,
        ),
        "ne_bg" => SequentialCalibrationParameter(
            "ne_bg", [[ne, co, "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
        "pe_bg" => SequentialCalibrationParameter(
            "pe_bg", [[pe, co, "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
        "ne_D" => SequentialCalibrationParameter(
            "ne_D", [[ne, am, "DiffusionCoefficient"]], (1.0e-15, 1.0e-9), :log,
        ),
        "pe_D" => SequentialCalibrationParameter(
            "pe_D", [[pe, am, "DiffusionCoefficient"]], (1.0e-15, 1.0e-8), :log,
        ),
        "elyte_bg" => SequentialCalibrationParameter(
            "elyte_bg", [["Electrolyte", "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
        "elyte_bg_ne" => SequentialCalibrationParameter(
            "elyte_bg_ne", [[ne, co, "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
        "elyte_bg_pe" => SequentialCalibrationParameter(
            "elyte_bg_pe", [[pe, co, "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
        "elyte_bg_sep" => SequentialCalibrationParameter(
            "elyte_bg_sep", [["Separator", "BruggemanCoefficient"]], (1.0e-10, 10.0), :linear,
        ),
    )
end

function select_sequential_parameters(shortnames)
    catalog = sequential_parameter_catalog()
    names = String.(shortnames)
    length(unique(names)) == length(names) ||
        throw(ArgumentError("The shortname list contains duplicates."))
    unknown = filter(name -> !haskey(catalog, name), names)
    isempty(unknown) ||
        throw(ArgumentError("Unknown sequential calibration parameters: $(join(unknown, ", "))."))
    parameters = [catalog[name] for name in names]
    selected_paths = Dict{String, String}()
    for parameter in parameters
        for path in parameter.paths
            path_key = join(path, "/")
            if haskey(selected_paths, path_key)
                other = selected_paths[path_key]
                throw(ArgumentError(
                    "Parameters $other and $(parameter.shortname) both update $(join(path, ".")).",
                ))
            end
            selected_paths[path_key] = parameter.shortname
        end
    end
    return parameters
end

function sequential_parameter_value(cell_parameters, parameter)
    values = [get_nested_json_value(cell_parameters, path) for path in parameter.paths]
    value0 = first(values)
    if !all(value -> isapprox(value, value0), values)
        throw(ArgumentError(
            "Tied parameter $(parameter.shortname) has inconsistent initial values: $values",
        ))
    end
    return value0
end

function set_sequential_parameter!(cell_parameters, parameter, value)
    for path in parameter.paths
        set_nested_json_value!(cell_parameters, path, value)
    end
    return cell_parameters
end

function scale_sequential_parameter(parameter, value)
    if parameter.scaling == :log
        return log10(value)
    elseif parameter.scaling == :linear
        return value
    end
    throw(ArgumentError("Unsupported scaling $(parameter.scaling) for $(parameter.shortname)."))
end

function unscale_sequential_parameter(parameter, value)
    if parameter.scaling == :log
        return 10.0^value
    elseif parameter.scaling == :linear
        return value
    end
    throw(ArgumentError("Unsupported scaling $(parameter.scaling) for $(parameter.shortname)."))
end

function setup_sequential_calibration_case(X, sim, parameters; stepix = missing)
    for (parameter, value) in zip(parameters, X)
        physical_value = unscale_sequential_parameter(parameter, value)
        set_sequential_parameter!(sim.cell_parameters, parameter, physical_value)
    end

    input = (
        model_settings = sim.model.settings,
        cell_parameters = sim.cell_parameters,
        cycling_protocol = sim.cycling_protocol,
        simulation_settings = sim.settings,
        initial_state = sim.initial_state,
        time_steps = sim.time_steps,
    )
    grids, couplings = setup_grids_and_couplings(sim.model, input)
    model, model_parameters = setup_model!(
        sim.model, input, grids, couplings; T = eltype(X),
    )
    state0 = setup_initial_state(input, model)
    forces = setup_forces(model.multimodel)
    timesteps = setup_timesteps(input)
    if !ismissing(stepix)
        timesteps = timesteps[stepix]
    end
    return Jutul.JutulCase(
        model.multimodel,
        timesteps,
        forces;
        parameters = model_parameters,
        state0,
        input_data = input,
    )
end

function setup_sequential_problem(sim, t, voltage, shortnames)
    parameters = select_sequential_parameters(shortnames)
    calibration = VoltageCalibration(t, voltage, sim)
    physical_x0 = Float64[
        sequential_parameter_value(calibration.sim.cell_parameters, p) for p in parameters
    ]
    physical_lower = [p.bounds[1] for p in parameters]
    physical_upper = [p.bounds[2] for p in parameters]
    for i in eachindex(physical_x0)
        physical_lower[i] <= physical_x0[i] <= physical_upper[i] || throw(ArgumentError(
            "Initial value $(physical_x0[i]) for $(parameters[i].shortname) is outside " *
                "the bounds [$(physical_lower[i]), $(physical_upper[i])].",
        ))
    end
    x0 = [scale_sequential_parameter(p, x) for (p, x) in zip(parameters, physical_x0)]
    lower = [scale_sequential_parameter(p, x) for (p, x) in zip(parameters, physical_lower)]
    upper = [scale_sequential_parameter(p, x) for (p, x) in zip(parameters, physical_upper)]
    objective = setup_calibration_objective(calibration)
    setup_case(X, step_info = missing) =
        setup_sequential_calibration_case(X, calibration.sim, parameters)
    return (; calibration, parameters, x0, lower, upper, objective, setup_case)
end

"""
    evaluate_sequential_sensitivities(sim, t, voltage, shortnames; kwargs...)

Evaluate the voltage objective and its adjoint gradient for the selected
short-name parameters at their current values.
"""
function evaluate_sequential_sensitivities(
        sim, t, voltage, shortnames;
        solver_settings = get_default_solver_settings(sim.model),
        validate_solver_settings = true,
        backend_arg = (
            use_sparsity = false,
            di_sparse = true,
            single_step_sparsity = false,
            do_prep = true,
        ),
    )
    problem = setup_sequential_problem(sim, t, voltage, shortnames)
    objective_value, physical_gradient = solve_and_differentiate_for_calibration(
        problem.x0,
        problem.setup_case,
        problem.calibration,
        problem.objective,
        solver_settings;
        backend_arg,
        validate_solver_settings,
    )
    gradient = physical_gradient .* (problem.upper .- problem.lower)
    return (;
        objective_value,
        gradient,
        physical_gradient,
        problem.x0,
        problem.lower,
        problem.upper,
    )
end

"""
    calibrate_sequential_group(sim, t, voltage, shortnames; kwargs...)

Optimize one sequential parameter group with Jutul's bounded BFGS solver.
"""
function calibrate_sequential_group(
        sim, t, voltage, shortnames;
        solver_settings = get_default_solver_settings(sim.model),
        validate_solver_settings = true,
        grad_tol = 1.0e-10,
        obj_change_tol = 1.0e-10,
        maxit = 100,
        print = 1,
        backend_arg = (
            use_sparsity = false,
            di_sparse = true,
            single_step_sparsity = false,
            do_prep = true,
        ),
    )
    problem = setup_sequential_problem(sim, t, voltage, shortnames)
    adjoint_cache = Dict()
    objective_gradient(x) = solve_and_differentiate_for_calibration(
        x,
        problem.setup_case,
        problem.calibration,
        problem.objective,
        solver_settings;
        adj_cache = adjoint_cache,
        backend_arg,
        validate_solver_settings,
    )
    value, x, history = Jutul.LBFGS.box_bfgs(
        copy(problem.x0),
        objective_gradient,
        problem.lower,
        problem.upper;
        maximize = false,
        grad_tol,
        obj_change_tol,
        max_it = maxit,
        print,
    )

    calibrated = deepcopy(sim.cell_parameters)
    for (parameter, parameter_value) in zip(problem.parameters, x)
        physical_value = unscale_sequential_parameter(parameter, parameter_value)
        set_sequential_parameter!(calibrated, parameter, physical_value)
    end
    return (; value, x, history, cell_parameters = calibrated, initial = problem.x0)
end

function sensitivity_groups(param_names, sensitivities, high_threshold, medium_threshold)
    abs_sensitivities = abs.(sensitivities)
    masks = (
        ("High_Sensitivity", abs_sensitivities .>= high_threshold),
        (
            "Medium_Sensitivity",
            (abs_sensitivities .>= medium_threshold) .&
                (abs_sensitivities .< high_threshold),
        ),
        ("Low_Sensitivity", abs_sensitivities .< medium_threshold),
    )
    groups = SequentialParameterGroup[]
    for (name, mask) in masks
        any(mask) || continue
        indices = findall(mask)
        sort!(indices; by = i -> abs_sensitivities[i], rev = true)
        priority = length(groups) + 1
        push!(groups, SequentialParameterGroup(
            name,
            param_names[indices],
            mean(abs_sensitivities[indices]),
            priority,
        ))
    end
    return groups
end

function magnitude_parameter_groups(param_names, sensitivities)
    abs_sensitivities = abs.(sensitivities)
    max_sensitivity = maximum(abs_sensitivities)
    if iszero(max_sensitivity)
        group_size = ceil(Int, length(param_names) / 3)
        groups = SequentialParameterGroup[]
        for (priority, indices) in enumerate(Iterators.partition(eachindex(param_names), group_size))
            selected = collect(indices)
            push!(groups, SequentialParameterGroup(
                "Group_$priority", param_names[selected], 0.0, priority,
            ))
        end
        return groups
    end
    return sensitivity_groups(
        param_names, sensitivities, 0.2 * max_sensitivity, 0.01 * max_sensitivity,
    )
end

function physical_parameter_groups(param_names, sensitivities)
    domains = (
        ("Electrode_Kinetics", ["ne_vsa", "pe_vsa", "ne_j0", "pe_j0"]),
        ("Electrode_Transport", ["ne_bg", "pe_bg"]),
        ("Electrolyte_Transport", ["elyte_bg", "elyte_bg_ne", "elyte_bg_pe", "elyte_bg_sep"]),
        ("Solid_Diffusion", ["ne_D", "pe_D"]),
    )
    abs_sensitivities = abs.(sensitivities)
    groups = SequentialParameterGroup[]
    grouped = Set{String}()
    for (name, domain_parameters) in domains
        indices = findall(parameter -> parameter in domain_parameters, param_names)
        isempty(indices) && continue
        union!(grouped, param_names[indices])
        push!(groups, SequentialParameterGroup(
            name, param_names[indices], mean(abs_sensitivities[indices]), 0,
        ))
    end
    indices = findall(parameter -> !(parameter in grouped), param_names)
    if !isempty(indices)
        push!(groups, SequentialParameterGroup(
            "Ungrouped", param_names[indices], mean(abs_sensitivities[indices]), 0,
        ))
    end
    sort!(groups; by = group -> group.mean_sensitivity, rev = true)
    return [
        SequentialParameterGroup(group.name, group.parameters, group.mean_sensitivity, i)
        for (i, group) in enumerate(groups)
    ]
end

function hybrid_parameter_groups(param_names, sensitivities)
    abs_sensitivities = abs.(sensitivities)
    sensitivity_ratio = maximum(abs_sensitivities) /
        (minimum(abs_sensitivities) + eps(Float64))
    if sensitivity_ratio > 1000
        log_sensitivities = log10.(abs_sensitivities .+ eps(Float64))
        high_threshold = 10.0^quantile(log_sensitivities, 0.7)
        medium_threshold = 10.0^quantile(log_sensitivities, 0.3)
    else
        high_threshold = quantile(abs_sensitivities, 0.7)
        medium_threshold = quantile(abs_sensitivities, 0.3)
    end
    return sensitivity_groups(
        param_names, sensitivities, high_threshold, medium_threshold,
    )
end

"""
    create_clustered_parameter_groups(param_names, sensitivities; strategy=:hybrid_adaptive)

Create sequential optimization groups using the strategies from the MATLAB
`createClusteredParameterGroups` helper.
"""
function create_clustered_parameter_groups(
        param_names, sensitivities;
        strategy = :hybrid_adaptive,
    )
    names = String.(param_names)
    length(names) == length(sensitivities) ||
        throw(ArgumentError("Parameter names and sensitivities must have equal length."))
    isempty(names) && return SequentialParameterGroup[]

    if strategy == :magnitude
        return magnitude_parameter_groups(names, sensitivities)
    elseif strategy == :physical
        return physical_parameter_groups(names, sensitivities)
    elseif strategy == :hybrid_adaptive
        return hybrid_parameter_groups(names, sensitivities)
    else
        throw(ArgumentError("Unknown grouping strategy: $strategy"))
    end
end

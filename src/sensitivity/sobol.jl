export AbstractSensitivityAnalysis, SobolSensitivity, SobolResult
export free_sensitivity_parameter!, freeze_sensitivity_parameter!, print_sensitivity_overview
export print_sobol_indices, compute_heat_generation, default_sobol_quantities

"""
    SobolResult

Result of `solve(sa::SobolSensitivity)`. Index matrices have one row per parameter (in the
order of `parameter_names`) and one column per quantity (in the order of `quantity_names`).

# Fields
- `parameter_names`: Parameter paths joined with `.`, sorted.
- `quantity_names`: Quantity names, sorted.
- `first_order`: First-order indices `S_i`: the variance fraction of a quantity explained by
  parameter `i` alone.
- `total_order`: Total-order indices `ST_i`: the variance fraction that involves parameter
  `i`, including its interactions with the other parameters.
- `first_order_ci`, `total_order_ci`: Bootstrap confidence intervals as
  `(lower, upper)` matrices, or `nothing` when `bootstrap = 0`.
- `samples`: Physical parameter values of all evaluated points, one row per simulation.
- `values`: Quantity values of all evaluated points, one row per simulation. Failed
  simulations are `NaN`.
- `N`: Number of base samples. The number of simulations is `N * (d + 2)`.
- `n_valid`: Number of base samples per quantity used by the estimators. A base sample is
  dropped when any of its `d + 2` simulations failed or returned a non-finite value.
"""
struct SobolResult
    parameter_names::Vector{String}
    quantity_names::Vector{String}
    first_order::Matrix{Float64}
    total_order::Matrix{Float64}
    first_order_ci::Union{Nothing, NTuple{2, Matrix{Float64}}}
    total_order_ci::Union{Nothing, NTuple{2, Matrix{Float64}}}
    samples::Matrix{Float64}
    values::Matrix{Float64}
    N::Int
    n_valid::Vector{Int}
end

function Base.show(io::IO, ::MIME"text/plain", result::SobolResult)
    println(io, "SobolResult with $(length(result.parameter_names)) parameters, ", "$(length(result.quantity_names)) quantities and N = $(result.N):")
    return print_sobol_indices(io, result)
end

"""
    AbstractSensitivityAnalysis

Abstract type for sensitivity analysis objects.
"""
abstract type AbstractSensitivityAnalysis end

"""
    mutable struct SobolSensitivity <: AbstractSensitivityAnalysis

Global sensitivity analysis of simulation quantities with Sobol indices. The workflow
follows the calibration API: create the object from a `Simulation`, free the parameters
to vary, and `solve` it.

# Fields
- `sim`: A deep copy of the `Simulation` object, so that the original simulation can be reused.
- `quantities`: Dictionary from quantity name to a function
  `f(output::SimulationOutput) -> Float64`. Add or remove entries to change the analysed
  quantities.
- `parameter_targets`: Dictionary from parameter path to a named tuple
  `(v0, vmin, vmax, scaling)` with the nominal value, the bounds and the sampling scaling.
- `result`: The `SobolResult` (once solved).

# Constructor

- `SobolSensitivity(sim; quantities = default_sobol_quantities())`

# Example
```julia
sim = Simulation(model, cell_parameters, cycling_protocol)
sa = SobolSensitivity(sim)
free_sensitivity_parameter!(sa, ["NegativeElectrode", "ActiveMaterial", "DiffusionCoefficient"];
    lower_bound = 1e-14, upper_bound = 1e-13, scaling = :log)
free_sensitivity_parameter!(sa, ["Electrolyte", "BruggemanCoefficient"];
    lower_bound = 1.3, upper_bound = 2.0)
print_sensitivity_overview(sa)
result = solve(sa; N = 64)
```
"""
mutable struct SobolSensitivity <: AbstractSensitivityAnalysis
    "The simulation object. This is a copy of the original simulation object, so that the original simulation can be reused."
    sim::Any
    "A dictionary from quantity name to a function of the `SimulationOutput`."
    quantities::Dict{String, Function}
    "A dictionary from parameter path to the nominal value, the bounds and the scaling."
    parameter_targets::Dict{Vector{String}, Any}
    "The Sobol indices (once solved)."
    result::Any
    function SobolSensitivity(sim::Simulation; quantities::AbstractDict = default_sobol_quantities())
        quantities = Dict{String, Function}(String(name) => f for (name, f) in quantities)
        return new(deepcopy(sim), quantities, Dict{Vector{String}, Any}(), missing)
    end
end

"""
    free_sensitivity_parameter!(sa::AbstractSensitivityAnalysis, parameter_name::Vector{String};
            lower_bound = missing,
            upper_bound = missing,
            scaling = :linear,
        )

Vary a parameter in the sensitivity analysis. The parameter is specified by
`parameter_name`, a vector of strings representing the nested structure of the parameter
in the simulation's cell parameters. The parameter is sampled uniformly between the bounds,
in `log10` space for `scaling = :log`.

# Notes
- The `lower_bound` and `upper_bound` must be provided and cannot be `missing`.
- The nominal value of the parameter must be within the bounds.
"""
function free_sensitivity_parameter!(
        sa::AbstractSensitivityAnalysis, parameter_name::Vector{String};
        lower_bound = missing,
        upper_bound = missing,
        scaling::Symbol = :linear,
    )
    if ismissing(lower_bound) || ismissing(upper_bound)
        throw(ArgumentError("$parameter_name: Bounds must be set for free parameters (defaults not implemented)"))
    end
    if lower_bound >= upper_bound
        throw(ArgumentError("Lower bound for $parameter_name $lower_bound must be less than upper bound $upper_bound"))
    end
    if !(scaling in (:linear, :log))
        throw(ArgumentError("Scaling for $parameter_name must be :linear or :log, got $scaling"))
    end
    if scaling == :log && lower_bound <= 0
        throw(ArgumentError("Log-scaled parameter $parameter_name requires a positive lower bound, got $lower_bound"))
    end
    initial_value = get_nested_json_value(sa.sim.cell_parameters, parameter_name)
    if !(initial_value isa Real)
        throw(ArgumentError("$parameter_name must be a scalar parameter, got $(typeof(initial_value))"))
    end
    if initial_value < lower_bound || initial_value > upper_bound
        throw(ArgumentError("Initial value for $parameter_name $initial_value out of bounds [$lower_bound, $upper_bound]"))
    end
    sa.parameter_targets[parameter_name] = (
        v0 = initial_value, vmin = Float64(lower_bound), vmax = Float64(upper_bound), scaling,
    )
    return sa
end

"""
    freeze_sensitivity_parameter!(sa::AbstractSensitivityAnalysis, parameter_name::Vector{String})

Remove a parameter from the sensitivity analysis. It keeps its nominal value.
"""
function freeze_sensitivity_parameter!(sa::AbstractSensitivityAnalysis, parameter_name::Vector{String})
    return delete!(sa.parameter_targets, parameter_name)
end

"""
    print_sensitivity_overview(sa::SobolSensitivity)

Print an overview of the parameters in the sensitivity analysis, with their nominal values,
bounds and scaling, and the analysed quantities. If the analysis has been solved, the Sobol
indices are printed as well, see `print_sobol_indices`.
"""
function print_sensitivity_overview(sa::SobolSensitivity)
    pt = sa.parameter_targets
    outer_keys = unique!(sort!([first(k) for k in keys(pt)]))
    for outer_key in outer_keys
        subkeys = sort!(filter(k -> first(k) == outer_key, collect(keys(pt))))
        tab = Matrix{Any}(undef, length(subkeys), 4)
        for (i, k) in enumerate(subkeys)
            tab[i, :] = [join(k[2:end], "."), pt[k].v0, "$(pt[k].vmin) - $(pt[k].vmax)", pt[k].scaling]
        end
        Jutul.PrettyTables.pretty_table(
            tab;
            column_labels = ["Name", "Initial value", "Bounds", "Scaling"],
            title = "$outer_key: Active sensitivity parameters",
            fit_table_in_display_horizontally = false,
            fit_table_in_display_vertically = false,
        )
    end
    println("Quantities: ", join(sort!(collect(keys(sa.quantities))), ", "))
    if !ismissing(sa.result)
        print_sobol_indices(sa.result)
    end
    return
end

###########################
# Quantities of interest  #
###########################

"""
    compute_heat_generation(output::SimulationOutput; method = :bernardi)

Compute the heat generated during a simulation. Return `(; time, rate, total)`, where
`rate` is the heat generation rate in W at the report times and `total` is the generated
heat in J. Only irreversible heat is included.

Methods:
- `:bernardi` (default): `rate = I * (U_ocv - V)`, where `U_ocv` is the cell open-circuit
  voltage at the volume-averaged particle concentration of each electrode. This is the total
  dissipated energy, including the energy left in concentration gradients, which is
  released as heat when the cell relaxes. It is cheap and works for every geometry.
- `:source_terms`: Sum of the ohmic, electrolyte diffusion and irreversible reaction heat
  sources, as used by the BattMo thermal model. Energy in concentration gradients within the
  particles is not included. This method evaluates all secondary variables at every report
  step and is much slower than solving the simulation.

The first interval, from time zero to the first report time, uses the rate at the first
report time.
"""
function compute_heat_generation(output::SimulationOutput; method::Symbol = :bernardi)
    states = output.jutul_output.states
    isempty(states) && throw(ArgumentError("The simulation output contains no states."))
    sim = output.simulation
    multimodel = output.model.multimodel
    time, current, voltage = report_series(output)

    if method == :bernardi
        ocv = [cell_average_open_circuit_voltage(multimodel, sim.parameters, state) for state in states]
        rate = current .* (ocv .- voltage)
    elseif method == :source_terms
        operators = setup_flux_operators(output.model)
        rate = [heat_source_rate(multimodel, sim.parameters, state, operators) for state in states]
    else
        throw(ArgumentError("Unknown heat generation method $method. Use :bernardi or :source_terms."))
    end
    return (; time, rate, total = integrate_report_series(time, rate))
end

# The rate at the first report time is used for the first interval from time zero.
function integrate_report_series(time, values)
    isempty(time) && return 0.0
    total = time[1] * values[1]
    for i in 2:lastindex(time)
        total += (time[i] - time[i - 1]) * (values[i] + values[i - 1]) / 2
    end
    return total
end

function electrode_average_concentration(multimodel, parameters, state, name::Symbol)
    system = multimodel[name].system
    weights = parameters[name][:Volume] .* parameters[name][:VolumeFraction]
    electrode_state = state[name]
    if haskey(electrode_state, :ParticleConcentration) && system.discretization isa P2Ddiscretization
        shell_volumes = system.discretization[:vols]
        concentrations = electrode_state[:ParticleConcentration]
        particle_average = vec(sum(shell_volumes .* concentrations; dims = 1)) ./ sum(shell_volumes)
    else
        particle_average = electrode_state[:SurfaceConcentration]
    end
    return sum(weights .* particle_average) / sum(weights)
end

function cell_average_open_circuit_voltage(multimodel, parameters, state)
    negative, positive = map((:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial)) do name
        concentration = electrode_average_concentration(multimodel, parameters, state, name)
        volumes = parameters[name][:Volume]
        temperature = sum(state[name][:Temperature] .* volumes) / sum(volumes)
        eval_ocp_from_system(multimodel[name].system, concentration, temperature)
    end
    return positive - negative
end

function heat_source_rate(multimodel, parameters, state, operators)
    full_state = get_state_with_secondary_variables(multimodel, state, parameters)
    rate = 0.0
    for (name, operator) in operators
        for source in values(get_energy_source_terms(multimodel[name], full_state[name], operator))
            rate += sum(source)
        end
    end
    for cross_term in multimodel.cross_terms
        if cross_term.cross_term isa ButlerVolmerActmatToElyteCT && cross_term.target_equation == :charge_conservation
            irreversible, _ = get_reaction_energy_source_terms(cross_term, multimodel, full_state)
            rate += sum(irreversible)
        end
    end
    return rate
end

"""
    default_sobol_quantities(; heat_method = :bernardi)

Return the default quantities of a `SobolSensitivity`, as a dictionary of functions
`f(output::SimulationOutput) -> Float64`:

- `"Energy"`: Energy throughput `∫ V |I| dt` in Wh. For a discharge, this is the delivered
  energy.
- `"Power"`: Average power in W: the energy throughput divided by the time with nonzero
  current.
- `"Heat"`: Generated irreversible heat in Wh, see `compute_heat_generation`.

The definitions assume a single charge or discharge. For cycling protocols, use your own
quantities, for example built from `get_output_metrics`.
"""
function default_sobol_quantities(; heat_method::Symbol = :bernardi)
    return Dict{String, Function}(
        "Energy" => output -> energy_throughput(output) / 3600,
        "Power" => average_power,
        "Heat" => output -> compute_heat_generation(output; method = heat_method).total / 3600,
    )
end

function report_series(output::SimulationOutput)
    states = output.jutul_output.states
    isempty(states) && throw(ArgumentError("The simulation output contains no states."))
    time = [state[:Control][:Controller].time for state in states]
    current = [state[:Control][:Current][1] for state in states]
    voltage = [state[:Control][:ElectricPotential][1] for state in states]
    return time, current, voltage
end

function energy_throughput(output::SimulationOutput)
    time, current, voltage = report_series(output)
    return integrate_report_series(time, voltage .* abs.(current))
end

function average_power(output::SimulationOutput)
    time, current, voltage = report_series(output)
    active = [abs(I) > 1.0e-12 for I in current]
    intervals = [first(time); diff(time)]
    active_time = sum(intervals[active])
    active_time > 0 || return NaN
    return integrate_report_series(time, voltage .* abs.(current)) / active_time
end

##################################
# Sampling and Sobol estimators  #
##################################

"""
Map a point of the unit cube to physical parameter values, uniformly between the bounds
in the scaled coordinates (`log10(p)` for `:log` and `p` for `:linear`).
"""
function unit_to_physical(targets, u)
    return map(targets, u) do target, x
        if target.scaling == :log
            lower, upper = log10(target.vmin), log10(target.vmax)
            10.0^(lower + x * (upper - lower))
        else
            target.vmin + x * (target.vmax - target.vmin)
        end
    end
end

"""
Return the `N * (d + 2)` Saltelli points for base matrices `A` and `B` of size `N × d`:
the rows of `A`, the rows of `B`, then for each parameter `i` the rows of `A` with
column `i` taken from `B`.
"""
function saltelli_points(A::AbstractMatrix, B::AbstractMatrix)
    size(A) == size(B) || throw(DimensionMismatch("A and B must have the same size."))
    N, d = size(A)
    points = Matrix{Float64}(undef, N * (d + 2), d)
    points[1:N, :] .= A
    points[(N + 1):(2N), :] .= B
    for i in 1:d
        rows = ((i + 1) * N + 1):((i + 2) * N)
        points[rows, :] .= A
        points[rows, i] .= B[:, i]
    end
    return points
end

function sobol_estimates(fA, fB, fAB)
    d = size(fAB, 2)
    variance = var(vcat(fA, fB))
    # Centering does not bias the estimators, but removes the large variance of the
    # first-order estimator for quantities with a large mean.
    fB_centered = fB .- mean(vcat(fA, fB))
    first_order = Vector{Float64}(undef, d)
    total_order = Vector{Float64}(undef, d)
    for i in 1:d
        fABi = @view fAB[:, i]
        # Saltelli et al. (2010) first-order and Jansen (1999) total-order estimators.
        first_order[i] = mean(fB_centered .* (fABi .- fA)) / variance
        total_order[i] = mean((fA .- fABi) .^ 2) / (2 * variance)
    end
    return first_order, total_order
end

"""
    estimate_sobol_indices(Y, N, d; bootstrap = 0, confidence = 0.95, rng)

Estimate first- and total-order Sobol indices from quantity values `Y` (one row per Saltelli
point, ordered as by `saltelli_points`, one column per quantity). Base samples with a
non-finite value in any of their points are dropped per quantity.
"""
function estimate_sobol_indices(
        Y::AbstractMatrix, N::Integer, d::Integer;
        bootstrap::Integer = 0, confidence = 0.95, rng = Random.default_rng(),
    )
    size(Y, 1) == N * (d + 2) || throw(DimensionMismatch("Y must have N * (d + 2) rows."))
    q = size(Y, 2)
    first_order = fill(NaN, d, q)
    total_order = fill(NaN, d, q)
    ci_first = bootstrap > 0 ? (fill(NaN, d, q), fill(NaN, d, q)) : nothing
    ci_total = bootstrap > 0 ? (fill(NaN, d, q), fill(NaN, d, q)) : nothing
    n_valid = zeros(Int, q)
    alpha = (1 - confidence) / 2

    for k in 1:q
        fA = Y[1:N, k]
        fB = Y[(N + 1):(2N), k]
        fAB = reshape(Y[(2N + 1):end, k], N, d)
        valid = [isfinite(fA[j]) && isfinite(fB[j]) && all(isfinite, @view fAB[j, :]) for j in 1:N]
        n_valid[k] = count(valid)
        fA, fB, fAB = fA[valid], fB[valid], fAB[valid, :]
        if n_valid[k] < 2 || var(vcat(fA, fB)) <= eps(Float64) * max(1.0, mean(abs.(vcat(fA, fB))))^2
            continue
        end
        first_order[:, k], total_order[:, k] = sobol_estimates(fA, fB, fAB)
        if bootstrap > 0
            boot_first = Matrix{Float64}(undef, bootstrap, d)
            boot_total = Matrix{Float64}(undef, bootstrap, d)
            n = n_valid[k]
            for b in 1:bootstrap
                idx = rand(rng, 1:n, n)
                boot_first[b, :], boot_total[b, :] = sobol_estimates(fA[idx], fB[idx], fAB[idx, :])
            end
            for i in 1:d
                for (ci, boot) in ((ci_first, boot_first), (ci_total, boot_total))
                    samples = filter(isfinite, @view boot[:, i])
                    isempty(samples) && continue
                    ci[1][i, k] = quantile(samples, alpha)
                    ci[2][i, k] = quantile(samples, 1 - alpha)
                end
            end
        end
    end
    return (; first_order, total_order, first_order_ci = ci_first, total_order_ci = ci_total, n_valid)
end

########################
# Solve                #
########################

function evaluate_sobol_point(model, sim, solver_settings, parameter_names, values, quantity_functions)
    cell = deepcopy(sim.cell_parameters)
    for (name, value) in zip(parameter_names, values)
        set_nested_json_value!(cell, name, value)
    end
    result = fill(NaN, length(quantity_functions))
    try
        output = Logging.with_logger(Logging.NullLogger()) do
            sample_sim = Simulation(
                model, cell, sim.cycling_protocol;
                simulation_settings = sim.settings, validate = false,
            )
            solve(sample_sim; solver_settings, info_level = -1)
        end
        for (k, f) in enumerate(quantity_functions)
            result[k] = try
                Float64(f(output))
            catch err
                err isa InterruptException && rethrow(err)
                NaN
            end
        end
    catch err
        err isa InterruptException && rethrow(err)
    end
    return result
end

"""
    solve(sa::SobolSensitivity; N = 64, kwargs...) -> SobolResult

Compute first- and total-order Sobol indices of the quantities of `sa` with respect to its
free parameters, using the Saltelli sampling scheme. The parameters are sampled
independently and uniformly between their bounds, in `log10` space for `:log` scaling.
This requires `N * (d + 2)` simulations for `d` parameters. The result is also stored in
`sa.result`.

# Keyword Arguments
- `N = 64`: Number of base samples. Use a power of two with a quasi-random `sampler`.
- `solver_settings`: Solver settings for every simulation.
- `bootstrap = 100`, `confidence = 0.95`: Number of bootstrap resamples and the level of
  the confidence intervals. Set `bootstrap = 0` to skip the intervals.
- `rng = Random.default_rng()`: Random number generator for sampling and bootstrapping.
- `sampler = nothing`: Optional function `(N, d, rng) -> (A, B)` that returns two
  independent `N × d` matrices in the unit cube, for example from a Sobol sequence. By
  default, `A` and `B` are uniform random samples.
- `parallel = Threads.nthreads() > 1`: Run the simulations on all Julia threads.
- `info_level = 0`: Print progress when `info_level >= 0`.

Simulations that fail return `NaN` for every quantity. Their base samples are dropped from
the estimators, see `SobolResult`.

# Example
```julia
result = solve(sa; N = 128)
```
"""
function solve(
        sa::SobolSensitivity;
        N::Integer = 64,
        solver_settings = get_default_solver_settings(sa.sim.model),
        bootstrap::Integer = 100,
        confidence = 0.95,
        rng = Random.default_rng(),
        sampler = nothing,
        parallel::Bool = Threads.nthreads() > 1,
        info_level::Integer = 0,
    )
    N >= 2 || throw(ArgumentError("N must be at least 2."))
    isempty(sa.parameter_targets) && throw(ArgumentError("No free parameters set, unable to compute sensitivities."))
    isempty(sa.quantities) && throw(ArgumentError("No quantities set, unable to compute sensitivities."))
    sim = sa.sim
    parameter_names = sort!(collect(keys(sa.parameter_targets)); by = name -> join(name, "."))
    targets = [sa.parameter_targets[name] for name in parameter_names]
    d = length(parameter_names)
    quantity_names = sort!(collect(keys(sa.quantities)))
    quantity_functions = [sa.quantities[name] for name in quantity_names]

    A, B = isnothing(sampler) ? (rand(rng, N, d), rand(rng, N, d)) : sampler(N, d, rng)
    size(A) == (N, d) && size(B) == (N, d) ||
        throw(DimensionMismatch("The sampler must return two $N × $d matrices."))
    all(x -> 0 <= x <= 1, A) && all(x -> 0 <= x <= 1, B) ||
        throw(ArgumentError("The sampler must return values in the unit interval."))
    unit_points = saltelli_points(A, B)
    npoints = size(unit_points, 1)
    samples = Matrix{Float64}(undef, npoints, d)
    for j in 1:npoints
        samples[j, :] = unit_to_physical(targets, unit_points[j, :])
    end

    quantity_values = fill(NaN, npoints, length(quantity_functions))
    completed = Threads.Atomic{Int}(0)
    report_every = max(1, npoints ÷ 20)
    if info_level >= 0
        jutul_message("Sensitivity", "Starting Sobol analysis of $d parameters with $npoints simulations.", color = :green)
    end

    function run_chunk(indices, chunk_model)
        for j in indices
            quantity_values[j, :] = evaluate_sobol_point(
                chunk_model, sim, solver_settings, parameter_names, samples[j, :], quantity_functions,
            )
            n = Threads.atomic_add!(completed, 1) + 1
            if info_level >= 0 && (n % report_every == 0 || n == npoints)
                println("Sobol analysis: $n / $npoints simulations completed.")
            end
        end
        return nothing
    end

    t_sa = @elapsed if parallel && Threads.nthreads() > 1
        chunks = Iterators.partition(1:npoints, cld(npoints, Threads.nthreads()))
        # Each task sets up its own model, since simulation setup updates the model.
        tasks = [Threads.@spawn run_chunk(chunk, deepcopy(sim.model)) for chunk in chunks]
        foreach(fetch, tasks)
    else
        run_chunk(1:npoints, deepcopy(sim.model))
    end
    if info_level >= 0
        jutul_message("Sensitivity", "Sobol analysis finished in $t_sa seconds.", color = :green)
    end

    n_failed = count(j -> !all(isfinite, @view quantity_values[j, :]), 1:npoints)
    if n_failed > 0
        @warn "$n_failed of $npoints simulations failed or returned non-finite quantities. Their base samples are dropped."
    end

    estimates = estimate_sobol_indices(quantity_values, N, d; bootstrap, confidence, rng)
    for (k, name) in enumerate(quantity_names)
        if all(isnan, @view estimates.first_order[:, k])
            @warn "Sobol indices of $name could not be estimated: too few valid samples or zero variance."
        end
    end

    sa.result = SobolResult(
        [join(name, ".") for name in parameter_names],
        quantity_names,
        estimates.first_order,
        estimates.total_order,
        estimates.first_order_ci,
        estimates.total_order_ci,
        samples,
        quantity_values,
        N,
        estimates.n_valid,
    )
    return sa.result
end

"""
    print_sobol_indices(result::SobolResult)

Print a table of the first- and total-order indices per quantity, with the bootstrap
confidence intervals when available.
"""
print_sobol_indices(result::SobolResult) = print_sobol_indices(stdout, result)

function print_sobol_indices(io::IO, result::SobolResult)
    has_ci = !isnothing(result.first_order_ci)
    fmt(x) = isfinite(x) ? string(round(x; digits = 3)) : "NaN"
    for (k, quantity) in enumerate(result.quantity_names)
        header = has_ci ? ["Parameter", "S1", "S1 interval", "ST", "ST interval"] : ["Parameter", "S1", "ST"]
        order = sortperm(result.total_order[:, k]; by = x -> isfinite(x) ? -x : Inf)
        table = Matrix{Any}(undef, length(order), length(header))
        for (row, i) in enumerate(order)
            S1 = result.first_order[i, k]
            ST = result.total_order[i, k]
            if has_ci
                lo1, hi1 = result.first_order_ci[1][i, k], result.first_order_ci[2][i, k]
                loT, hiT = result.total_order_ci[1][i, k], result.total_order_ci[2][i, k]
                table[row, :] = [
                    result.parameter_names[i], fmt(S1), "[$(fmt(lo1)), $(fmt(hi1))]",
                    fmt(ST), "[$(fmt(loT)), $(fmt(hiT))]",
                ]
            else
                table[row, :] = [result.parameter_names[i], fmt(S1), fmt(ST)]
            end
        end
        Jutul.PrettyTables.pretty_table(
            io, table;
            column_labels = header,
            title = "Sobol indices of $quantity ($(result.n_valid[k]) of $(result.N) base samples)",
            alignment = :l,
            fit_table_in_display_horizontally = false,
            fit_table_in_display_vertically = false,
        )
    end
    return nothing
end

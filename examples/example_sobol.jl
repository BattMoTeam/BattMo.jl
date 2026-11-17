# # Global sensitivity analysis with Sobol indices
# This example computes Sobol indices of the delivered energy, the average power
# and the generated heat of a discharge with respect to transport and kinetic
# parameters of the Chen 2020 cell, and compares two ways of estimating them.
#
# Sobol indices split the variance of a quantity over the parameters, when the
# parameters vary independently within their bounds:
#
# - The first-order index `S1` is the variance fraction explained by one parameter alone.
# - The total-order index `ST` also includes the interactions of the parameter with the
#   others. A parameter with a small `ST` can be fixed without changing the quantity.
#
# BattMo offers two estimation methods:
#
# - `:saltelli` (default): Monte Carlo estimators on the Saltelli sampling scheme,
#   which require `N * (d + 2)` simulations for `d` parameters and `N` base samples.
#   They make no assumption on the quantities.
# - `:pce`: a polynomial chaos expansion (PCE), a polynomial surrogate fitted to the
#   simulations, from which the indices follow analytically. It needs far fewer
#   simulations when the quantities depend smoothly on the parameters.
#
# The workflow follows the calibration API: create a `SobolSensitivity` from a
# `Simulation`, free the parameters to vary, and `solve` it.

# ## Set up the base case
using BattMo
using Random
using GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_protocol["DRate"] = 1.0
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)

# ## Set up the sensitivity analysis
# A parameter is specified by its path in the cell parameters and its bounds.
# Parameters that span several decades are sampled uniformly in `log10` space
# with `scaling = :log`.

sa = SobolSensitivity(sim)

for electrode in ["NegativeElectrode", "PositiveElectrode"]
    D = cell_parameters[electrode]["ActiveMaterial"]["DiffusionCoefficient"]
    k0 = cell_parameters[electrode]["ActiveMaterial"]["ReactionRateConstant"]
    free_sensitivity_parameter!(
        sa, [electrode, "ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = D / 3, upper_bound = 3 * D, scaling = :log,
    )
    free_sensitivity_parameter!(
        sa, [electrode, "ActiveMaterial", "ReactionRateConstant"];
        lower_bound = k0 / 10, upper_bound = 10 * k0, scaling = :log,
    )
end

# The Bruggeman coefficient controls the effective electrolyte transport. For
# large values, the discharge becomes limited by electrolyte depletion, and the
# end of the discharge varies erratically from one parameter set to the next.
# Such non-smooth behaviour adds variance that neither method can attribute to
# a parameter in a meaningful way, so we keep the bounds below that regime.

free_sensitivity_parameter!(
    sa, ["Electrolyte", "BruggemanCoefficient"];
    lower_bound = 1.3, upper_bound = 1.6,
)

# The default quantities are the energy throughput (Wh), the average power (W)
# and the generated irreversible heat (Wh), see `default_sobol_quantities`.
# Any function of the `SimulationOutput` can be added. Here we add the peak heat
# generation rate in W, computed with `compute_heat_generation`.

sa.quantities["PeakHeatRate"] = output -> maximum(compute_heat_generation(output).rate)

print_sensitivity_overview(sa)

# ## Estimate the computational cost
# Timing one simulation of the base case gives an estimate of the total time
# before committing to a large study. The first run includes compilation, so we
# time the second one. The estimates are for a serial run. Samples near the
# parameter bounds can need more time steps, and running on several threads
# shortens the total, but by much less than the number of threads.
#
# The Saltelli scheme with `N` base samples needs `N * (d + 2)` simulations. A
# PCE of total degree `p` has `binomial(d + p, p)` basis polynomials, and by
# default twice as many simulations are used to fit it.

N = 32
degree = 3
d = length(sa.parameter_targets)
n_saltelli = N * (d + 2)
n_pce = 2 * binomial(d + degree, degree)

format_time(t) = t < 120 ? "$(round(t; digits = 1)) s" : "$(round(t / 60; digits = 1)) min"

solve(sim; info_level = -1)
time_single = @elapsed solve(sim; info_level = -1)

println("One simulation: $(format_time(time_single))")
println("Saltelli:       $n_saltelli simulations, about $(format_time(n_saltelli * time_single)) serial")
println("PCE:            $n_pce simulations, about $(format_time(n_pce * time_single)) serial")

# ## Compute the Sobol indices with the Saltelli scheme
# Start Julia with several threads (`julia -t auto`) to run the simulations in
# parallel. Use a larger `N` for a production study: the bootstrap intervals
# show whether the estimates have converged.

time_saltelli = @elapsed result = solve(sa; N, rng = Random.Xoshiro(42))
println("Saltelli: $(format_time(time_saltelli)) on $(Threads.nthreads()) thread(s)")

print_sobol_indices(result)

# ## Plot the indices
# Each panel shows the total-order (ST) and first-order (S1) indices of one
# quantity, with their bootstrap confidence intervals. The parameters keep the
# same order in all panels, with the largest total-order indices at the top.
# With few samples, the estimates can fall slightly outside [0, 1].

function parameter_label(name)
    parts = split(name, ".")
    owner = Dict("NegativeElectrode" => "NE", "PositiveElectrode" => "PE")
    field = replace(parts[end], r"(?<=[a-z])(?=[A-Z])" => " ")
    return "$(get(owner, parts[1], parts[1])) $field"
end

units = Dict("Energy" => "Wh", "Power" => "W", "Heat" => "Wh", "PeakHeatRate" => "W")
quantity_label(name) = haskey(units, name) ? "$name / $(units[name])" : name

labels = parameter_label.(result.parameter_names)
q = length(result.quantity_names)
order = sortperm(vec(sum(result.total_order; dims = 2)))
color_ST = "#2a78d6"
color_S1 = "#eb6834"

fig = Figure(size = (1000, 640))
for (k, quantity) in enumerate(result.quantity_names)
    row, col = fldmod1(k, 2)
    ax = Axis(
        fig[row, col];
        title = quantity,
        xlabel = row == cld(q, 2) ? "Sobol index" : "",
        yticks = (1:d, labels[order]),
        ygridvisible = false,
        xgridcolor = (:black, 0.08),
    )
    col > 1 && hideydecorations!(ax)
    bars = (
        (0.19, result.total_order, result.total_order_ci, color_ST),
        (-0.19, result.first_order, result.first_order_ci, color_S1),
    )
    for (offset, index, ci, color) in bars
        y = (1:d) .+ offset
        barplot!(ax, y, index[order, k]; direction = :x, width = 0.36, color)
        rangebars!(
            ax, y, ci[1][order, k], ci[2][order, k];
            direction = :x, color = (:black, 0.55), linewidth = 1.5, whiskerwidth = 6,
        )
    end
    vlines!(ax, 0; color = :black, linewidth = 1)
end
Legend(
    fig[cld(q, 2) + 1, :],
    [PolyElement(color = color_ST), PolyElement(color = color_S1)],
    ["Total order ST (with interactions)", "First order S1 (alone)"];
    orientation = :horizontal, framevisible = false,
)
Label(fig[0, :], "Sobol indices (Saltelli), N = $(result.N)"; fontsize = 18, font = :bold)
display(GLMakie.Screen(), fig) # hide
fig # hide

# ## Compute the Sobol indices with a polynomial chaos expansion
# With `method = :pce`, the parameters are sampled on a Latin hypercube, and a
# polynomial of total degree `degree` in the (scaled) parameters is fitted to
# the simulated quantities by least squares. The polynomials are orthonormal for
# the uniform distribution of the parameters, so the variance of the surrogate
# splits exactly over its coefficients, and the Sobol indices are sums of
# squared coefficients.
#
# The accuracy of the surrogate is measured by the leave-one-out coefficient of
# determination `Q²`, printed in the table titles: the fraction of the variance
# that the PCE predicts at each simulation when that simulation is left out of
# the fit. Values close to one mean the surrogate, and therefore its indices,
# can be trusted. A warning is printed below `Q² = 0.9`; then increase the
# degree or the number of simulations.

sa_pce = deepcopy(sa)
time_pce = @elapsed result_pce = solve(sa_pce; method = :pce, degree, rng = Random.Xoshiro(42))
println("PCE: $(format_time(time_pce)) on $(Threads.nthreads()) thread(s)")

print_sobol_indices(result_pce)

# ## Compare the two methods
# The table summarises the cost of both methods and the accuracy of the PCE.

println(rpad("Method", 10), rpad("Simulations", 13), rpad("Time", 10), "Q² (", join(result_pce.quantity_names, ", "), ")")
println(rpad("Saltelli", 10), rpad(size(result.samples, 1), 13), rpad(format_time(time_saltelli), 10), "-")
println(
    rpad("PCE", 10), rpad(size(result_pce.samples, 1), 13), rpad(format_time(time_pce), 10),
    join(round.(result_pce.pce.q2; digits = 4), ", "),
)

# Each panel shows one index of one quantity for both methods, with the
# bootstrap confidence intervals as whiskers. The parameters are ordered as
# above. Where the intervals overlap, the methods agree within their sampling
# error. The PCE intervals are typically narrower with fewer simulations, since
# the surrogate exploits the smoothness of the quantities, while the Saltelli
# estimates converge slowly, with an error proportional to `1 / sqrt(N)`.

@assert result_pce.parameter_names == result.parameter_names
@assert result_pce.quantity_names == result.quantity_names
color_saltelli = "#2a78d6"
color_pce = "#eb6834"
methods = (
    (0.14, result, color_saltelli, :circle, "Saltelli ($(size(result.samples, 1)) simulations)"),
    (-0.14, result_pce, color_pce, :diamond, "PCE degree $degree ($(size(result_pce.samples, 1)) simulations)"),
)
indices = (
    ("Total order ST", r -> r.total_order, r -> r.total_order_ci),
    ("First order S1", r -> r.first_order, r -> r.first_order_ci),
)

fig_compare = Figure(size = (1100, 620))
compare_axes = Matrix{Axis}(undef, length(indices), q)
for (row, (index_label, index, ci)) in enumerate(indices), (k, quantity) in enumerate(result.quantity_names)
    ax = compare_axes[row, k] = Axis(
        fig_compare[row, k];
        title = row == 1 ? quantity : "",
        ylabel = k == 1 ? index_label : "",
        xlabel = row == length(indices) ? "Sobol index" : "",
        yticks = (1:d, labels[order]),
        ygridvisible = false,
        xgridcolor = (:black, 0.08),
    )
    k > 1 && hideydecorations!(ax; label = false)
    vlines!(ax, 0; color = :black, linewidth = 1)
    for (offset, r, color, marker, _) in methods
        y = (1:d) .+ offset
        lower, upper = ci(r)
        rangebars!(
            ax, y, lower[order, k], upper[order, k];
            direction = :x, color, linewidth = 2, whiskerwidth = 6,
        )
        scatter!(
            ax, index(r)[order, k], y;
            color, marker, markersize = 11, strokecolor = :white, strokewidth = 1.5,
        )
    end
end
linkxaxes!(compare_axes...)
Legend(
    fig_compare[length(indices) + 1, :],
    [MarkerElement(; color, marker, markersize = 11) for (_, _, color, marker, _) in methods],
    [label for (_, _, _, _, label) in methods];
    orientation = :horizontal, framevisible = false,
)
Label(fig_compare[0, :], "Saltelli and PCE estimates of the Sobol indices"; fontsize = 18, font = :bold)
display(GLMakie.Screen(), fig_compare) # hide
fig_compare # hide

# For the energy, the heat and the power, `Q²` is close to one, and the PCE
# estimates agree with the Saltelli estimates, with much narrower intervals
# from half the simulations. The peak heat generation rate is a maximum over
# time: when a parameter moves the time of the peak from one part of the
# discharge to another, the peak changes non-smoothly. A polynomial cannot
# follow this, `Q²` is low and a warning is printed, and the PCE indices of this
# quantity differ from the Saltelli indices. Here, the Saltelli estimates should
# be used, with a larger `N`.
#
# Which method to use? The PCE is the better choice when each simulation is
# expensive and the quantities are smooth functions of the parameters, which is
# typical for integral quantities such as energy and heat; always check `Q²`.
# The Saltelli scheme needs more simulations but no smoothness, so it is the
# safer choice for quantities with kinks or jumps, for example when a parameter
# change makes the discharge stop at a different cut-off condition.

# ## Scatter plots of the samples
# The indices show how much each parameter matters, the scatter plots show how.
# Every simulation of the Saltelli analysis is a point, and every column spans
# the bounds of one parameter. A clear trend in a column means a large
# first-order effect; the spread around the trend comes from the other
# parameters.

targets = [sa.parameter_targets[String.(split(name, "."))] for name in result.parameter_names]
is_log = [target.scaling == :log for target in targets]

# Three ticks inside the bounds, so that the labels of neighbouring panels do not collide.
function bound_ticks(target)
    scale, unscale = target.scaling == :log ? (log10, exp10) : (identity, identity)
    lower, upper = scale(target.vmin), scale(target.vmax)
    ticks = round.(unscale.(lower .+ [0.1, 0.5, 0.9] .* (upper - lower)); sigdigits = 2)
    return (ticks, string.(ticks))
end

fig_scatter = Figure(size = (220 * d, 190 * q))
columns = reverse(order)
axes = [
    Axis(
            fig_scatter[k, j];
            xscale = is_log[i] ? log10 : identity,
            xticks = bound_ticks(targets[i]),
            limits = ((targets[i].vmin, targets[i].vmax), nothing),
            xlabel = labels[i],
            ylabel = quantity_label(quantity),
            xgridcolor = (:black, 0.08),
            ygridcolor = (:black, 0.08),
        )
        for (k, quantity) in enumerate(result.quantity_names), (j, i) in enumerate(columns)
]
for (k, quantity) in enumerate(result.quantity_names), (j, i) in enumerate(columns)
    ax = axes[k, j]
    scatter!(ax, result.samples[:, i], result.values[:, k]; color = (color_ST, 0.45), markersize = 6)
    k < q && hidexdecorations!(ax; grid = false)
    j > 1 && hideydecorations!(ax; grid = false)
end
foreach(row -> linkyaxes!(row...), eachrow(axes))
foreach(column -> linkxaxes!(column...), eachcol(axes))
display(GLMakie.Screen(), fig_scatter) # hide
fig_scatter # hide

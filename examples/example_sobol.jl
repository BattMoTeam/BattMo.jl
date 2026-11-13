# # Global sensitivity analysis with Sobol indices
# This example computes Sobol indices of the delivered energy, the average power
# and the generated heat of a discharge with respect to transport and kinetic
# parameters of the Chen 2020 cell.
#
# Sobol indices split the variance of a quantity over the parameters, when the
# parameters vary independently within their bounds:
#
# - The first-order index `S1` is the variance fraction explained by one parameter alone.
# - The total-order index `ST` also includes the interactions of the parameter with the
#   others. A parameter with a small `ST` can be fixed without changing the quantity.
#
# The indices are estimated with the Saltelli sampling scheme, which requires
# `N * (d + 2)` simulations for `d` parameters and `N` base samples. The workflow
# follows the calibration API: create a `SobolSensitivity` from a `Simulation`,
# free the parameters to vary, and `solve` it.

# ## Set up the base case
using BattMo
using Random
using GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_protocol["DRate"] = 2.0
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
free_sensitivity_parameter!(
    sa, ["Electrolyte", "BruggemanCoefficient"];
    lower_bound = 1.3, upper_bound = 2.0,
)

# The default quantities are the energy throughput (Wh), the average power (W)
# and the generated irreversible heat (Wh), see `default_sobol_quantities`.
# Any function of the `SimulationOutput` can be added. Here we add the peak heat
# generation rate in W, computed with `compute_heat_generation`.

sa.quantities["PeakHeatRate"] = output -> maximum(compute_heat_generation(output).rate)

print_sensitivity_overview(sa)

# ## Estimate the computational cost
# The analysis runs `N * (d + 2)` simulations. Timing one simulation of the base
# case gives an estimate of the total time before committing to a large `N`.
# The first run includes compilation, so we time the second one. The estimate is
# for a serial run. Samples near the parameter bounds can need more time steps,
# and running on several threads shortens the total, but by much less than the
# number of threads, so measure the speed-up on your machine (printed below).

N = 32
d = length(sa.parameter_targets)
n_simulations = N * (d + 2)

format_time(t) = t < 120 ? "$(round(t; digits = 1)) s" : "$(round(t / 60; digits = 1)) min"

solve(sim; info_level = -1)
time_single = @elapsed solve(sim; info_level = -1)
time_estimate = n_simulations * time_single

println("One simulation:        $(format_time(time_single))")
println("Number of simulations: $n_simulations")
println("Estimated serial time: $(format_time(time_estimate))")

# ## Compute the Sobol indices
# Start Julia with several threads (`julia -t auto`) to run the simulations in
# parallel. Use a larger `N` for a production study: the bootstrap intervals
# show whether the estimates have converged.

time_start = time()
result = solve(sa; N, rng = Random.Xoshiro(42))
time_sobol = time() - time_start

println("Total time:            $(format_time(time_sobol)) on $(Threads.nthreads()) thread(s)")
println("Speed-up over serial:  $(round(time_estimate / time_sobol; digits = 1))x (estimated)")

print_sensitivity_overview(sa)

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
d = length(labels)
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
Label(fig[0, :], "Sobol indices, N = $(result.N)"; fontsize = 18, font = :bold)
display(GLMakie.Screen(), fig) # hide
fig # hide

# ## Scatter plots of the samples
# The indices show how much each parameter matters, the scatter plots show how.
# Every simulation is a point, and every column spans the bounds of one
# parameter. A clear trend in a column means a large first-order effect; the
# spread around the trend comes from the other parameters.

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

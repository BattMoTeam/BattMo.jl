using CSV, DataFrames, GLMakie, Statistics

battmo_df = CSV.read(joinpath("results", "battmo_benchmark_times.csv"), DataFrame)
pybamm_df = CSV.read(joinpath("results", "pybamm_benchmark_times.csv"), DataFrame)

groups = vcat(
    [(label = g.tool[1], times = g.solve_time_s) for g in groupby(battmo_df, :tool)],
    [(label = pybamm_df.tool[1], times = pybamm_df.solve_time_s)],
)

println("Solve-time comparison (1C discharge, Chen 2020, target cutoff 2.5 V):")
for g in groups
    println(rpad(g.label, 32), "mean=$(round(mean(g.times), digits=4)) s  min=$(round(minimum(g.times), digits=4)) s  std=$(round(std(g.times), digits=4)) s")
end

println()
println("Accuracy of the voltage-cutoff detection (BattMo.jl only, see caveat in battmo_benchmark.jl):")
for g in groupby(battmo_df, :tool)
    println(rpad(g.tool[1], 32), "report_steps=$(g.report_steps[1])  t_final=$(round(g.t_final_s[1], digits=1)) s  v_final=$(round(g.v_final_V[1], digits=4)) V")
end

labels = [g.label for g in groups]
means = [mean(g.times) for g in groups]
stds = [std(g.times) for g in groups]
xs = 1:length(groups)

fig = Figure(size = (800, 500))
ax = Axis(
    fig[1, 1],
    ylabel = "Solve time (s)",
    xticks = (xs, labels),
    xticklabelrotation = pi / 8,
    title = "1C Discharge Solve Time: BattMo.jl vs PyBaMM (Chen 2020)",
)

barplot!(ax, xs, means, color = [:red, :orange, :blue])
errorbars!(ax, xs, means, stds, whiskerwidth = 20)

save(joinpath("results", "benchmark_comparison.png"), fig)
println()
println("Saved results/benchmark_comparison.png")

fig

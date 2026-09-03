using BattMo
using DataFrames, CSV, Statistics

# -----------------------------
# BattMo.jl model and parameters (Chen 2020, 1C discharge to 2.5 V)
# Same physical setup as battmo_chen.jl
# -----------------------------
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

cycling_protocol["DRate"] = 1.0
cycling_protocol["LowerVoltageLimit"] = 2.5

model = LithiumIonBattery()

# -----------------------------
# Two variants:
#   "default" - BattMo.jl's out-of-the-box p2d simulation_settings (TimeStepDuration = 50 s,
#               ~84 fixed report steps, matching the earlier accuracy comparison exactly).
#   "adapted" - Coarser TimeStepDuration = 100 s (~44 report steps), explored because PyBaMM's
#               adaptive DAE solver takes far fewer effective solves than BattMo.jl's fixed
#               report-step schedule (which does a full Newton solve at every report step).
#
# Caveat (found during exploration, see battmo_stepping_explore.jl): BattMo.jl's CC protocol
# only checks the voltage cutoff AT report-step boundaries, it does not do event/root-finding
# like PyBaMM's IDA solver. So coarsening TimeStepDuration doesn't just speed things up, it also
# makes the detected cutoff voltage/time drift further from the true 2.5 V cutoff:
#   dt=50s  -> stops at ~2.526 V, t=3448 s (small ~0.03 V discretization error)
#   dt=100s -> stops at ~2.701 V, t=3397 s (~0.20 V error - a real accuracy cost, not noise)
# Both variants are run and saved here so this tradeoff is visible rather than hidden.
# -----------------------------
variants = [
    (label = "BattMo.jl (default dt=50s)", dt = 50, ramp_steps = 5),
    (label = "BattMo.jl (adapted dt=100s)", dt = 100, ramp_steps = 5),
]

const N_WARMUP = 1
const N_REPS = 5

mkpath("results")
all_rows = DataFrame()

for variant in variants
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = variant.dt
    simulation_settings["RampUpSteps"] = variant.ramp_steps

    sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings = simulation_settings)

    println("=== $(variant.label) ===")

    warmup_times = Float64[]
    for i in 1:N_WARMUP
        t0 = time()
        solve(sim; info_level = -1)
        t1 = time()
        push!(warmup_times, t1 - t0)
        println("warmup $i/$N_WARMUP (includes JIT compilation): $(round(warmup_times[end], digits = 4)) s")
    end

    times = Float64[]
    local output
    for i in 1:N_REPS
        t0 = time()
        output = solve(sim; info_level = -1)
        t1 = time()
        push!(times, t1 - t0)
        println("rep $i/$N_REPS: $(round(times[end], digits = 4)) s")
    end

    t = output.time_series["Time"]
    v = output.time_series["Voltage"]

    df = DataFrame(rep = 1:N_REPS, solve_time_s = times)
    df.tool .= variant.label
    df.battmo_version .= string(pkgversion(BattMo))
    df.time_step_duration_s .= variant.dt
    df.report_steps .= length(sim.time_steps)
    df.t_final_s .= t[end]
    df.v_final_V .= v[end]
    global all_rows = vcat(all_rows, df)

    println("warmup (compile+solve): $(round(warmup_times[1], digits = 4)) s")
    println("mean: $(round(mean(times), digits = 4)) s")
    println("min:  $(round(minimum(times), digits = 4)) s")
    println("std:  $(round(std(times), digits = 4)) s")
    println("report_steps: $(length(sim.time_steps))  t_final: $(round(t[end], digits = 1)) s  v_final: $(round(v[end], digits = 4)) V")
    println()
end

output_path = joinpath("results", "battmo_benchmark_times.csv")
CSV.write(output_path, all_rows)
println("Saved $output_path")

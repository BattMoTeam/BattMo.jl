using BattMo
using DataFrames, CSV, Statistics

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_protocol["DRate"] = 1.0
cycling_protocol["LowerVoltageLimit"] = 2.5

model = LithiumIonBattery()

function build_and_solve(; dt = 50, ramp_steps = 5)
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = dt
    simulation_settings["RampUpSteps"] = ramp_steps
    sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings = simulation_settings)
    return solve(sim; info_level = -1)
end

# -----------------------------
# Benchmark: time the FULL build+solve pipeline (fresh Simulation each rep),
# already-compiled/warm process (package already loaded, Simulation()/solve()
# already JIT-compiled by the warmup rep). Mirrors pybamm_full_benchmark.py.
# -----------------------------
const N_WARMUP = 1
const N_REPS = 5

variants = [
    (label = "BattMo.jl build+solve (default dt=50s)", dt = 50),
    (label = "BattMo.jl build+solve (adapted dt=100s)", dt = 100),
]

mkpath("results")
all_rows = DataFrame()

for variant in variants
    println("=== $(variant.label) ===")

    for _ in 1:N_WARMUP
        build_and_solve(; dt = variant.dt)
    end

    times = Float64[]
    for i in 1:N_REPS
        t0 = time()
        build_and_solve(; dt = variant.dt)
        t1 = time()
        push!(times, t1 - t0)
        println("rep $i/$N_REPS: $(round(times[end], digits = 4)) s")
    end

    df = DataFrame(rep = 1:N_REPS, build_solve_time_s = times)
    df.tool .= variant.label
    df.battmo_version .= string(pkgversion(BattMo))
    global all_rows = vcat(all_rows, df)

    println("mean: $(round(mean(times), digits = 4)) s")
    println("min:  $(round(minimum(times), digits = 4)) s")
    println("std:  $(round(std(times), digits = 4)) s")
    println()
end

output_path = joinpath("results", "battmo_full_benchmark_times.csv")
CSV.write(output_path, all_rows)
println("Saved $output_path")

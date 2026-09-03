t_script_start = time()

using BattMo

t_after_import = time()

# -----------------------------
# BattMo.jl model and parameters (Chen 2020, 1C discharge to 2.5 V)
# Default p2d simulation_settings (TimeStepDuration = 50 s), same physical
# setup as battmo_chen.jl / battmo_benchmark.jl's "default" variant.
# -----------------------------
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

cycling_protocol["DRate"] = 1.0
cycling_protocol["LowerVoltageLimit"] = 2.5

model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)

t_before_solve = time()
output = solve(sim; info_level = -1)
t_after_solve = time()

t = output.time_series["Time"]
v = output.time_series["Voltage"]

println("BattMo.jl $(pkgversion(BattMo))")
println("import time (using BattMo, includes package JIT/precompile): $(round(t_after_import - t_script_start, digits = 4)) s")
println("setup time:          $(round(t_before_solve - t_after_import, digits = 4)) s")
println("solve time (includes JIT compilation of solve()): $(round(t_after_solve - t_before_solve, digits = 4)) s")
println("total (from using BattMo): $(round(t_after_solve - t_script_start, digits = 4)) s")
println("t_final=$(round(t[end], digits = 1)) s  v_final=$(round(v[end], digits = 4)) V")

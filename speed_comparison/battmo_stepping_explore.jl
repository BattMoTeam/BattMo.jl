using BattMo, Statistics

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
cycling_protocol["DRate"] = 1.0
cycling_protocol["LowerVoltageLimit"] = 2.5

model = LithiumIonBattery()

function build_sim(dt; ramp_steps = 5)
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["TimeStepDuration"] = dt
    simulation_settings["RampUpSteps"] = ramp_steps
    return Simulation(model, cell_parameters, cycling_protocol; simulation_settings = simulation_settings)
end

function bench(dt; n_warmup = 1, n_reps = 5)
    sim = build_sim(dt)
    for _ in 1:n_warmup
        solve(sim; info_level = -1)
    end
    times = Float64[]
    local output
    for _ in 1:n_reps
        t0 = time()
        output = solve(sim; info_level = -1)
        t1 = time()
        push!(times, t1 - t0)
    end
    n_steps = length(sim.time_steps)
    t = output.time_series["Time"]
    v = output.time_series["Voltage"]
    return (dt = dt, n_steps = n_steps, mean_time = mean(times), std_time = std(times), min_time = minimum(times), t_final = t[end], v_final = v[end])
end

for dt in [50, 100, 200]
    r = bench(dt)
    println("dt=$(r.dt)s  report_steps=$(r.n_steps)  mean=$(round(r.mean_time, digits=4))s  std=$(round(r.std_time, digits=4))s  min=$(round(r.min_time, digits=4))s  t_final=$(round(r.t_final, digits=1))s  v_final=$(round(r.v_final, digits=4))V")
end

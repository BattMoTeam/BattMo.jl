using BattMo, GLMakie

# New API and parameter sets
model_settings = load_model_settings(; from_default_set = "P4D_demo")
# model_settings["UseThermalModel"] = "Sequential"
cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
# cycling_protocol["LowerCutoffVoltage"] = 2.4
# cycling_protocol["HigherCutoffVoltage"] = 4.1
# cycling_protocol["NumberOfCycles"] = 3
# cycling_protocol["CRate"] = 2
# cycling_protocol["DRate"] = 2

model = LithiumIonBatteryModel(; model_settings);



sim = Simulation(model, cell_parameters, cycling_protocol);

output1 = solve(sim; accept_invalid = true)


t1 = [state[:Control][:ControllerCV].time for state in output1[:states]]
E1 = [state[:Control][:Phi][1] for state in output1[:states]]
I1 = [state[:Control][:Current][1] for state in output1[:states]]



fig = Figure()

ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")
lines!(ax, t1, E1, linestyle = :dot, linewidth = 5)  # Big dotted line


ax = Axis(fig[1, 2], ylabel = "Current / A", xlabel = "Time / s")
lines!(ax, t1, I1, label = "new_new", linestyle = :dot, linewidth = 5)


fig[1, 3] = Legend(fig, ax, "parameter set", framevisible = false)

fig # hide
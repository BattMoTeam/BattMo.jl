
using BattMo, GLMakie

using CSV
using DataFrames
using Printf


# Read Experimental voltage curves
df_05 = CSV.read("./examples/voltage_curves/Xu_2015_voltageCurve_05C.csv", DataFrame)
df_1 = CSV.read("./examples/voltage_curves/Xu_2015_voltageCurve_1C.csv", DataFrame)
df_2 = CSV.read("./examples/voltage_curves/Xu_2015_voltageCurve_2C.csv", DataFrame)

dfs = [df_05, df_1, df_2]

cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model_setup = LithiumIonBattery()

CRates = [0.5, 1, 2]
outputs = []

for CRate in CRates
	cycling_protocol["DRate"] = CRate
	sim = Simulation(model_setup, cell_parameters, cycling_protocol)

	output = solve(sim)
	push!(outputs, (CRate = CRate, output = output))
end


fig = Figure()
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

for data in outputs
	local t = [state[:Control][:Controller].time for state in data.output[:states]]
	local E = [state[:Control][:Phi][1] for state in data.output[:states]]
	lines!(ax, t, E, label = @sprintf("%.1f", data.CRate))
end

for (i, df) in enumerate(dfs)
	local t = df[:, 1]
	local E = df[:, 2]
	label = "Experimental " * @sprintf("%.1f", CRates[i])
	lines!(ax, t, E, linestyle = :dot, label = label)
end

fig[1, 2] = Legend(fig, ax, "C rate", framevisible = false)
fig # hide


using BattMo, GLMakie, CSV, DataFrames, Statistics

# ## Load the experimental data and set up a base case
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_1_crate.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_6_crate.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_voltage_1_4_crate.csv"), DataFrame)

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCCV")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

t_exp_06 = df_06[:, 1] * 3600 / 1000 / A / 5
v_exp_06 = df_06[:, 2]

t_exp_01 = df_01[:, 1] * 3600 / 1000 / A
v_exp_01 = df_01[:, 2]

t_exp_14 = df_14[:, 1] * 3600 / 1000 / A / 12
v_exp_14 = df_14[:, 2]

cell_parameters["NegativeElectrode"]["ElectrodeCoating"]["Thickness"] = 1.2 * 64e-6
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] = 0.83
# cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] = 1.667145305054536 * cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"]
simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 10
simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 10
simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 10
simulation_settings["GridResolution"]["Separator"] = 5

simulation_settings["TimeStepDuration"] = 20
@info "np ratio" compute_np_ratio(cell_parameters)

model_settings["ReactionRateConstant"] = "UserDefined"

cycling_protocol["DRate"] = 0.5
cycling_protocol["CRate"] = 0.5
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.0
# cycling_protocol["InitialControl"] = "discharging"
# cycling_protocol["TotalNumberOfCycles"] = 1
# cycling_protocol["InitialStateOfCharge"] = 1.0

# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 2.0306459345750275e-16
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 4.542183772045386e-11
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 1.2952951004386266e-15
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1.6787424917471138e-11

nothing # hide

model = LithiumIonBattery(; model_settings)

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);

# Now we can run the simulation
output = solve(sim; accept_invalid = true, info_level = 1, hook = logger)
nothing # hide


# Now we can easily plot some results

states = get_output_states(output)
time_series = get_output_time_series(output)

# ne_am_diff = states[:NeAmDiffusionCoefficient][:, :20]
# pe_am_diff = states[:PeAmDiffusionCoefficient][:, 31:50]

# @info maximum(states[:PeAmSurfaceConcentration][:, 14:23])


plot_dashboard(output; plot_type = "contour")

max_t_exp = maximum(t_exp_06)
max_t = maximum(time_series[:Time])

@info "ratio", max_t_exp / max_t

ne_stoich = []
pe_stoich = []
for i in 1:length(states[:NeAmSurfaceConcentration][:, 1])
	push!(ne_stoich, mean(states[:NeAmSurfaceConcentration][i, :8]) ./ cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"])
	push!(pe_stoich, mean(states[:PeAmSurfaceConcentration][i, 14:23]) ./ cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"])

end

fig = Figure()
ax = Axis(fig[1, 1], title = "Stoichiometry", xlabel = "Time / s", ylabel = "Stoichiometry / -")
lines!(ax, time_series[:Time], ne_stoich, label = "Negative")
lines!(ax, time_series[:Time], pe_stoich, label = "Positive")
# lines!(ax, t_exp_06, v_exp_06, label = "Experimental data")
axislegend(position = :lb)
fig

fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V")
lines!(ax, time_series[:Time], time_series[:Voltage], label = "Simulation data")
lines!(ax, t_exp_06, v_exp_06, label = "Experimental data")
axislegend(position = :lb)
fig
# plot_output(output, ["NeAmOpenCircuitPotential vs ", "PeAmOpenCircuitPotential vs Time and Position", "NeAmSurfaceConcentration vs Time and Position"]; layout = (3, 1))
# plot_output(output, ["NeAmReactionRateConst vs Time and Position", "PeAmReactionRateConst vs Time and Position"]; layout = (2, 1))


# ## Load packages and set up helper functions
using BattMo, Jutul
using CSV
using DataFrames
using GLMakie

function get_tV(x)
	t = [state[:Control][:Controller].time for state in x[:states]]
	V = [state[:Control][:Phi][1] for state in x[:states]]
	return (t, V)
end

function get_tV(x::DataFrame)
	return (x[:, 1], x[:, 2])
end

# ## Load the experimental data and set up a base case
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_1_crate.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_6_crate.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_voltage_1_4_crate.csv"), DataFrame)

dfs = [df_01, df_06, df_14]

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")

model_settings["ReactionRateConstant"] = "UserDefined"

cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 2.0306459345750275e-15
cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 4.542183772045386e-11
cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = 1.2952951004386266e-16

cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 1.6787424917471138e-11

cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.2
model = LithiumIonBattery(; model_settings)

cycling_protocol["DRate"] = 0.6
sim = Simulation(model, cell_parameters, cycling_protocol)
output0 = solve(sim; accept_invalid = true)

t0 = get_output_time_series(output0)[:Time]
V0 = get_output_time_series(output0)[:Voltage]

cap_exp_01, V_exp_01 = get_tV(df_01)
cap_exp_06, V_exp_06 = get_tV(df_06)

A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

t_exp_01 = cap_exp_01 * 3600 / 1000 / A
t_exp_06 = cap_exp_06 * 3600 / 1000 / A / 5

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.1", xlabel = "Time / s", ylabel = "Voltage / V")
lines!(ax, t0, V0, label = "Base case")
lines!(ax, t_exp_06, V_exp_06, label = "Experimental data")
axislegend(position = :lb)
fig
# ## Set up the first calibration

# setup before calibration starts.
vc06 = VoltageCalibration(t_exp_06, V_exp_06, sim)

free_calibration_parameter!(vc06,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.6, upper_bound = 1.0)
free_calibration_parameter!(vc06,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.0, upper_bound = 0.4)

# "StoichiometricCoefficientAtSOC0" at both electrodes
free_calibration_parameter!(vc06,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.0, upper_bound = 0.4)
free_calibration_parameter!(vc06,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.6, upper_bound = 1.0)

#  "MaximumConcentration" of both electrodes
free_calibration_parameter!(vc06,
	["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 3e4)
free_calibration_parameter!(vc06,
	["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 3e4)

print_calibration_overview(vc06)
# ### Solve the first calibration problem
# The calibration is performed by solving the optimization problem. This makes
# use of the adjoint method implemented in Jutul.jl and the LBFGS algorithm.
solve(vc06);
cell_parameters_calibrated = vc06.calibrated_cell_parameters;
print_calibration_overview(vc06)
# ## Compare the results of the calibration against the experimental data
# We can now compare the results of the calibrated model against the
# experimental data for the 0.5C discharge curve.
sim_opt = Simulation(model, cell_parameters_calibrated, cycling_protocol)
output_opt = solve(sim_opt);
t_opt, V_opt = get_tV(output_opt)

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.1")
lines!(ax, t0, V0, label = "BattMo initial")
lines!(ax, t_exp_06, V_exp_06, label = "Experimental data")
lines!(ax, t_opt, V_opt, label = "BattMo calibrated", linestyle = :dash)
axislegend(position = :lb)
fig
# ## Set up the second calibration
# The second calibration is performed against the 2.0C discharge curve. In the
# same manner as for the first discharge curve, we set up a set of parameters to
# calibrate against experimental data. The parameters are:
#
# - The reaction rate constant of both electrodes
# - The diffusion coefficient of both electrodes
#
# The calibration this time around starts from the parameters calibrated in the
# first step, so we use the `cell_parameters_calibrated` from the first `solve`
# call when defining the new object:
# cap_exp_14, V_exp_14 = get_tV(df_14)

# t_exp_14 = cap_exp_14 * 3600 / 1000 / A / 12

# cycling_protocol14 = deepcopy(cycling_protocol)
# cycling_protocol14["DRate"] = 1.4
# sim14 = Simulation(model, cell_parameters_calibrated, cycling_protocol14)
# output14 = solve(sim14);
# t14, V14 = get_tV(output14)

# sim14_0 = Simulation(model, cell_parameters, cycling_protocol14)
# output14_0 = solve(sim14_0);
# t14_0, V14_0 = get_tV(output14_0)

# vc14 = VoltageCalibration(t_exp_14, V_exp_14, sim14)

# free_calibration_parameter!(vc14,
# 	["NegativeElectrode", "ActiveMaterial", "ReactionRateConstant"];
# 	lower_bound = 1e-16, upper_bound = 1e-10)
# free_calibration_parameter!(vc14,
# 	["PositiveElectrode", "ActiveMaterial", "ReactionRateConstant"];
# 	lower_bound = 1e-16, upper_bound = 1e-10)

# free_calibration_parameter!(vc14,
# 	["NegativeElectrode", "ActiveMaterial", "DiffusionCoefficient"];
# 	lower_bound = 1e-16, upper_bound = 1e-12)
# free_calibration_parameter!(vc14,
# 	["PositiveElectrode", "ActiveMaterial", "DiffusionCoefficient"];
# 	lower_bound = 1e-16, upper_bound = 1e-12)
# print_calibration_overview(vc14)

# # ### Solve the second calibration problem
# cell_parameters_calibrated14, = solve(vc14);
# print_calibration_overview(vc14)
# # ## Compare the results of the second calibration against the experimental data
# # We can now compare the results of the calibrated model against the
# # experimental data for the 14.0C discharge curve. We compare three simulations against the experimental data:
# # 1. The initial simulation with the original parameters.
# # 2. The simulation with the parameters calibrated against the 0.5C discharge curve.
# # 3. The simulation with the parameters calibrated against the 0.5C and 2.0C discharge curves.
# sim_c14 = Simulation(model, cell_parameters_calibrated14, cycling_protocol14)
# output14_c = solve(sim_c14, accept_invalid = false);

# t14_c = [state[:Control][:Controller].time for state in output14_c[:states]]
# V14_c = [state[:Control][:Phi][1] for state in output14_c[:states]]

# fig = Figure()
# ax = Axis(fig[1, 1], title = "CRate = 1.4")
# lines!(ax, t14_0, V14_0, label = "BattMo.jl")
# lines!(ax, t14, V14, label = "BattMo.jl (after CRate=0.5 calibration)")

# lines!(ax, t_exp_14, V_exp_14, label = "Experimental data")
# lines!(ax, t14_c, V14_c, label = "BattMo.jl (after CRate=0.1 + Crate=1.4 calibration)", linestyle = :dash)
# axislegend(position = :lb)
# fig
# ## Compare the results of the calibrated model against the experimental data
# We can now compare the results of the calibrated model against the
# experimental data for the 0.5C, 1.0C, and 2.0C discharge curves.

# Note that we did not calibrate the model for the 1.0C discharge curve, but we
# still obtain a good fit.

# CRates = [0.1, 0.6, 1.4]
# outputs_base = []
# outputs_calibrated = []

# for CRate in CRates
# 	cycling_protocol["DRate"] = CRate
# 	simuc = Simulation(model, cell_parameters, cycling_protocol)

# 	output = solve(simuc, info_level = -1)
# 	push!(outputs_base, (CRate = CRate, output = output))

# 	simc = Simulation(model, cell_parameters_calibrated14, cycling_protocol)
# 	output_c = solve(simc, info_level = -1)

# 	push!(outputs_calibrated, (CRate = CRate, output = output_c))
# end

# colors = Makie.wong_colors()

# fig = Figure(size = (1200, 600))
# ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

# for (i, data) in enumerate(outputs_base)
# 	t_i, V_i = get_tV(data.output)
# 	lines!(ax, t_i, V_i, label = "Simulation (initial) $(round(data.CRate, digits = 2))", color = colors[i])
# end

# for (i, data) in enumerate(outputs_calibrated)
# 	t_i, V_i = get_tV(data.output)
# 	lines!(ax, t_i, V_i, label = "Simulation (calibrated) $(round(data.CRate, digits = 2))", color = colors[i], linestyle = :dash)
# end

# for (i, df) in enumerate(dfs)
# 	t_i, V_i = get_tV(df)
# 	label = "Experimental $(round(CRates[i], digits = 2))"
# 	lines!(ax, t_i, V_i, linestyle = :dot, label = label, color = colors[i])
# end

# fig[1, 2] = Legend(fig, ax, "C rate", framevisible = false)
# fig

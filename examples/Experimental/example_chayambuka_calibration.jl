
## Load packages and set up helper functions
using BattMo, Jutul
using CSV
using DataFrames
using GLMakie, StatsBase, Loess


battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

######### Load Experimental Data #########

exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_V_01C.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_V_06C.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_V_14C.csv"), DataFrame)

# --- Smoothing functions ---
function moving_average(data::AbstractVector, window::Int = 5)
	[mean(data[max(1, i - window + 1):i]) for i in 1:length(data)]
end

function loess_smooth(x, y; span = 0.3)
	model = loess(x, y; span = span)
	Loess.predict(model, x)
end

function sort_df_by_x(df)
	sort(df, by = r -> r[1])  # sort by first column
end

function smooth_df(df; window = 5, span = 0.3)
	df = sort_df_by_x(df)
	x, y = df[:, 1], df[:, 2]
	df[:, :smooth_ma] = moving_average(y, window)      # <- use df[:, :symbol]
	df[:, :smooth_loess] = loess_smooth(x, y; span = span)
	return df
end

df_01 = smooth_df(df_01)
df_06 = smooth_df(df_06)
df_14 = smooth_df(df_14)


######### Load Simulation Data #########

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

######### Alter simulation settings #########
simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 50
simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["Separator"] = 5

simulation_settings["TimeStepDuration"] = 300

######### Alter cycling protocol #########
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 0.1
cycling_protocol["CRate"] = 1.4
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.2

######### Alter cell parameters #########
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = Dict(
# 	"FunctionName" => "calc_ne_k",
# )
# cell_parameters["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = Dict(
# 	"FunctionName" => "calc_ne_D",
# )
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = Dict(
# 	"FunctionName" => "calc_pe_k",
# )
# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = Dict(
# 	"FunctionName" => "calc_pe_D",
# )

# cell_parameters["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] = Dict(
# 	"FunctionName" => "calc_pe_ocp",
# )


######### Format experimental data ##########
A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]
cap_exp_01 = df_01[:, 1]
t_exp_01 = (df_01[:, 1] .- minimum(df_01[:, 1])) .* 3600 ./ 1000 ./ A
V_exp_01 = df_01[:, 2]

cap_exp_06 = df_06[:, 1]
t_exp_06 = (df_06[:, 1] .- minimum(df_06[:, 1])) .* 3600 ./ 1000 ./ A ./ 5
V_exp_06 = df_06[:, 2]


cap_exp_14 = df_14[:, 1]
t_exp_14 = (df_14[:, 1] .- minimum(df_14[:, 1])) .* 3600 ./ 1000 ./ A ./ 12
V_exp_14 = df_14[:, 2]


######### Run simulation ##########
model = SodiumIonBattery(; model_settings);

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim; info_level = 0);


######### Plot results ##########

t0 = get_output_time_series(output)[:Time]
V0 = get_output_time_series(output)[:Voltage]
metrics = get_output_metrics(output)


fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Capacity / mAh", ylabel = "Voltage / V")
lines!(ax, metrics[:Capacity] .* 1000, V0, label = "Simulation data")
lines!(ax, cap_exp_01, V_exp_01, label = "Experimental data")
axislegend(position = :lb)
fig

######### Setup Crate 0.6 calibration #########

calibration_06 = VoltageCalibration(t_exp_01, V_exp_01, sim)

# calibrate "StoichiometricCoefficientAtSOC100" at both electrodes
free_calibration_parameter!(calibration_06,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.6, upper_bound = 1.0)
free_calibration_parameter!(calibration_06,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.0, upper_bound = 0.4)

# calibrate "StoichiometricCoefficientAtSOC0" at both electrodes
free_calibration_parameter!(calibration_06,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.0, upper_bound = 0.4)
free_calibration_parameter!(calibration_06,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.6, upper_bound = 1.0)

#  calibrate "MaximumConcentration" of both electrodes
free_calibration_parameter!(calibration_06,
	["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 3e4)
free_calibration_parameter!(calibration_06,
	["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 3e4)

print_calibration_overview(calibration_06)

######### Solve Crate 0.6 calibration problem #########

solve(calibration_06);

print_calibration_overview(calibration_06)


######### Crate 0.6 calibration results #########
simulation_settings["TimeStepDuration"] = 20

sim_opt = Simulation(model, calibration_06.calibrated_cell_parameters, cycling_protocol; simulation_settings);
output_opt = solve(sim_opt);

time_series = get_output_time_series(output_opt)
t_opt = time_series[:Time]
V_opt = time_series[:Voltage]

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.1")
lines!(ax, t0, V0, label = "BattMo initial")
lines!(ax, t_exp_01, V_exp_01, label = "Experimental data")
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

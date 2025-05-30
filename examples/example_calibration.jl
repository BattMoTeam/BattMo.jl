# # Gradient-based parameter calibration of a lithium-ion battery model
# This example demonstrates how to calibrate a lithium-ion battery against data
# model using BattMo.jl. The example uses a two-step calibration process:
#
# 1. We first calibrate the model against a 0.5C discharge curve (adjusting
#    stoichiometric coefficients and maximum concentration in the active
#    material)
# 2. We then calibrate the model against a 2.0C discharge curve (adjusting
#    reaction rate constants and diffusion coefficients in the active material)
#
# Finally, we compare the results of the calibrated model against the
# experimental data for discharge rates of 0.5C, 1.0C, and 2.0C.

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
df_05 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_05C.csv"), DataFrame)
df_1 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_1C.csv"), DataFrame)
df_2 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_2C.csv"), DataFrame)

dfs = [df_05, df_1, df_2]

cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

cycling_protocol["LowerVoltageLimit"] = 2.0
model_setup = LithiumIonBattery()

cycling_protocol["DRate"] = 0.5
sim = Simulation(model_setup, cell_parameters, cycling_protocol)
output0 = solve(sim)

t0, V0 = get_tV(output0)
t_exp_05, V_exp_05 = get_tV(df_05)
t_exp_1, V_exp_1 = get_tV(df_1)

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.5", xlabel = "Time / s", ylabel = "Voltage / V")
lines!(ax, t0, V0, label = "Base case")
lines!(ax, t_exp_05, V_exp_05, label = "Experimental data")
axislegend(position = :lb)
fig
# ## Set up the first calibration
# We select the following parameters to calibrate:
# - "StoichiometricCoefficientAtSOC100" at both electrodes
# - "StoichiometricCoefficientAtSOC0" at both electrodes
# - "MaximumConcentration" of both electrodes
#
# We also set bounds for these parameters to ensure they remain physically
# meaningful and possible to simulate. The objective function is the sum of
# squares: ``\sum_i (V_i - V_{exp,i})^2``, where ``V_i`` is the voltage from the
# model and ``V_{exp,i}`` is the voltage from the experimental data at step
# ``i``.
#
# We print the setup as a table to give the user the opportunity to review the
# setup before calibration starts.
vc05 = VoltageCalibration(t_exp_05, V_exp_05, sim)

free_calibration_parameter!(vc05,
    ["NegativeElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
    lower_bound = 0.0, upper_bound = 1.0)
free_calibration_parameter!(vc05,
    ["PositiveElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
    lower_bound = 0.0, upper_bound = 1.0)

# "StoichiometricCoefficientAtSOC0" at both electrodes
free_calibration_parameter!(vc05,
    ["NegativeElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
    lower_bound = 0.0, upper_bound = 1.0)
free_calibration_parameter!(vc05,
    ["PositiveElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
    lower_bound = 0.0, upper_bound = 1.0)

#  "MaximumConcentration" of both electrodes
free_calibration_parameter!(vc05,
    ["NegativeElectrode","ActiveMaterial", "MaximumConcentration"];
    lower_bound = 10000.0, upper_bound = 1e5)
free_calibration_parameter!(vc05,
    ["PositiveElectrode","ActiveMaterial", "MaximumConcentration"];
    lower_bound = 10000.0, upper_bound = 1e5)

print_calibration_overview(vc05)
# ### Solve the first calibration problem
# The calibration is performed by solving the optimization problem. This makes
# use of the adjoint method implemented in Jutul.jl and the LBFGS algorithm.
solve(vc05);
cell_parameters_calibrated = vc05.calibrated_cell_parameters;
print_calibration_overview(vc05)
# ## Compare the results of the calibration against the experimental data
# We can now compare the results of the calibrated model against the
# experimental data for the 0.5C discharge curve.
sim_opt = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol)
output_opt = solve(sim_opt);
t_opt, V_opt = get_tV(output_opt)

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.5")
lines!(ax, t0, V0, label = "BattMo initial")
lines!(ax, t_exp_05, V_exp_05, label = "Experimental data")
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
t_exp_2, V_exp_2 = get_tV(df_2)

cycling_protocol2 = deepcopy(cycling_protocol)
cycling_protocol2["DRate"] = 2.0
sim2 = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol2)
output2 = solve(sim2);
t2, V2 = get_tV(output2)

sim2_0 = Simulation(model_setup, cell_parameters, cycling_protocol2)
output2_0 = solve(sim2_0);
t2_0, V2_0 = get_tV(output2_0)

vc2 = VoltageCalibration(t_exp_2, V_exp_2, sim2)

free_calibration_parameter!(vc2,
    ["NegativeElectrode","ActiveMaterial", "ReactionRateConstant"];
    lower_bound = 1e-16, upper_bound = 1e-10)
free_calibration_parameter!(vc2,
    ["PositiveElectrode","ActiveMaterial", "ReactionRateConstant"];
    lower_bound = 1e-16, upper_bound = 1e-10)

free_calibration_parameter!(vc2,
    ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
    lower_bound = 1e-16, upper_bound = 1e-12)
free_calibration_parameter!(vc2,
    ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
    lower_bound = 1e-16, upper_bound = 1e-12)
print_calibration_overview(vc2)

# ### Solve the second calibration problem
cell_parameters_calibrated2, = solve(vc2);
print_calibration_overview(vc2)
# ## Compare the results of the second calibration against the experimental data
# We can now compare the results of the calibrated model against the
# experimental data for the 2.0C discharge curve. We compare three simulations against the experimental data:
# 1. The initial simulation with the original parameters.
# 2. The simulation with the parameters calibrated against the 0.5C discharge curve.
# 3. The simulation with the parameters calibrated against the 0.5C and 2.0C discharge curves.
sim_c2 = Simulation(model_setup, cell_parameters_calibrated2, cycling_protocol2)
output2_c = solve(sim_c2, accept_invalid = false);

t2_c = [state[:Control][:Controller].time for state in output2_c[:states]]
V2_c = [state[:Control][:Phi][1] for state in output2_c[:states]]

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 2.0")
lines!(ax, t2_0, V2_0, label = "BattMo.jl")
lines!(ax, t2, V2, label = "BattMo.jl (after CRate=0.5 calibration)")

lines!(ax, t_exp_2, V_exp_2, label = "Experimental data")
lines!(ax, t2_c, V2_c, label = "BattMo.jl (after CRate=0.5 + Crate=2.0 calibration)", linestyle = :dash)
axislegend(position = :lb)
fig
# ## Compare the results of the calibrated model against the experimental data
# We can now compare the results of the calibrated model against the
# experimental data for the 0.5C, 1.0C, and 2.0C discharge curves.

# Note that we did not calibrate the model for the 1.0C discharge curve, but we
# still obtain a good fit.

CRates = [0.5, 1.0, 2.0]
outputs_base = []
outputs_calibrated = []

for CRate in CRates
	cycling_protocol["DRate"] = CRate
	simuc = Simulation(model_setup, cell_parameters, cycling_protocol)

	output = solve(simuc, info_level = -1)
	push!(outputs_base, (CRate = CRate, output = output))

    simc = Simulation(model_setup, cell_parameters_calibrated2, cycling_protocol)
	output_c = solve(simc, info_level = -1)

    push!(outputs_calibrated, (CRate = CRate, output = output_c))
end

colors = Makie.wong_colors()

fig = Figure(size = (1200, 600))
ax = Axis(fig[1, 1], ylabel = "Voltage / V", xlabel = "Time / s", title = "Discharge curve")

for (i, data) in enumerate(outputs_base)
    t_i, V_i = get_tV(data.output)
    lines!(ax, t_i, V_i, label = "Simulation (initial) $(round(data.CRate, digits = 2))", color = colors[i])
end

for (i, data) in enumerate(outputs_calibrated)
    t_i, V_i = get_tV(data.output)
	lines!(ax, t_i, V_i, label = "Simulation (calibrated) $(round(data.CRate, digits = 2))", color = colors[i], linestyle = :dash)
end

for (i, df) in enumerate(dfs)
    t_i, V_i = get_tV(df)
    label = "Experimental $(round(CRates[i], digits = 2))"
	lines!(ax, t_i, V_i, linestyle = :dot, label = label, color = colors[i])
end

fig[1, 2] = Legend(fig, ax, "C rate", framevisible = false)
fig

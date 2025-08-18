using BattMo, GLMakie, CSV, DataFrames

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
include(joinpath(battmo_base, "src/input/defaults/cell_parameters/Chayambuka_functions.jl"))

######### Load Experimental Data #########

exdata = joinpath(battmo_base, "examples", "example_data")
df_01 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_1_crate.csv"), DataFrame)
df_06 = CSV.read(joinpath(exdata, "Chayambuka_voltage_0_6_crate.csv"), DataFrame)
df_14 = CSV.read(joinpath(exdata, "Chayambuka_voltage_1_4_crate.csv"), DataFrame)


######### Load Simulation Data #########

cell_parameters = load_cell_parameters(; from_default_set = "Chayambuka2022")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

######### Alter model settings #########
model_settings["ReactionRateConstant"] = "UserDefined"

######### Alter simulation settings #########
simulation_settings["GridResolution"]["NegativeElectrodeCoating"] = 8
simulation_settings["GridResolution"]["PositiveElectrodeCoating"] = 50
simulation_settings["GridResolution"]["NegativeElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["PositiveElectrodeActiveMaterial"] = 50
simulation_settings["GridResolution"]["Separator"] = 5

simulation_settings["TimeStepDuration"] = 50

######### Alter cycling protocol #########
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 1.4
cycling_protocol["CRate"] = 0.5
cycling_protocol["LowerVoltageLimit"] = 2.0
cycling_protocol["UpperVoltageLimit"] = 4.2


######### Run simulation ##########
model = LithiumIonBattery(; model_settings);

sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);
output = solve(sim; logger = logger, info_level = 0);


######### Format experimental data ##########
A = cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"]

t_exp_01 = (df_01[:, 1] .- minimum(df_01[:, 1])) .* 3600 ./ 1000 ./ A
V_exp_01 = df_01[:, 2]

t_exp_06 = (df_06[:, 1] .- minimum(df_06[:, 1])) .* 3600 ./ 1000 ./ A ./ 5
V_exp_06 = df_06[:, 2]

t_exp_14 = (df_14[:, 1] .- minimum(df_14[:, 1])) .* 3600 ./ 1000 ./ A ./ 12
V_exp_14 = df_14[:, 2]


######### Plot results ##########

fig = Figure()
ax = Axis(fig[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V")
lines!(ax, time_series[:Time], time_series[:Voltage], label = "Simulation data")
lines!(ax, t_exp_14, v_exp_14, label = "Experimental data")
axislegend(position = :lb)
fig

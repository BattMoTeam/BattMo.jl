using BattMo, Jutul
using CSV
using DataFrames
using GLMakie

# ## Load the experimental data and set up a base case
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")

# Voltage curve C-rate 0.5
df_05 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_05C.csv"), DataFrame)

t_exp_05 = df_05[:, 1]
V_exp_05 = df_05[:, 2]

# Load parameter sets
cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

cycling_protocol["LowerVoltageLimit"] = 2.25
cycling_protocol["DRate"] = 0.5

# Setup model and simulation
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)

# Solve initial simulation and retrieve the time series results
output0 = solve(sim)
time_series_0 = get_output_time_series(output0)

# Setup the voltage calibration
cal = VoltageCalibration(t_exp_05, V_exp_05, sim)

# Free the parameters that should be calibrated
free_calibration_parameter!(cal,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.0, upper_bound = 1.0)
free_calibration_parameter!(cal,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0.0, upper_bound = 1.0)

# "StoichiometricCoefficientAtSOC0" at both electrodes
free_calibration_parameter!(cal,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.0, upper_bound = 1.0)
free_calibration_parameter!(cal,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0.0, upper_bound = 1.0)

#  "MaximumConcentration" of both electrodes
free_calibration_parameter!(cal,
	["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 1e5)
free_calibration_parameter!(cal,
	["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"];
	lower_bound = 10000.0, upper_bound = 1e5)


# Solve the calibration problem
solve(cal);

# Retrieve the calibrated parameters
cell_parameters_calibrated = cal.calibrated_cell_parameters;

# ## Compare the results of the calibration against the experimental data
sim_opt = Simulation(model, cell_parameters_calibrated, cycling_protocol)
output_opt = solve(sim_opt);
time_series_opt = get_output_time_series(output_opt)

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.5", xlabel = "Time [s]", ylabel = "Voltage [V]")
lines!(ax, time_series_0.Time, time_series_0.Voltage, label = "BattMo initial")
lines!(ax, t_exp_05, V_exp_05, label = "Experimental data", linestyle = :dash)
lines!(ax, time_series_opt.Time, time_series_opt.Voltage, label = "BattMo calibrated")
axislegend(position = :lb)
fig

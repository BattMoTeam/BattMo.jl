using BattMo
using DelimitedFiles
using Statistics
using GLMakie

"""
Calibrate Bolay composition and density parameters against the digitized
discharge curve in `examples/Experimental/resources/bolay_discharge_data.csv`.

The calibration target in BattMo is time-voltage. Since this experiment is a
constant-current discharge at 0.3 A, we convert capacity [Ah] to time [s] as
`t = capacity*3600/current`.
"""

function capacity_voltage_rmse(sim_capacity, sim_voltage, exp_capacity, exp_voltage)
	yq = fill(NaN, length(exp_capacity))
	for (i, x) in pairs(exp_capacity)
		if x < sim_capacity[1] || x > sim_capacity[end]
			continue
		end
		k = searchsortedlast(sim_capacity, x)
		if k == length(sim_capacity)
			yq[i] = sim_voltage[end]
		elseif x == sim_capacity[k]
			yq[i] = sim_voltage[k]
		else
			x0, x1 = sim_capacity[k], sim_capacity[k+1]
			y0, y1 = sim_voltage[k], sim_voltage[k+1]
			yq[i] = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
		end
	end
	valid = .!isnan.(yq)
	r = yq[valid] .- exp_voltage[valid]
	return sqrt(mean(r .^ 2)), mean(abs.(r)), count(valid)
end

function print_composition_summary(cell_parameters)
	for electrode in ("PositiveElectrode", "NegativeElectrode")
		am = cell_parameters[electrode]["ActiveMaterial"]["MassFraction"]
		ca = cell_parameters[electrode]["ConductiveAdditive"]["MassFraction"]
		bi = cell_parameters[electrode]["Binder"]["MassFraction"]
		ρeff = cell_parameters[electrode]["Coating"]["EffectiveDensity"]
		@info "$electrode composition summary" active = am additive = ca binder = bi sum = am + ca + bi effective_density = ρeff
	end
end

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))

cell_file = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters.json")
exp_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_discharge_data_1.csv")
output_file = joinpath(@__DIR__, "bolay_cell_parameters_calibrated.json")

cell_parameters = load_cell_parameters(; from_file_path = cell_file)
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["SEIModel"] = "Bolay"
# Validation currently expects numeric transference number.
cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4083333333333333

current_A = 1.0
# cycling_protocol["Experiment"] = ["Discharge at $(current_A) A until 3.0 V"]
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 1/3
cycling_protocol["LowerVoltageLimit"] = 3.0

exp_data = readdlm(exp_file, ',', Float64)
exp_time = exp_data[:, 1]
exp_voltage = exp_data[:, 2]
exp_capacity = exp_time .* current_A # Ah

model = LithiumIonBattery(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol)
base_output = solve(sim; accept_invalid = true, info_level = 1)

base_rmse, base_mae, base_points = capacity_voltage_rmse(
	base_output.time_series["CumulativeCapacity"],
	base_output.time_series["Voltage"],
	exp_capacity,
	exp_voltage,
)
@info "Base curve mismatch against capacity-voltage data" rmse = base_rmse mae = base_mae points = base_points

cal = VoltageCalibration(exp_time, exp_voltage, sim)
# Positive electrode mass fractions
free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "MassFraction"]; lower_bound = 0.65, upper_bound = 0.8)
free_calibration_parameter!(cal, ["PositiveElectrode", "ConductiveAdditive", "MassFraction"]; lower_bound = 0.005, upper_bound = 0.20)
free_calibration_parameter!(cal, ["PositiveElectrode", "Binder", "MassFraction"]; lower_bound = 0.005, upper_bound = 0.10)

# # Positive electrode densities
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "Density"]; lower_bound = 3000.0, upper_bound = 5200.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ConductiveAdditive", "Density"]; lower_bound = 1500.0, upper_bound = 2200.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "Binder", "Density"]; lower_bound = 1300.0, upper_bound = 2000.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "Coating", "EffectiveDensity"]; lower_bound = 1500.0, upper_bound = 3000.0)

# # Negative electrode mass fractions
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "MassFraction"]; lower_bound = 0.65, upper_bound = 0.85)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ConductiveAdditive", "MassFraction"]; lower_bound = 0.005, upper_bound = 0.20)
# free_calibration_parameter!(cal, ["NegativeElectrode", "Binder", "MassFraction"]; lower_bound = 0.005, upper_bound = 0.10)

# # Negative electrode densities
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "Density"]; lower_bound = 1800.0, upper_bound = 2800.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ConductiveAdditive", "Density"]; lower_bound = 1500.0, upper_bound = 2200.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "Binder", "Density"]; lower_bound = 800.0, upper_bound = 1800.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "Coating", "EffectiveDensity"]; lower_bound = 1000.0, upper_bound = 2600.0)

free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"]; lower_bound = 0.7, upper_bound = 1.0)
free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"]; lower_bound = 0.0, upper_bound = 0.3)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"]; lower_bound = 23610, upper_bound = 29610)


free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"]; lower_bound = 0.0, upper_bound = 0.3)
free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"]; lower_bound = 0.7, upper_bound = 1.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"]; lower_bound = 28000, upper_bound = 34000)

# free_calibration_parameter!(cal, ["Electrolyte", "TransferenceNumber"]; lower_bound = 0.35, upper_bound = 0.5)
# free_calibration_parameter!(cal, ["Cell", "ElectrodeGeometricSurfaceArea"]; lower_bound = 0.1, upper_bound = 0.3)


#  "ReactionRateConstant" of both electrodes
free_calibration_parameter!(vc05,
	["NegativeElectrode", "ActiveMaterial", "ReactionRateConstant"];
	lower_bound = 1e-16, upper_bound = 1e-10)
free_calibration_parameter!(vc05,
	["PositiveElectrode", "ActiveMaterial", "ReactionRateConstant"];
	lower_bound = 1e-16, upper_bound = 1e-10)

#  "DiffusionCoefficient" of both electrodes
free_calibration_parameter!(vc05,
	["NegativeElectrode", "ActiveMaterial", "DiffusionCoefficient"];
	lower_bound = 1e-16, upper_bound = 1e-12)
free_calibration_parameter!(vc05,
	["PositiveElectrode", "ActiveMaterial", "DiffusionCoefficient"];
	lower_bound = 1e-16, upper_bound = 1e-12)


print_info(cal)
solve(cal)
print_info(cal)

cell_parameters_calibrated = cal.calibrated_cell_parameters
write_to_json_file(output_file, cell_parameters_calibrated)
@info "Wrote calibrated parameters" output_file
print_composition_summary(cell_parameters_calibrated)

sim_opt = Simulation(model, cell_parameters_calibrated, cycling_protocol)
opt_output = solve(sim_opt; accept_invalid = true, info_level = 1)

opt_rmse, opt_mae, opt_points = capacity_voltage_rmse(
	opt_output.time_series["Time"],
	opt_output.time_series["Voltage"],
	exp_capacity,
	exp_voltage,
)
@info "Calibrated curve mismatch against capacity-voltage data" rmse = opt_rmse mae = opt_mae points = opt_points

fig = Figure(size = (1000, 500))
ax = Axis(fig[1, 1], xlabel = "Time / h", ylabel = "Voltage / V", title = "Bolay Calibration")
lines!(ax, base_output.time_series["Time"] ./ 3600.0, base_output.time_series["Voltage"], label = "Base")
lines!(ax, opt_output.time_series["Time"] ./ 3600.0, opt_output.time_series["Voltage"], label = "Calibrated")
scatter!(ax, exp_time, exp_voltage, label = "Experiment", markersize = 8)
axislegend(ax, position = :lb)
fig

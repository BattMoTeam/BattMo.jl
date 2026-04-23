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

cell_file = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters_calibrated_stoich_effdens.json")
exp_file = joinpath(battmo_base, "examples/Experimental/data/bolay_discharge_data_1.csv")
output_file = joinpath(@__DIR__, "bolay_cell_parameters_calibrated.json")

cell_parameters = load_cell_parameters(; from_file_path = cell_file)
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")
simulation_settings = load_simulation_settings(; from_default_set = "p2d")
# simulation_settings["TimeStepDuration"] = 20

model_settings["SEIModel"] = "Bolay"
# Validation currently expects numeric transference number.
cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4083333333333333

# Calculate effective densities
pe_am_mf = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MassFraction"]
pe_b_mf = cell_parameters["PositiveElectrode"]["Binder"]["MassFraction"]
pe_add_mf = cell_parameters["PositiveElectrode"]["ConductiveAdditive"]["MassFraction"]
pe_am_density = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["Density"]
pe_b_density = cell_parameters["PositiveElectrode"]["Binder"]["Density"]
pe_add_density = cell_parameters["PositiveElectrode"]["ConductiveAdditive"]["Density"]
pe_porosity = 0.4

ne_am_mf = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MassFraction"]
ne_b_mf = cell_parameters["NegativeElectrode"]["Binder"]["MassFraction"]
ne_add_mf = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["MassFraction"]
ne_am_density = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["Density"]
ne_b_density = cell_parameters["NegativeElectrode"]["Binder"]["Density"]
ne_add_density = cell_parameters["NegativeElectrode"]["ConductiveAdditive"]["Density"]
ne_porosity = 0.4

cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"] = (1-pe_porosity) * (pe_am_mf * pe_am_density + pe_b_mf * pe_b_density + pe_add_mf * pe_add_density)
cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"] = (1-ne_porosity) * (ne_am_mf * ne_am_density + ne_b_mf * ne_b_density + ne_add_mf * ne_add_density)

cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["InitialControl"] = "discharging"
cycling_protocol["TotalNumberOfCycles"] = 0
cycling_protocol["DRate"] = 1 / 3
cycling_protocol["CRate"] = cycling_protocol["DRate"]
cycling_protocol["LowerVoltageLimit"] = 3.0
cycling_protocol["UpperVoltageLimit"] = 4.0

exp_data = readdlm(exp_file, ',', Float64)
exp_time = exp_data[:, 1] * 3600.0
exp_voltage = exp_data[:, 2]
# exp_time = exp_capacity .* 3600.0 ./ current_A

model = LithiumIonBattery(; model_settings)
sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings = simulation_settings)
base_output = solve(sim; accept_invalid = true, info_level = 0)

base_rmse, base_mae, base_points = capacity_voltage_rmse(
	base_output.time_series["CumulativeCapacity"],
	base_output.time_series["Voltage"],
	exp_capacity,
	exp_voltage,
)
@info "Base curve mismatch against capacity-voltage data" rmse = base_rmse mae = base_mae points = base_points

cal = VoltageCalibration(exp_time, exp_voltage, sim)


# # Positive electrode densities
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "Density"]; lower_bound = 3500.0, upper_bound = 5200.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ConductiveAdditive", "Density"]; lower_bound = 1500.0, upper_bound = 2200.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "Binder", "Density"]; lower_bound = 1300.0, upper_bound = 2000.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "Coating", "EffectiveDensity"]; lower_bound = 2000.0, upper_bound = 3000.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"]; lower_bound = 0.5, upper_bound = 1.0)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"]; lower_bound = 0.0, upper_bound = 0.5)
free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "ParticleRadius"]; lower_bound = 1.0e-7, upper_bound = 5e-6)
# free_calibration_parameter!(cal, ["PositiveElectrode", "ActiveMaterial", "ElectronicConductivity"]; lower_bound = 0.01, upper_bound = 50)


# Negative electrode densities
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "Density"]; lower_bound = 1800.0, upper_bound = 2800.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ConductiveAdditive", "Density"]; lower_bound = 1500.0, upper_bound = 2200.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "Binder", "Density"]; lower_bound = 800.0, upper_bound = 1800.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "Coating", "EffectiveDensity"]; lower_bound = 1000.0, upper_bound = 2000.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"]; lower_bound = 0.5, upper_bound = 1.0)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"]; lower_bound = 0.0, upper_bound = 0.5)
free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "ParticleRadius"]; lower_bound = 1.0e-6, upper_bound = 5e-5)
# free_calibration_parameter!(cal, ["NegativeElectrode", "ActiveMaterial", "ElectronicConductivity"]; lower_bound = 0.01, upper_bound = 300)


# free_calibration_parameter!(cal, ["Electrolyte", "Density"]; lower_bound = 1000, upper_bound = 2000)

print_info(cal)
solve(cal)
print_info(cal)

cell_parameters_calibrated = cal.calibrated_cell_parameters
write_to_json_file(output_file, cell_parameters_calibrated)
@info "Wrote calibrated parameters" output_file
print_composition_summary(cell_parameters_calibrated)

sim_opt = Simulation(model, cell_parameters_calibrated, cycling_protocol; simulation_settings = simulation_settings)
opt_output = solve(sim_opt; accept_invalid = true, info_level = 0)

opt_rmse, opt_mae, opt_points = capacity_voltage_rmse(
	opt_output.time_series["CumulativeCapacity"],
	opt_output.time_series["Voltage"],
	exp_capacity,
	exp_voltage,
)
@info "Calibrated curve mismatch against capacity-voltage data" rmse = opt_rmse mae = opt_mae points = opt_points

fig = Figure(size = (1000, 500))
ax = Axis(fig[1, 1], xlabel = "Capacity / Ah", ylabel = "Voltage / V", title = "Bolay Calibration")
lines!(ax, base_output.time_series["Time"], base_output.time_series["Voltage"], label = "Base")
lines!(ax, opt_output.time_series["Time"], opt_output.time_series["Voltage"], label = "Calibrated")
scatter!(ax, exp_time, exp_voltage, label = "Experiment", markersize = 8)
axislegend(ax, position = :lb)
fig
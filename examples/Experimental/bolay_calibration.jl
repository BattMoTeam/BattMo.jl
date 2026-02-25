using BattMo, Jutul
using GLMakie
using Statistics
using DelimitedFiles

# Calibration of the Bolay SEI setup against the same experimental data used in
# examples/validation_notebooks/sei_model.jl.

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))

# --- Model and input setup (matches sei_model.jl) ---
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters.json")
cell_parameters = load_cell_parameters(; from_file_path = fn)
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["SEIModel"] = "Bolay"
model = LithiumIonBattery(; model_settings)

cell_parameters["Electrolyte"]["TransferenceNumber"] = 0.4
cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["DRate"] = 0.1

# --- Experimental data (capacity [Ah], voltage [V]) ---
csv_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_discharge_data.csv")
exp_data = readdlm(csv_file, ',', Float64)
exp_capacity = exp_data[:, 1]
exp_voltage = exp_data[:, 2]

# VoltageCalibration expects time-voltage data. Convert capacity to equivalent
# discharge time for this constant-current protocol.
I_discharge = cycling_protocol["DRate"] * cell_parameters["Cell"]["NominalCapacity"]
exp_time_s = exp_capacity ./ I_discharge .* 3600.0

# Enforce strictly increasing time for calibration.
perm = sortperm(exp_time_s)
t_exp = exp_time_s[perm]
V_exp = exp_voltage[perm]
keep = trues(length(t_exp))
for i in 2:length(t_exp)
	keep[i] = t_exp[i] > t_exp[i-1]
end
t_exp = t_exp[keep]
V_exp = V_exp[keep]

function linear_interpolate(x_grid::AbstractVector, y_grid::AbstractVector, xq::AbstractVector)
	yq = fill(NaN, length(xq))
	for (i, x) in pairs(xq)
		if x < x_grid[1] || x > x_grid[end]
			continue
		end
		k = searchsortedlast(x_grid, x)
		if k == length(x_grid)
			yq[i] = y_grid[end]
		elseif x == x_grid[k]
			yq[i] = y_grid[k]
		else
			x0, x1 = x_grid[k], x_grid[k+1]
			y0, y1 = y_grid[k], y_grid[k+1]
			yq[i] = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
		end
	end
	return yq
end

function voltage_rmse(output, t_obs, v_obs)
	t_sim = output.time_series["Time"]
	v_sim = output.time_series["Voltage"]
	v_on_obs = linear_interpolate(t_sim, v_sim, t_obs)
	valid = .!isnan.(v_on_obs)
	res = v_on_obs[valid] .- v_obs[valid]
	return sqrt(mean(res .^ 2)), count(valid)
end

# --- Baseline simulation ---
sim_base = Simulation(model, cell_parameters, cycling_protocol)
out_base = solve(sim_base; accept_invalid = true, info_level = -1)
rmse_base, nbase = voltage_rmse(out_base, t_exp, V_exp)
@info "Baseline fit" points = nbase rmse_V = rmse_base

# --- Calibration setup (patterned after examples/example_calibration.jl) ---
vc = VoltageCalibration(t_exp, V_exp, sim_base)

# Parameters linked to SEI response / electrolyte transport.
free_calibration_parameter!(vc,
	["Electrolyte", "TransferenceNumber"];
	lower_bound = 0.2, upper_bound = 0.6)

free_calibration_parameter!(vc,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0, upper_bound = 1)

free_calibration_parameter!(vc,
	["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0, upper_bound = 1)

free_calibration_parameter!(vc,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
	lower_bound = 0, upper_bound = 1)

free_calibration_parameter!(vc,
	["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
	lower_bound = 0, upper_bound = 1)



print_info(vc)

calibrated_cell_parameters, = solve(vc)
print_info(vc)

# --- Re-simulate with calibrated parameters ---
sim_cal = Simulation(model, calibrated_cell_parameters, cycling_protocol)
out_cal = solve(sim_cal; accept_invalid = true, info_level = -11)
rmse_cal, ncal = voltage_rmse(out_cal, t_exp, V_exp)
@info "Calibrated fit" points = ncal rmse_V = rmse_cal

# --- Plot in the same axis as the experimental data (capacity-voltage) ---
cap_base = out_base.time_series["CumulativeCapacity"]
V_base = out_base.time_series["Voltage"]
cap_cal = out_cal.time_series["CumulativeCapacity"]
V_cal = out_cal.time_series["Voltage"]

f = Figure(size = (1000, 450))
ax = Axis(f[1, 1],
	title = "Bolay SEI calibration (DRate = 0.1)",
	xlabel = "Capacity / Ah",
	ylabel = "Voltage / V",
)

lines!(ax, cap_base, V_base, label = "Simulation (baseline)", linewidth = 2)
lines!(ax, cap_cal, V_cal, label = "Simulation (calibrated)", linewidth = 3, linestyle = :dash)
scatter!(ax, exp_capacity, exp_voltage, label = "Experimental data", markersize = 7)
axislegend(position = :lb)

f

using BattMo
using GLMakie
using Statistics
using DelimitedFiles

# ### Load model with Arrhenius temperature dependence
battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
fn = joinpath(battmo_base, "examples/Experimental/jsoninputs/bolay_cell_parameters_calibrated.json")
cell_parameters = load_cell_parameters(; from_file_path = fn)
cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["SEIModel"] = "Bolay"

model = LithiumIonBattery(; model_settings)

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

@show cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"]
@show cell_parameters["NegativeElectrode"]["Coating"]["EffectiveDensity"]
# cycling_protocol["Experiment"] = [
# 	"Discharge at 0.3 A until 3.0 V"]

cycling_protocol["InitialTemperature"] = 298.15 - 5
cycling_protocol["InitialStateOfCharge"] = 0.99
cycling_protocol["InitialControl"] = "discharging"
cycling_protocol["TotalNumberOfCycles"] = 1
cycling_protocol["DRate"] = 1 / 3
cycling_protocol["CRate"] = cycling_protocol["DRate"]
cycling_protocol["LowerVoltageLimit"] = 3.0
cycling_protocol["UpperVoltageLimit"] = 4.0


sim = Simulation(model, cell_parameters, cycling_protocol)

output = solve(sim; accept_invalid = true, info_level = 1)

time = output.time_series["Time"]
voltage = output.time_series["Voltage"]
capacity = output.time_series["CumulativeCapacity"]

csv_file = joinpath(battmo_base, "examples/Experimental/resources/bolay_discharge_data_1.csv")
exp_data = readdlm(csv_file, ',', Float64)
exp_time = exp_data[:, 1]
exp_voltage = exp_data[:, 2]

# Convert simulation time to hours when it is given in seconds.
sim_time_h = maximum(time) > 100.0 ? time ./ 3600.0 : time

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

sim_voltage_on_exp = linear_interpolate(sim_time_h, voltage, exp_time)
valid = .!isnan.(sim_voltage_on_exp)
residual = sim_voltage_on_exp[valid] .- exp_voltage[valid]
rmse = sqrt(mean(residual .^ 2))
mae = mean(abs.(residual))
@info "Comparison against CSV: points=$(count(valid)), RMSE=$(rmse) V, MAE=$(mae) V"

f = Figure(size = (1000, 400))

ax = GLMakie.Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / h",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	sim_time_h,
	voltage;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Simulation",
)

scatterlines!(ax,
	exp_time,
	exp_voltage;
	linewidth = 2,
	markersize = 7,
	marker = :circle,
	color = :tomato,
	label = "Digitized experiment",
)

axislegend()
display(GLMakie.Screen(), f)

# SEI-model validation diagnostics (equation-level).
Fconst = BattMo.FARADAY_CONSTANT
Rconst = BattMo.GAS_CONSTANT
states = output.states
ne_resolution = output.simulation.settings["NegativeElectrodeCoatingGridPoints"]

sei_thickness = states["SEIThickness"][:, 1:ne_resolution]
sei_voltage_drop = states["SEIVoltageDrop"][:, 1:ne_resolution]
phi_s_ne = states["NegativeElectrodeActiveMaterialPotential"][:, 1:ne_resolution]
ocp_ne = states["NegativeElectrodeActiveMaterialOpenCircuitPotential"][:, 1:ne_resolution]
temp_ne = states["NegativeElectrodeActiveMaterialTemperature"][:, 1:ne_resolution]

elyte_potential = states["ElectrolytePotential"]
ne_elyte_cells = min(ne_resolution, size(elyte_potential, 2))
phi_e_ne = elyte_potential[:, 1:ne_elyte_cells]

if ne_elyte_cells != ne_resolution
	@warn "Electrolyte potential has fewer cells than negative electrode. Truncating SEI diagnostics to $(ne_elyte_cells) cells."
	sei_thickness = sei_thickness[:, 1:ne_elyte_cells]
	sei_voltage_drop = sei_voltage_drop[:, 1:ne_elyte_cells]
	phi_s_ne = phi_s_ne[:, 1:ne_elyte_cells]
	ocp_ne = ocp_ne[:, 1:ne_elyte_cells]
	temp_ne = temp_ne[:, 1:ne_elyte_cells]
end

mean_over_ne(x) = vec(mean(x, dims = 2))

function time_derivative(y::AbstractVector, t::AbstractVector)
	n = length(y)
	dy = zeros(eltype(y), n)
	if n < 2
		return dy
	end
	dy[1] = (y[2] - y[1]) / (t[2] - t[1])
	for i in 2:(n-1)
		dy[i] = (y[i+1] - y[i-1]) / (t[i+1] - t[i-1])
	end
	dy[end] = (y[end] - y[end-1]) / (t[end] - t[end-1])
	return dy
end

eta_sei = phi_s_ne .- phi_e_ne .- sei_voltage_drop
eta_bv = phi_s_ne .- phi_e_ne .- ocp_ne .- sei_voltage_drop

interphase = cell_parameters["NegativeElectrode"]["Interphase"]
ssei = interphase["StoichiometricCoefficient"]
Vsei = interphase["MolarVolume"]
De = interphase["ElectronicDiffusionCoefficient"]
ce0 = interphase["InterstitialConcentration"]

# Reconstruct model flux N exactly as implemented in src/models/sei_layer.jl.
transport_factor = De .* ce0 ./ sei_thickness
activation_factor = exp.(-(Fconst ./ (Rconst .* temp_ne)) .* eta_sei)
drop_correction_factor = 1 .- (Fconst ./ (2 * Rconst .* temp_ne)) .* sei_voltage_drop
N_model = transport_factor .* activation_factor .* drop_correction_factor

# Validate growth equation: (s/V) dL/dt = N
nt, nc = size(sei_thickness)
dLdt = zeros(size(sei_thickness))
for j in 1:nc
	dLdt[:, j] = time_derivative(view(sei_thickness, :, j), time)
end
growth_lhs = (ssei / Vsei) .* dLdt
growth_rhs = N_model
growth_residual = growth_lhs .- growth_rhs

L_mean = mean_over_ne(sei_thickness)
U_mean = mean_over_ne(sei_voltage_drop)
lhs_mean = mean_over_ne(growth_lhs)
rhs_mean = mean_over_ne(growth_rhs)
res_mean = mean_over_ne(growth_residual)
abs_rel_res = mean_over_ne(abs.(growth_residual) ./ (abs.(growth_rhs) .+ eps()))

ΔL = diff(L_mean)
frac_non_decreasing = count(>=(0.0), ΔL) / max(length(ΔL), 1)
rmse_growth = sqrt(mean((lhs_mean .- rhs_mean) .^ 2))
mae_growth = mean(abs.(lhs_mean .- rhs_mean))

@info "SEI growth-law validation (mean over NE cells)" rmse_growth mae_growth frac_non_decreasing

f_sei = Figure(size = (1400, 450))

ax_grow = GLMakie.Axis(
	f_sei[1, 1],
	title = "SEI Growth Law Check",
	xlabel = "Time / h",
	ylabel = "Flux-equivalent",
)
lines!(ax_grow, sim_time_h, lhs_mean; linewidth = 2.5, color = :black, label = "(s/V) dL/dt")
lines!(ax_grow, sim_time_h, rhs_mean; linewidth = 2.5, color = :green4, label = "N_model")
axislegend(ax_grow, position = :lt)

ax_res = GLMakie.Axis(
	f_sei[1, 2],
	title = "Growth-Law Relative Residual",
	xlabel = "Time / h",
	ylabel = "mean |LHS-RHS|/(|RHS|+eps)",
)
lines!(ax_res, sim_time_h, abs_rel_res; linewidth = 2.5, color = :orange)

ax_state = GLMakie.Axis(
	f_sei[1, 3],
	title = "Mean SEI Thickness",
	xlabel = "Time / h",
	ylabel = "L_sei / nm",
)
lines!(ax_state, sim_time_h, L_mean .* 1e9; linewidth = 2.5, color = :dodgerblue)

display(GLMakie.Screen(), f_sei)

# Compare SEI growth for separate CC discharge / CC charge protocols.
drates = [0.2, 1 / 3, 0.5, 1.0]

function run_cc_rate_sweep(protocol_name::String, rates::Vector{Float64})
	curves = Dict{
		Float64,
		NamedTuple{(:time_h, :L_nm, :U_sei, :eta_sei, :N_model), Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}}},
	}()
	for rate in rates
		cp_i = deepcopy(cell_parameters)
		cyc_i = load_cycling_protocol(; from_default_set = protocol_name)
		cyc_i["InitialTemperature"] = get(cycling_protocol, "InitialTemperature", 298.15)
		if protocol_name == "cc_discharge"
			cyc_i["InitialStateOfCharge"] = 0.99
			cyc_i["DRate"] = rate
		else
			cyc_i["InitialStateOfCharge"] = 0.01
			cyc_i["CRate"] = rate
		end

		sim_i = Simulation(model, cp_i, cyc_i)
		local out_i
		try
			out_i = solve(sim_i; accept_invalid = true, info_level = -1, error_on_incomplete = false)
		catch err
			@warn "Skipping rate case due solver/output error" protocol = protocol_name rate exception = err
			continue
		end
		if !hasproperty(out_i, :states) || isempty(out_i.states)
			@warn "Skipping rate case with empty state history" protocol = protocol_name rate
			continue
		end

		t_i = out_i.time_series["Time"]
		t_h_i = maximum(t_i) > 100.0 ? t_i ./ 3600.0 : t_i
		ne_i = out_i.simulation.settings["NegativeElectrodeCoatingGridPoints"]
		st_i = out_i.states
		L_i = st_i["SEIThickness"][:, 1:ne_i]
		U_i = st_i["SEIVoltageDrop"][:, 1:ne_i]
		phi_s_i = st_i["NegativeElectrodeActiveMaterialPotential"][:, 1:ne_i]
		T_i = st_i["NegativeElectrodeActiveMaterialTemperature"][:, 1:ne_i]
		phi_e_full_i = st_i["ElectrolytePotential"]
		ne_elyte_i = min(ne_i, size(phi_e_full_i, 2))
		phi_e_i = phi_e_full_i[:, 1:ne_elyte_i]

		if ne_elyte_i != ne_i
			L_i = L_i[:, 1:ne_elyte_i]
			U_i = U_i[:, 1:ne_elyte_i]
			phi_s_i = phi_s_i[:, 1:ne_elyte_i]
			T_i = T_i[:, 1:ne_elyte_i]
		end

		eta_sei_i = phi_s_i .- phi_e_i .- U_i
		transport_i = De .* ce0 ./ L_i
		activation_i = exp.(-(Fconst ./ (Rconst .* T_i)) .* eta_sei_i)
		drop_corr_i = 1 .- (Fconst ./ (2 * Rconst .* T_i)) .* U_i
		N_i = transport_i .* activation_i .* drop_corr_i

		curves[rate] = (
			time_h = t_h_i,
			L_nm = vec(mean(L_i, dims = 2)) .* 1e9,
			U_sei = vec(mean(U_i, dims = 2)),
			eta_sei = vec(mean(eta_sei_i, dims = 2)),
			N_model = vec(mean(N_i, dims = 2)),
		)
	end
	return curves
end

function plot_rate_curves(curves, rates, title_suffix)
	available_rates = [r for r in rates if haskey(curves, r)]
	if isempty(available_rates)
		error("No valid rate cases produced output states for $title_suffix sweep.")
	end
	fig = Figure(size = (1850, 450))
	ax_L = GLMakie.Axis(fig[1, 1], title = "Mean SEI Thickness ($title_suffix)", xlabel = "Time / h", ylabel = "Mean SEI thickness / nm")
	ax_U = GLMakie.Axis(fig[1, 2], title = "Mean U_sei ($title_suffix)", xlabel = "Time / h", ylabel = "U_sei / V")
	ax_eta = GLMakie.Axis(fig[1, 3], title = "Mean eta_sei ($title_suffix)", xlabel = "Time / h", ylabel = "eta_sei / V")
	ax_N = GLMakie.Axis(fig[1, 4], title = "Mean N ($title_suffix)", xlabel = "Time / h", ylabel = "N (mean)")
	for rate in available_rates
		curve = curves[rate]
		label = "Rate = $(round(rate, digits = 3))C"
		lines!(ax_L, curve.time_h, curve.L_nm; linewidth = 2.5, label = label)
		lines!(ax_U, curve.time_h, curve.U_sei; linewidth = 2.5, label = label)
		lines!(ax_eta, curve.time_h, curve.eta_sei; linewidth = 2.5, label = label)
		lines!(ax_N, curve.time_h, curve.N_model; linewidth = 2.5, label = label)
	end
	axislegend(ax_L, position = :lt)
	axislegend(ax_U, position = :lt)
	axislegend(ax_eta, position = :lt)
	axislegend(ax_N, position = :lt)
	return fig
end

curves_discharge = run_cc_rate_sweep("cc_discharge", drates)
curves_charge = run_cc_rate_sweep("cc_charge", drates)

f_cc_discharge = plot_rate_curves(curves_discharge, drates, "CC Discharge")
f_cc_charge = plot_rate_curves(curves_charge, drates, "CC Charge")

display(GLMakie.Screen(), f_cc_discharge)
display(GLMakie.Screen(), f_cc_charge)

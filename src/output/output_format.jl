export get_output_time_series, get_output_metrics, get_output_states, compute_voltage_breakdown

# for debugging
export extract_time_series_data, extract_output_times, get_multimodel_centroids, extract_spatial_data, get_simple_output

"""
	get_output_time_series(output::NamedTuple; quantities::Union{Nothing, Vector{String}} = nothing)

Extracts selected time-series data (e.g., voltage, current, time) from a simulation output.

# Arguments
- `output::NamedTuple`: The simulation result, typically produced by `solve_simulation`, containing computed states and metadata.
- `quantities::Union{Nothing, Vector{String}}` (optional): A list of quantity names to extract from the output. Supported values include `"Time"`, `"Voltage"`, and `"Current"`. If `nothing` (default), all available quantities are returned.

# Behavior
- Extracts time, voltage, and current data from the simulation output.
- If specific quantities are requested, filters and returns only those.
- Validates requested quantity names against the list of available quantities.
- Returns the selected data as a named tuple of vectors, keyed by quantity name.

# Returns
A `NamedTuple` of selected time-series data, where each entry is a vector of values over time. Possible keys include:
- `:Time`
- `:Voltage`
- `:Current`

# Throws
- An error if an unsupported or unknown quantity name is provided in `quantities`.

# Example
```julia
output = solve_simulation(sim)
ts = get_output_time_series(output; quantities=["Time", "Voltage"])
plot(ts.Time, ts.Voltage)
```
"""
function get_output_time_series(jutul_output::NamedTuple; quantities::Union{Nothing, Vector{String}} = nothing)

	states = jutul_output[:states]

	# Extract data
	voltage, current = extract_time_series_data(jutul_output)
	time = extract_output_times(jutul_output)
	cumulative_capacity = compute_capacity(jutul_output, "Cumulative")
	net_capacity = compute_capacity(jutul_output, "Net")
	cycle_number = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : nothing

	# Available data mapping
	data_map = Dict(
		"Time" => time,
		"Voltage" => voltage,
		"Current" => current,
		"CumulativeCapacity" => cumulative_capacity,
		"NetCapacity" => net_capacity,
	)

	if !isnothing(cycle_number)
		data_map["CycleNumber"] = cycle_number
	end

	if isnothing(quantities)
		# Default: include all
		return data_map
	else
		# Select only requested quantities
		return Dict(q => get(data_map, q, error("Quantity $q is not available")) for q in quantities)
	end
end

function find_nearest_finite_index(values::AbstractVector{<:Real}, target::Int)

	n = length(values)
	if target < 1 || target > n
		error("Target index $target is out of bounds for vector of length $n.")
	end

	if isfinite(values[target])
		return target
	end

	for offset in 1:(n-1)
		left = target - offset
		if left >= 1 && isfinite(values[left])
			return left
		end
		right = target + offset
		if right <= n && isfinite(values[right])
			return right
		end
	end

	error("No finite value found in vector while searching around index $target.")
end

function mean_finite(values::AbstractVector{<:Real})
	sum_finite = 0.0
	n_finite = 0
	for v in values
		if isfinite(v)
			sum_finite += v
			n_finite += 1
		end
	end
	n_finite == 0 && return NaN
	return sum_finite / n_finite
end

function clip_to_finite_magnitude(x::Real; max_abs::Real = 700.0)
	if !isfinite(x)
		return sign(x) * max_abs
	end
	return clamp(x, -max_abs, max_abs)
end

function effective_exchange_current_density(
	R0_vals::AbstractVector{<:Real},
	c_e_vals::AbstractVector{<:Real},
	c_s_vals::AbstractVector{<:Real},
	cmax::Real,
	n::Real,
)
	F = FARADAY_CONSTANT
	nvals = min(length(R0_vals), length(c_e_vals), length(c_s_vals))
	sum_j0 = 0.0
	nj0 = 0
	cmax_loc = max(cmax, 1.0e-12)
	th = 1.0e-3 * cmax_loc
	for k in 1:nvals
		R0 = R0_vals[k]
		ce = c_e_vals[k]
		cs = c_s_vals[k]
		if !(isfinite(R0) && isfinite(ce) && isfinite(cs))
			continue
		end
		ce_loc = max(ce, 0.0)
		cs_loc = clamp(cs, 0.0, cmax_loc)
		term = ce_loc * (cmax_loc - cs_loc) * cs_loc
		if term <= 0
			j0 = 0.0
		elseif term <= th
			j0 = R0 * (term / th) * sqrt(th) * n * F
		else
			j0 = R0 * sqrt(term) * n * F
		end
		if isfinite(j0) && j0 >= 0
			sum_j0 += j0
			nj0 += 1
		end
	end
	nj0 == 0 && return NaN
	return sum_j0 / nj0
end

function effective_net_reaction_overpotential(
	I_cell::Real,
	A_geo::Real,
	vol_surf_area::Real,
	thickness::Real,
	n::Real,
	T::Real,
	j0_eff::Real,
	sign_reference::Real,
)
	if !(isfinite(I_cell) && isfinite(A_geo) && isfinite(vol_surf_area) && isfinite(thickness) && isfinite(n) && isfinite(T) && isfinite(j0_eff))
		return NaN
	end
	if A_geo <= 0 || vol_surf_area <= 0 || thickness <= 0 || n <= 0 || T <= 0 || j0_eff <= 0
		return NaN
	end
	R = GAS_CONSTANT
	F = FARADAY_CONSTANT
	i_geo = I_cell / A_geo
	j_net = abs(i_geo) / (vol_surf_area * thickness)
	argument = clip_to_finite_magnitude(j_net / (2.0 * j0_eff))
	eta_mag = 2.0 * R * T / (n * F) * asinh(argument)
	sgn = sign(sign_reference)
	if sgn == 0
		return 0.0
	end
	return sgn * eta_mag
end

function eval_ocp_from_system(system, c::Real, T::Real)
	params = system.params
	ocp_fun = system[:ocp_func]
	cmax = system[:maximum_concentration]
	refT = 298.15
	c_clamped = clamp(c, 1.0e-12, cmax - 1.0e-12)

	if haskey(params, :ocp_funcconstant)
		return ocp_fun
	elseif haskey(params, :ocp_funcdata)
		return ocp_fun(c_clamped / cmax)
	end

	# Handle several OCP function signatures used across parameter definitions.
	for candidate in (
		() -> ocp_fun(c_clamped, T, refT, cmax),
		() -> ocp_fun(c_clamped, T, cmax),
		() -> ocp_fun(c_clamped, T),
		() -> ocp_fun(c_clamped),
	)
		try
			return candidate()
		catch err
			err isa MethodError || rethrow(err)
		end
	end

	error("Failed to evaluate OCP function for concentration $c_clamped and temperature $T.")
end

"""
	compute_voltage_breakdown(output::SimulationOutput)

Compute an approximate decomposition of terminal voltage into physically meaningful components.

The decomposition is based on interface values and reconstructs:

`Voltage ≈ OCV_avg + η_conc,solid,pos + η_conc,solid,neg + η_pos + η_neg + Δϕ_e,conc + Δϕ_e,ohm + Δϕ_s,pos + Δϕ_s,neg (+ η_SEI) + Residual`

where each term is returned as a time series.
"""
function compute_voltage_breakdown(output::SimulationOutput)

	states = output.states
	time_series = output.time_series

	get_state(name::AbstractString; required::Bool = true) =
		try
			get_nested_output_value(states, output_state_path(String(name)), String(name))
		catch err
			if required
				error("Cannot compute voltage breakdown. Missing output state \"$(String(name))\".")
			end
			if err isa ErrorException
				return nothing
			end
			rethrow(err)
		end

	required = [
		"NegativeElectrodeActiveMaterialPotential",
		"PositiveElectrodeActiveMaterialPotential",
		"ElectrolytePotential",
		"NegativeElectrodeActiveMaterialOpenCircuitPotential",
		"PositiveElectrodeActiveMaterialOpenCircuitPotential",
	]

	for key in required
		get_state(key)
	end

	if !haskey(time_series, "Time") || !haskey(time_series, "Voltage") || !haskey(time_series, "Current")
		error("Cannot compute voltage breakdown. Time-series output must contain \"Time\", \"Voltage\", and \"Current\".")
	end

	phi_n = get_state("NegativeElectrodeActiveMaterialPotential")
	phi_p = get_state("PositiveElectrodeActiveMaterialPotential")
	phi_e = get_state("ElectrolytePotential")
	ocp_n = get_state("NegativeElectrodeActiveMaterialOpenCircuitPotential")
	ocp_p = get_state("PositiveElectrodeActiveMaterialOpenCircuitPotential")
	c_n_surf = get_state("NegativeElectrodeActiveMaterialSurfaceConcentration"; required = false)
	c_p_surf = get_state("PositiveElectrodeActiveMaterialSurfaceConcentration"; required = false)
	R0_n_field = get_state("NegativeElectrodeActiveMaterialReactionRateConstant"; required = false)
	R0_p_field = get_state("PositiveElectrodeActiveMaterialReactionRateConstant"; required = false)
	c_e = get_state("ElectrolyteConcentration"; required = false)
	c_n_part = get_state("NegativeElectrodeActiveMaterialParticleConcentration"; required = false)
	c_p_part = get_state("PositiveElectrodeActiveMaterialParticleConcentration"; required = false)
	T_n = get_state("NegativeElectrodeActiveMaterialTemperature"; required = false)
	T_p = get_state("PositiveElectrodeActiveMaterialTemperature"; required = false)

	nsteps = min(
		length(time_series["Time"]),
		length(time_series["Voltage"]),
		size(phi_n, 1),
		size(phi_p, 1),
		size(phi_e, 1),
		size(ocp_n, 1),
		size(ocp_p, 1),
	)

	if nsteps < 2
		error("Need at least 2 time steps to compute a voltage breakdown.")
	end

	time = time_series["Time"][1:nsteps]
	voltage = time_series["Voltage"][1:nsteps]
	current = time_series["Current"][1:nsteps]

	n_idx = findall(isfinite, phi_n[1, :])
	p_idx = findall(isfinite, phi_p[1, :])

	isempty(n_idx) && error("Negative electrode potential field has no finite entries.")
	isempty(p_idx) && error("Positive electrode potential field has no finite entries.")

	ne_cc_idx = first(n_idx)
	ne_sep_idx = last(n_idx)
	pe_sep_idx = first(p_idx)
	pe_cc_idx = last(p_idx)

	e_ne_idx = find_nearest_finite_index(vec(phi_e[1, :]), ne_sep_idx)
	e_pe_idx = find_nearest_finite_index(vec(phi_e[1, :]), pe_sep_idx)
	e_ne_map = [find_nearest_finite_index(vec(phi_e[1, :]), idx) for idx in n_idx]
	e_pe_map = [find_nearest_finite_index(vec(phi_e[1, :]), idx) for idx in p_idx]

	sei = get_state("NegativeElectrodeInterphaseVoltageDrop"; required = false)
	has_sei = !isnothing(sei)
	sei_idx = has_sei ? find_nearest_finite_index(vec(sei[1, :]), ne_sep_idx) : 0

	ne_system = output.model.multimodel[:NegativeElectrodeActiveMaterial].system
	pe_system = output.model.multimodel[:PositiveElectrodeActiveMaterial].system

	ne_params = ne_system.params
	pe_params = pe_system.params

	a_n = haskey(ne_params, :volumetric_surface_area) ? ne_params[:volumetric_surface_area] : NaN
	a_p = haskey(pe_params, :volumetric_surface_area) ? pe_params[:volumetric_surface_area] : NaN
	n_n = haskey(ne_params, :n_charge_carriers) ? ne_params[:n_charge_carriers] : 1.0
	n_p = haskey(pe_params, :n_charge_carriers) ? pe_params[:n_charge_carriers] : 1.0
	cmax_n = haskey(ne_params, :maximum_concentration) ? ne_params[:maximum_concentration] : NaN
	cmax_p = haskey(pe_params, :maximum_concentration) ? pe_params[:maximum_concentration] : NaN
	bv_ne = haskey(ne_params, :setting_butler_volmer) ? ne_params[:setting_butler_volmer] : nothing
	bv_pe = haskey(pe_params, :setting_butler_volmer) ? pe_params[:setting_butler_volmer] : nothing

	cell_params = output.input["CellParameters"]
	cell_geometry = cell_params["Cell"]
	A_geo = get(cell_geometry, "ElectrodeGeometricSurfaceArea", NaN)
	if !(isfinite(A_geo) && A_geo > 0)
		w = get(cell_geometry, "ElectrodeWidth", NaN)
		l = get(cell_geometry, "ElectrodeLength", get(cell_geometry, "Height", NaN))
		if isfinite(w) && isfinite(l) && w > 0 && l > 0
			A_geo = w * l
		end
	end
	L_n = get(cell_params["NegativeElectrode"]["Coating"], "Thickness", NaN)
	L_p = get(cell_params["PositiveElectrode"]["Coating"], "Thickness", NaN)

	use_net_reactive_kinetics =
		!isnothing(c_e) &&
		!isnothing(c_n_surf) &&
		!isnothing(c_p_surf) &&
		!isnothing(R0_n_field) &&
		!isnothing(R0_p_field) &&
		isfinite(A_geo) &&
		A_geo > 0 &&
		isfinite(a_n) &&
		a_n > 0 &&
		isfinite(a_p) &&
		a_p > 0 &&
		isfinite(L_n) &&
		L_n > 0 &&
		isfinite(L_p) &&
		L_p > 0 &&
		isfinite(cmax_n) &&
		cmax_n > 0 &&
		isfinite(cmax_p) &&
		cmax_p > 0 &&
		(bv_ne != "Chayambuka") &&
		(bv_pe != "Chayambuka")

	t_plus = output.input["CellParameters"]["Electrolyte"]["TransferenceNumber"]
	F = FARADAY_CONSTANT
	R = GAS_CONSTANT

	ocv_surface = zeros(nsteps)
	ocv_average = zeros(nsteps)
	conc_solid_pos = zeros(nsteps)
	conc_solid_neg = zeros(nsteps)
	pos_kin = zeros(nsteps)
	neg_kin = zeros(nsteps)
	elyte_drop_total = zeros(nsteps)
	elyte_conc = zeros(nsteps)
	elyte_ohmic = zeros(nsteps)
	solid_drop_pos = zeros(nsteps)
	solid_drop_neg = zeros(nsteps)
	neg_sei = zeros(nsteps)
	reconstructed = zeros(nsteps)

	for i in 1:nsteps
		phi_n_cc = phi_n[i, ne_cc_idx]
		phi_n_sep = phi_n[i, ne_sep_idx]
		phi_p_sep = phi_p[i, pe_sep_idx]
		phi_p_cc = phi_p[i, pe_cc_idx]

		phi_e_n = phi_e[i, e_ne_idx]
		phi_e_p = phi_e[i, e_pe_idx]

		U_n = ocp_n[i, ne_sep_idx]
		U_p = ocp_p[i, pe_sep_idx]
		ocv_surface[i] = U_p - U_n

		eta_n_total = phi_n_sep - phi_e_n - U_n
		eta_p_total = phi_p_sep - phi_e_p - U_p

		if !isnothing(c_n_part) && !isnothing(c_p_part) && ndims(c_n_part) == 3 && ndims(c_p_part) == 3
			cn_profile = vec(c_n_part[i, ne_sep_idx, :])
			cp_profile = vec(c_p_part[i, pe_sep_idx, :])
			cn_avg = mean_finite(cn_profile)
			cp_avg = mean_finite(cp_profile)

			Tn_loc = isnothing(T_n) ? 298.15 : T_n[i, ne_sep_idx]
			Tp_loc = isnothing(T_p) ? 298.15 : T_p[i, pe_sep_idx]

			U_n_avg = eval_ocp_from_system(ne_system, cn_avg, Tn_loc)
			U_p_avg = eval_ocp_from_system(pe_system, cp_avg, Tp_loc)

			ocv_average[i] = U_p_avg - U_n_avg
			conc_solid_pos[i] = U_p - U_p_avg
			conc_solid_neg[i] = U_n_avg - U_n
		else
			ocv_average[i] = ocv_surface[i]
		end

		local_pos_kin = eta_p_total
		elyte_drop_total[i] = phi_e_p - phi_e_n
		solid_drop_pos[i] = phi_p_cc - phi_p_sep
		solid_drop_neg[i] = phi_n_sep - phi_n_cc

		T_elyte = isnothing(T_n) || isnothing(T_p) ? 298.15 : 0.5 * (T_n[i, ne_sep_idx] + T_p[i, pe_sep_idx])
		if !isnothing(c_e)
			cen = clamp(c_e[i, e_ne_idx], 1.0e-12, Inf)
			cep = clamp(c_e[i, e_pe_idx], 1.0e-12, Inf)
			elyte_conc[i] = 2.0 * R * T_elyte / F * (1.0 - t_plus) * log(cep / cen)
			elyte_ohmic[i] = elyte_drop_total[i] - elyte_conc[i]
		else
			elyte_ohmic[i] = elyte_drop_total[i]
		end

		if has_sei
			sei_u = sei[i, sei_idx]
			neg_sei[i] = -sei_u
			# Keep SEI separate from reaction kinetics in the returned decomposition.
			local_neg_kin = -eta_n_total - neg_sei[i]
		else
			local_neg_kin = -eta_n_total
		end

		if use_net_reactive_kinetics
			Tn_eff = isnothing(T_n) ? 298.15 : mean_finite(vec(T_n[i, n_idx]))
			Tp_eff = isnothing(T_p) ? 298.15 : mean_finite(vec(T_p[i, p_idx]))

			c_e_n_vals = vec(c_e[i, e_ne_map])
			c_e_p_vals = vec(c_e[i, e_pe_map])
			c_s_n_vals = vec(c_n_surf[i, n_idx])
			c_s_p_vals = vec(c_p_surf[i, p_idx])
			R0_n_vals = vec(R0_n_field[i, n_idx])
			R0_p_vals = vec(R0_p_field[i, p_idx])

			j0_eff_n = effective_exchange_current_density(R0_n_vals, c_e_n_vals, c_s_n_vals, cmax_n, n_n)
			j0_eff_p = effective_exchange_current_density(R0_p_vals, c_e_p_vals, c_s_p_vals, cmax_p, n_p)

			eta_neg_eff = effective_net_reaction_overpotential(
				current[i],
				A_geo,
				a_n,
				L_n,
				n_n,
				Tn_eff,
				j0_eff_n,
				local_neg_kin,
			)
			eta_pos_eff = effective_net_reaction_overpotential(
				current[i],
				A_geo,
				a_p,
				L_p,
				n_p,
				Tp_eff,
				j0_eff_p,
				local_pos_kin,
			)

			neg_kin[i] = isfinite(eta_neg_eff) ? eta_neg_eff : local_neg_kin
			pos_kin[i] = isfinite(eta_pos_eff) ? eta_pos_eff : local_pos_kin
		else
			neg_kin[i] = local_neg_kin
			pos_kin[i] = local_pos_kin
		end

		reconstructed[i] = ocv_average[i] + conc_solid_pos[i] + conc_solid_neg[i] + pos_kin[i] + neg_kin[i] + elyte_conc[i] + elyte_ohmic[i] + solid_drop_pos[i] + solid_drop_neg[i] + neg_sei[i]
	end

	residual = voltage .- reconstructed

	breakdown = Dict{String, Any}(
		"Time" => time,
		"Voltage" => voltage,
		"Current" => current,
		"OpenCircuitVoltage" => ocv_average,
		"OpenCircuitVoltageAverage" => ocv_average,
		"OpenCircuitVoltageSurface" => ocv_surface,
		"PositiveSolidConcentrationOverpotential" => conc_solid_pos,
		"NegativeSolidConcentrationOverpotential" => conc_solid_neg,
		"ElectrolyteConcentrationOverpotential" => elyte_conc,
		"PositiveReactionOverpotential" => pos_kin,
		"NegativeReactionOverpotential" => neg_kin,
		"ElectrolytePotentialDrop" => elyte_drop_total,
		"ElectrolyteOhmicPotentialDrop" => elyte_ohmic,
		"PositiveSolidPotentialDrop" => solid_drop_pos,
		"NegativeSolidPotentialDrop" => solid_drop_neg,
		"ReconstructedVoltage" => reconstructed,
		"ResidualVoltage" => residual,
		"KineticOverpotentialMode" => use_net_reactive_kinetics ? "NetReactiveEffective" : "InterfaceLocal",
	)

	if has_sei
		breakdown["NegativeSEIOverpotential"] = neg_sei
	end

	if haskey(time_series, "CumulativeCapacity")
		breakdown["CumulativeCapacity"] = time_series["CumulativeCapacity"][1:nsteps]
	end

	return breakdown
end


"""
	get_output_metrics(output::NamedTuple; metrics::Union{Nothing, Vector{String}} = nothing)

Computes key performance metrics from a battery simulation output, either globally or per cycle, and returns them as a named tuple.

# Arguments
- `output::NamedTuple`: The result of a simulation, typically returned from `solve_simulation`, containing time-series states and metadata.
- `metrics::Union{Nothing, Vector{String}}` (optional): A list of metric names to extract. If `nothing` (default), all available metrics are returned.

# Behavior
- Extracts the model and state history from the output.
- Detects the number of cycles in the simulation via the controller state.
- Computes the following metrics, either globally or per cycle:
  - `DischargeCapacity` (Ah)
  - `ChargeCapacity` (Ah)
  - `DischargeEnergy` (Wh)
  - `ChargeEnergy` (Wh)
  - `RoundTripEfficiency` (%)
- Constructs and returns a dictionary of requested metrics (or all metrics by default).

# Returns
A `NamedTuple` where each field is a vector containing the computed metric values (one value per cycle, or globally if no cycles are detected). Possible fields include:
- `:CycleIndex`
- `:DischargeCapacity`
- `:ChargeCapacity`
- `:DischargeEnergy`
- `:ChargeEnergy`
- `:RoundTripEfficiency`

# Throws
- An error if a requested metric is not recognized or unavailable.
- Errors include a helpful message listing all valid metric names.

# Example
```julia
output = solve_simulation(sim)
metrics = get_output_metrics(output; metrics=["DischargeCapacity", "RoundTripEfficiency"])
plot(metrics.CycleNumber, metrics.DischargeCapacity)
```
"""
function get_output_metrics(
	jutul_output::NamedTuple;
	metrics::Union{Nothing, Vector{String}} = nothing,
)
	states = jutul_output[:states]

	controller = states[1][:Control][:Controller]

	if isa(controller, FunctionController) || isa(controller, InputCurrentController)
		available_quantities = Dict()
	else
		cycle_array = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : nothing

		# Metric storage
		discharge_cap = Float64[]
		charge_cap = Float64[]
		discharge_energy = Float64[]
		charge_energy = Float64[]
		round_trip_efficiency = Float64[]

		# Identify unique non-zero cycles
		unique_cycles = unique(cycle_array)
		cycles_reduced = Int.(unique_cycles[1:(end-1)]) # Exclude last cycle index because it is incomplete


		if isempty(cycles_reduced)
			# Compute globally
			push!(discharge_cap, compute_discharge_capacity(jutul_output))
			push!(charge_cap, compute_charge_capacity(jutul_output))
			push!(discharge_energy, compute_discharge_energy(jutul_output))
			push!(charge_energy, compute_charge_energy(jutul_output))
			push!(round_trip_efficiency, compute_round_trip_efficiency(jutul_output))
		else
			# Compute per unique cycle (avoids duplicate pushes)
			for cycle in cycles_reduced
				push!(discharge_cap, compute_discharge_capacity(jutul_output; cycle_number = cycle))
				push!(charge_cap, compute_charge_capacity(jutul_output; cycle_number = cycle))
				push!(discharge_energy, compute_discharge_energy(jutul_output; cycle_number = cycle))
				push!(charge_energy, compute_charge_energy(jutul_output; cycle_number = cycle))
				push!(round_trip_efficiency, compute_round_trip_efficiency(jutul_output; cycle_number = cycle))
			end
		end

		# Dictionary of all available quantities
		available_quantities = Dict(
			"CycleIndex" => cycles_reduced,
			"DischargeCapacity" => discharge_cap,
			"ChargeCapacity" => charge_cap,
			"DischargeEnergy" => discharge_energy,
			"ChargeEnergy" => charge_energy,
			"RoundTripEfficiency" => round_trip_efficiency,
		)

	end

	# Return only requested metrics or all
	if isnothing(metrics)
		return available_quantities
	else
		return Dict(q => get(available_quantities, q, error("Metric \"$q\" is not available. Available metrics are: $(join(keys(available_quantities), ", "))")))
	end
end


"""
	get_output_states(output::NamedTuple; quantities::Union{Nothing, Vector{String}} = nothing)

Extracts spatially resolved state variables and associated coordinates from a battery simulation `output`.

# Arguments
- `output::NamedTuple`: The simulation result returned from `solve_simulation`, containing time series, model metadata, and padded states.
- `quantities::Union{Nothing, Vector{String}}` (optional): A list of quantity names to extract. If `nothing` (default), all available spatial and coordinate data is returned.

# Behavior
- Retrieves simulation time points and spatial coordinates:
  - `:Time`: Simulation time vector
  - `:Position`: 1D spatial grid along the cell (x-direction)
  - `:NegativeElectrodeActiveMaterialRadius`: Radial coordinate for the negative electrode active material
  - `:PositiveElectrodeActiveMaterialRadius`: Radial coordinate for the positive electrode active material
- Extracts spatially resolved state data (e.g., concentration, potential) using `extract_spatial_data`.
- Filters and returns only requested quantities if `quantities` is specified.
- Ensures returned data is not `nothing`; raises an error if a requested quantity is missing or unavailable.

# Returns
A `NamedTuple` containing the selected spatial quantities and coordinates. Possible keys include:
- `:Time`
- `:Position`
- `:NegativeElectrodeActiveMaterialRadius`
- `:PositiveElectrodeActiveMaterialRadius`
- Additional quantities from `extract_spatial_data`, such as:
  - Concentration profiles
  - Potential distributions
  - Temperature fields, etc.

# Throws
- An error if a requested quantity is unavailable or not present in the extracted state data.

# Example
```julia
output = solve_simulation(sim)
states = get_output_states(output; quantities=["Time", "Position", "ElectrolyteConcentration"])
heatmap(states.Position, states.Time, states.ElectrolyteConcentration)
```
"""
function get_output_states(
	jutul_output::NamedTuple,
	grids,
	input::FullSimulationInput;
	quantities::Union{Nothing, Vector{String}} = nothing,
)
	# Get time and coordinates
	time = extract_output_times(jutul_output)
	r_coords = get_r_coords(input)
	r_ne = r_coords.ne_radii
	r_pe = r_coords.pe_radii

	# Initialize available quantities (consistent key type = String)
	if input["ModelSettings"]["ModelFramework"] == "P2D"
		padded_states = get_padded_states(jutul_output)
		x = get_x_coords(jutul_output.multimodel)
		output_data = extract_spatial_data(padded_states)
		component_positions = get_component_positions_1d(grids)

		available_quantities = Dict{String, Any}(
			"Time" => time,
			"Position" => x,
			"NegativeElectrodeActiveMaterialRadius" => r_ne,
			"PositiveElectrodeActiveMaterialRadius" => r_pe,
		)
		for (k, v) in component_positions
			available_quantities[k] = v
		end

	elseif input["ModelSettings"]["ModelFramework"] == "P4D Pouch" || input["ModelSettings"]["ModelFramework"] == "P4D Cylindrical"
		output_data = extract_spatial_data(jutul_output[:states])

		available_quantities = Dict{String, Any}(
			"Time" => time,
			"NegativeElectrodeActiveMaterialPosition" => BattMoPosition(grids["NegativeElectrodeActiveMaterial"], "NegativeElectrodeActiveMaterial"),
			"PositiveElectrodeActiveMaterialPosition" => BattMoPosition(grids["PositiveElectrodeActiveMaterial"], "PositiveElectrodeActiveMaterial"),
			"NegativeElectrodeCurrentCollectorPosition" => BattMoPosition(grids["NegativeElectrodeCurrentCollector"], "NegativeElectrodeCurrentCollector"),
			"PositiveElectrodeCurrentCollectorPosition" => BattMoPosition(grids["PositiveElectrodeCurrentCollector"], "PositiveElectrodeCurrentCollector"),
			"ElectrolytePosition" => BattMoPosition(grids["Electrolyte"], "Electrolyte"),
			"SeparatorPosition" => BattMoPosition(grids["Separator"], "Separator"),
			"NegativeElectrodeActiveMaterialRadius" => r_ne,
			"PositiveElectrodeActiveMaterialRadius" => r_pe,
		)
	else
		error("Unsupported model framework: $(input["ModelSettings"]["ModelFramework"]). Supported frameworks are: P2D, P4D Pouch, P4D Cylindrical.")
	end

	for (k, v) in output_data
		available_quantities[k] = v
	end

	filtered_quantities = Dict(k => v for (k, v) in available_quantities if !isnothing(v))
	nested_quantities = nest_output_states(filtered_quantities)

	if isnothing(quantities)
		return nested_quantities
	else
		return Dict(q => get_nested_output_value(nested_quantities, output_state_path(q), q) for q in quantities)
	end
end

function get_component_positions_1d(grids)
	component_positions = Dict{String, Any}()

	component_map = Dict(
		"NegativeElectrodeActiveMaterialPosition" => "NegativeElectrode",
		"PositiveElectrodeActiveMaterialPosition" => "PositiveElectrode",
		"ElectrolytePosition" => "Electrolyte",
		"SeparatorPosition" => "Separator",
	)

	if haskey(grids, "NegativeCurrentCollector")
		component_map["NegativeElectrodeCurrentCollectorPosition"] = "NegativeCurrentCollector"
	end
	if haskey(grids, "PositiveCurrentCollector")
		component_map["PositiveElectrodeCurrentCollectorPosition"] = "PositiveCurrentCollector"
	end

	for (output_name, grid_name) in component_map
		if haskey(grids, grid_name)
			component_positions[output_name] = get_grid_x_coords(grids[grid_name])
		end
	end

	return component_positions
end

function get_grid_x_coords(grid)
	pp = physical_representation(grid)
	primitives = Jutul.plot_primitives(pp, :meshscatter)
	return primitives.points[:, 1]
end

function nest_output_states(flat_quantities::AbstractDict{String, <:Any})
	nested = Dict{String, Any}()

	for (key, value) in flat_quantities
		path = output_state_path(key)
		set_nested_output_value!(nested, path, value)
	end

	return nested
end

function set_nested_output_value!(dict::Dict{String, Any}, path::Vector{String}, value)
	current = dict
	for key in path[1:(end-1)]
		current = get!(() -> Dict{String, Any}(), current, key)
	end
	current[path[end]] = value
	return dict
end

function get_nested_output_value(dict::Dict{String, Any}, path::Vector{String}, name::String)
	value = dict
	for key in path
		if value isa AbstractDict{String, Any} && haskey(value, key)
			value = value[key]
		else
			error("Metric \"$name\" is not available.")
		end
	end
	return value
end

function output_state_path(key::String)
	if key == "Time"
		return ["Time"]
	elseif key == "Position"
		return ["Cell", "Position"]
	elseif key == "NegativeElectrodeActiveMaterialRadius"
		return ["NegativeElectrode", "ActiveMaterial", "Radius"]
	elseif key == "PositiveElectrodeActiveMaterialRadius"
		return ["PositiveElectrode", "ActiveMaterial", "Radius"]
	elseif key == "NegativeElectrodeInterphaseThickness" || key == "SEIThickness"
		return ["NegativeElectrode", "Interphase", "Thickness"]
	elseif key == "NegativeElectrodeInterphaseNormalizedThickness" || key == "NormalizedSEIThickness"
		return ["NegativeElectrode", "Interphase", "NormalizedThickness"]
	elseif key == "NegativeElectrodeInterphaseVoltageDrop" || key == "SEIVoltageDrop"
		return ["NegativeElectrode", "Interphase", "VoltageDrop"]
	elseif key == "NegativeElectrodeInterphaseNormalizedVoltageDrop" || key == "NormalizedSEIVoltageDrop"
		return ["NegativeElectrode", "Interphase", "NormalizedVoltageDrop"]
	end

	active_material_prefixes = [
		("NegativeElectrodeActiveMaterial", ["NegativeElectrode", "ActiveMaterial"]),
		("PositiveElectrodeActiveMaterial", ["PositiveElectrode", "ActiveMaterial"]),
	]
	for (prefix, path_prefix) in active_material_prefixes
		if startswith(key, prefix)
			suffix = key[(length(prefix)+1):end]
			return vcat(path_prefix, [suffix])
		end
	end

	current_collector_prefixes = [
		("NegativeElectrodeCurrentCollector", ["NegativeElectrode", "CurrentCollector"]),
		("PositiveElectrodeCurrentCollector", ["PositiveElectrode", "CurrentCollector"]),
	]
	for (prefix, path_prefix) in current_collector_prefixes
		if startswith(key, prefix)
			suffix = key[(length(prefix)+1):end]
			return vcat(path_prefix, [suffix])
		end
	end

	if startswith(key, "Electrolyte")
		suffix = key[(length("Electrolyte")+1):end]
		return ["Electrolyte", suffix]
	elseif startswith(key, "Separator")
		suffix = key[(length("Separator")+1):end]
		return ["Separator", suffix]
	else
		return [key]
	end
end


function get_r_coords(input::FullSimulationInput)

	particle_radius_ne = input["CellParameters"]["NegativeElectrode"]["ActiveMaterial"]["ParticleRadius"]
	number_of_cells_ne = input["SimulationSettings"]["NegativeElectrodeParticleGridPoints"]
	particle_radius_pe = input["CellParameters"]["PositiveElectrode"]["ActiveMaterial"]["ParticleRadius"]
	number_of_cells_pe = input["SimulationSettings"]["PositiveElectrodeParticleGridPoints"]

	ne_radii = range(0; stop = particle_radius_ne, length = number_of_cells_ne)
	pe_radii = range(0; stop = particle_radius_pe, length = number_of_cells_pe)
	return (ne_radii = ne_radii, pe_radii = pe_radii)

end


function extract_spatial_data(states::Vector)
	# Map from quantity names to symbol chains used to extract data
	var_map = Dict(
		"NegativeElectrodeActiveMaterialSurfaceConcentration" => [:NegativeElectrodeActiveMaterial, :SurfaceConcentration],
		"PositiveElectrodeActiveMaterialSurfaceConcentration" => [:PositiveElectrodeActiveMaterial, :SurfaceConcentration],
		"NegativeElectrodeActiveMaterialParticleConcentration" => [:NegativeElectrodeActiveMaterial, :ParticleConcentration],
		"PositiveElectrodeActiveMaterialParticleConcentration" => [:PositiveElectrodeActiveMaterial, :ParticleConcentration],
		"NegativeElectrodeActiveMaterialDiffusionCoefficient" => [:NegativeElectrodeActiveMaterial, :DiffusionCoefficient],
		"PositiveElectrodeActiveMaterialDiffusionCoefficient" => [:PositiveElectrodeActiveMaterial, :DiffusionCoefficient],
		"NegativeElectrodeActiveMaterialReactionRateConstant" => [:NegativeElectrodeActiveMaterial, :ReactionRateConstant],
		"PositiveElectrodeActiveMaterialReactionRateConstant" => [:PositiveElectrodeActiveMaterial, :ReactionRateConstant],
		"ElectrolyteConcentration" => [:Electrolyte, :ElectrolyteConcentration],
		"NegativeElectrodeActiveMaterialPotential" => [:NegativeElectrodeActiveMaterial, :ElectricPotential],
		"NegativeElectrodeCurrentCollectorPotential" => [:NegativeElectrodeCurrentCollector, :ElectricPotential],
		"ElectrolytePotential" => [:Electrolyte, :ElectricPotential],
		"PositiveElectrodeActiveMaterialPotential" => [:PositiveElectrodeActiveMaterial, :ElectricPotential],
		"PositiveElectrodeCurrentCollectorPotential" => [:PositiveElectrodeCurrentCollector, :ElectricPotential],
		"NegativeElectrodeActiveMaterialTemperature" => [:NegativeElectrodeActiveMaterial, :Temperature],
		"PositiveElectrodeActiveMaterialTemperature" => [:PositiveElectrodeActiveMaterial, :Temperature],
		"NegativeElectrodeActiveMaterialOpenCircuitPotential" => [:NegativeElectrodeActiveMaterial, :OpenCircuitPotential],
		"PositiveElectrodeActiveMaterialOpenCircuitPotential" => [:PositiveElectrodeActiveMaterial, :OpenCircuitPotential],
		"NegativeElectrodeActiveMaterialCharge" => [:NegativeElectrodeActiveMaterial, :Charge],
		"NegativeElectrodeCurrentCollectorCharge" => [:NegativeElectrodeCurrentCollector, :Charge],
		"ElectrolyteCharge" => [:Electrolyte, :Charge],
		"PositiveElectrodeActiveMaterialCharge" => [:PositiveElectrodeActiveMaterial, :Charge],
		"PositiveElectrodeCurrentCollectorCharge" => [:PositiveElectrodeCurrentCollector, :Charge],
		"ElectrolyteMass" => [:Electrolyte, :Mass],
		"ElectrolyteDiffusivity" => [:Electrolyte, :Diffusivity],
		"ElectrolyteConductivity" => [:Electrolyte, :Conductivity],
		"NegativeElectrodeInterphaseThickness" => [:NegativeElectrodeActiveMaterial, :SEIThickness],
		"NegativeElectrodeInterphaseNormalizedThickness" => [:NegativeElectrodeActiveMaterial, :NormalizedSEIThickness],
		"NegativeElectrodeInterphaseVoltageDrop" => [:NegativeElectrodeActiveMaterial, :SEIVoltageDrop],
		"NegativeElectrodeInterphaseNormalizedVoltageDrop" => [:NegativeElectrodeActiveMaterial, :NormalizedSEIVoltageDrop],
		"SEIThickness" => [:NegativeElectrodeActiveMaterial, :SEIThickness],
		"NormalizedSEIThickness" => [:NegativeElectrodeActiveMaterial, :NormalizedSEIThickness],
		"SEIVoltageDrop" => [:NegativeElectrodeActiveMaterial, :SEIVoltageDrop],
		"NormalizedSEIVoltageDrop" => [:NegativeElectrodeActiveMaterial, :NormalizedSEIVoltageDrop],
	)

	output_data = Dict{String, Any}()

	for q in keys(var_map)

		# Validate if the quantity exists in the known map
		@assert haskey(var_map, q) "Quantity \"$q\" is not a valid or supported variable."

		# Check if the variable actually exists in the first state
		chain = var_map[q]
		try
			_ = foldl(getindex, chain; init = states[1])
		catch
			# Skip quantity if not available
			continue
		end


		# Extract one sample to determine shape

		sample = foldl(getindex, chain; init = states[1])
		nt = length(states)
		sample_dims = size(sample)
		nd = ndims(sample)

		# Preallocate array with shape (nt, ...)
		data = Array{eltype(sample)}(undef, (nt, sample_dims...))

		# Fill the array using appropriate slicing
		for (i, state) in enumerate(states)
			value = foldl(getindex, chain; init = state)

			if nd == 0
				data[i] = value
			elseif nd == 1
				data[i, :] = value
			elseif nd == 2
				data[i, :, :] = value
			else
				error("Unsupported number of dimensions: $nd")
			end
		end


		if nd == 2
			perm = (1, reverse(2:(nd+1))...)  # Keep time as first dim, reverse the rest
			data = permutedims(data, perm)
		end

		if size(data, 2) == 1
			output_data[q] = dropdims(data; dims = 2)
		else
			output_data[q] = data
		end
	end


	return output_data
end


function get_x_coords(model::MultiModel{:IntercalationBattery})

	pp = physical_representation(model.models[:Electrolyte].data_domain)
	primitives = Jutul.plot_primitives(pp, :meshscatter)

	return primitives.points[:, 1]
end

function get_padded_states(jutul_output::NamedTuple)
	multimodel = jutul_output.multimodel
	states = jutul_output[:states]
	supported_model_keys = (
		:NegativeElectrodeCurrentCollector,
		:NegativeElectrodeActiveMaterial,
		:Electrolyte,
		:PositiveElectrodeActiveMaterial,
		:PositiveElectrodeCurrentCollector,
	)
	model_keys = [k for k in supported_model_keys if haskey(multimodel.models, k)]

	n = length(model_keys)
	ncells = Dict{Symbol, Any}()
	active = BitArray(undef, n)
	active .= false
	total_number_of_cells = 0
	for (i, k) in enumerate(model_keys)
		pp = physical_representation(multimodel[k].data_domain)
		if pp isa CurrentAndVoltageDomain
			keep = false
		else
			gg = multimodel[k].domain.representation
			nc = maximum(size(gg[:volumes]))
			ncells[k] = nc
			keep = true
		end
		active[i] = keep
	end
	model_keys = model_keys[active]

	# Setup some dicts
	padded_state = Dict{Symbol, Any}()
	start_idx = Dict{Symbol, Int}()
	end_idx = Dict{Symbol, Int}()
	for k in model_keys
		padded_state[k] = Dict{Symbol, Any}()
	end

	# Get start indices
	# mykeys = [:NegativeElectrodeCurrentCollector, :NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial, :PositiveElectrodeCurrentCollector]
	if :NegativeElectrodeCurrentCollector in model_keys
		start_idx[:NegativeElectrodeCurrentCollector] = 1
		start_idx[:NegativeElectrodeActiveMaterial] = ncells[:NegativeElectrodeCurrentCollector] + 1
	else
		start_idx[:NegativeElectrodeActiveMaterial] = 1
	end

	start_idx[:Electrolyte] = start_idx[:NegativeElectrodeActiveMaterial]
	start_idx[:PositiveElectrodeActiveMaterial] = ncells[:Electrolyte] - ncells[:PositiveElectrodeActiveMaterial] + 1

	if :PositiveElectrodeCurrentCollector in model_keys
		start_idx[:PositiveElectrodeCurrentCollector] = ncells[:Electrolyte] + 1
	end

	for k in model_keys
		end_idx[k] = start_idx[k] + ncells[k] - 1
	end


	total_number_of_cells = maximum(values(end_idx))

	padded_states = Vector{Any}(undef, size(states))
	# Find all possible state fields

	for (i, state) in enumerate(states)
		padded_state = Dict{Symbol, Any}()
		for model_key in model_keys
			nc = ncells[model_key]
			padded_model_state = Dict{Symbol, Any}()
			for (k, v) in state[model_key]
				valid_vector = v isa AbstractVector && length(v) == nc
				valid_matrix = v isa AbstractMatrix && size(v, 2) == nc

				if valid_vector
					data = zeros(total_number_of_cells)
					data .= NaN
					data[start_idx[model_key]:end_idx[model_key]] = state[model_key][k]
				elseif valid_matrix
					data = zeros(size(v, 1), total_number_of_cells)
					data .= NaN
					data[:, start_idx[model_key]:end_idx[model_key]] = state[model_key][k]
				end

				padded_model_state[k] = data
			end
			padded_state[model_key] = padded_model_state
		end

		padded_states[i] = padded_state
	end
	return padded_states

end

function extract_time_series_data(jutul_output::NamedTuple)

	states = jutul_output[:states]


	E = [state[:Control][:ElectricPotential][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	#time_series_data = Dict{String, Vector{Float64}}("voltage" => E, "current" => I)

	return (voltage = E, current = I)

end


function extract_output_times(jutul_output::NamedTuple)

	states = jutul_output[:states]
	t = [state[:Control][:Controller].time for state in states]

	return (time = t)

end

function get_model_coords(model_part::SimulationModel)
	# Get the grid wrap for the model part
	grid_wrap = physical_representation(model_part)

	# Extract the centroids of the cells and boundaries
	centroids_cells = grid_wrap[:cell_centroids, Cells()]
	centroids_boundaries = grid_wrap[:boundary_centroids, BoundaryFaces()]


	# Return the coordinates as a tuple
	cell_centroids = (x = centroids_cells[1, :], y = centroids_cells[2, :], z = centroids_cells[3, :])
	face_centroids = (x = centroids_boundaries[1, :], y = centroids_boundaries[2, :], z = centroids_boundaries[3, :])

	return (cells = cell_centroids, faces = face_centroids)

end

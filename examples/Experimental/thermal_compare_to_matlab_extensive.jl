using BattMo, GLMakie, MAT, Jutul, Statistics

###############################################
# MATLAB data

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/run_only_thermal.mat")

file = matopen(fn)
data = read(file)
close(file)

t_matlab_full = data["time"][:, 1]
t_matlab = t_matlab_full[1:(end-1)]
E_matlab = data["E"][:, 1][1:(end-1)]
sources_matlab = data["sourceTerms"]

# helper function to convert matlab cells to matrix
function convert_matlab_cells_to_matrix(cells)
	outer = vec(cells)
	vectors = [vec(inner[:, 1]) for inner in outer]
	M = reduce(hcat, vectors)
	return permutedims(M)
end

M = convert_matlab_cells_to_matrix(sources_matlab)
t_source_ref = length(t_matlab_full) == size(M, 1) ? t_matlab_full : t_matlab

# Toggle use of MATLAB-retrieved quantities in Julia.
use_matlab_effective_thermal_vectors = false
use_matlab_boundary_overrides = false
use_matlab_source_terms = true
function get_matlab_effective_thermal_vectors(data, nc)
	cap_keys = ["effectiveVolumetricHeatCapacity", "EffectiveVolumetricHeatCapacity"]
	cond_keys = ["effectiveThermalConductivity", "EffectiveThermalConductivity"]

	cap_vec = nothing
	for k in cap_keys
		if haskey(data, k)
			cap_vec = vec(data[k])
			break
		end
	end

	cond_vec = nothing
	for k in cond_keys
		if haskey(data, k)
			cond_vec = vec(data[k])
			break
		end
	end

	if !isnothing(cap_vec) && length(cap_vec) != nc
		cap_vec = nothing
	end
	if !isnothing(cond_vec) && length(cond_vec) != nc
		cond_vec = nothing
	end

	return (cap_vec = cap_vec, cond_vec = cond_vec)
end

function maybe_apply_matlab_effective_thermal_properties!(thermal_parameters, data, nc)
	eff = get_matlab_effective_thermal_vectors(data, nc)

	cap_vec = eff.cap_vec
	cond_vec = eff.cond_vec

	used = false
	if !isnothing(cap_vec)
		thermal_parameters[:Capacity] .= cap_vec
		used = true
	end
	if !isnothing(cond_vec)
		thermal_parameters[:ElectronicConductivity] .= cond_vec
		used = true
	end

	if used
		println("Applied MATLAB effective thermal vectors from .mat file.")
	else
		cap_len = isnothing(cap_vec) ? "missing/size-mismatch" : string(length(cap_vec))
		cond_len = isnothing(cond_vec) ? "missing/size-mismatch" : string(length(cond_vec))
		println("No compatible MATLAB effective thermal vectors found in .mat file; using current Julia thermal parameters.")
		println("  effectiveVolumetricHeatCapacity length: $cap_len")
		println("  effectiveThermalConductivity length: $cond_len")
	end

	return (applied = used, cap_vec = cap_vec, cond_vec = cond_vec)
end

function maybe_apply_matlab_boundary_override!(thermal_model, thermal_parameters, data, h_nominal)
	rep = thermal_model.domain.representation
	if !(haskey(data, "thermalBoundaryNeighbors") && haskey(data, "thermalBoundaryAreas"))
		println("No MATLAB boundary override arrays found in .mat file.")
		return false
	end
	nb = vec(data["thermalBoundaryNeighbors"])
	ba = vec(data["thermalBoundaryAreas"])
	nb_j = rep[:boundary_neighbors]
	ba_j = rep[:boundary_areas]
	if length(nb) != length(nb_j) || length(ba) != length(ba_j)
		println("MATLAB boundary override size mismatch:")
		println("  MATLAB neighbors/areas lengths = $(length(nb)) / $(length(ba))")
		println("  Julia  neighbors/areas lengths = $(length(nb_j)) / $(length(ba_j))")
		return false
	end
	rep[:boundary_neighbors] .= Int.(round.(nb))
	rep[:boundary_areas] .= Float64.(ba)
	thermal_parameters[:ExternalHeatTransferCoefficient] .= h_nominal .* rep[:boundary_areas]
	println("Applied MATLAB boundary overrides (neighbors + areas).")
	return true
end

function interpolate_source_at_time(tq, t_ref, M; pre_first_mode::Symbol = :hold_first)
	if tq < t_ref[1]
		if pre_first_mode == :zero
			return zeros(eltype(M), size(M, 2))
		end
		return vec(M[1, :])
	elseif tq == t_ref[1]
		return vec(M[1, :])
	elseif tq >= t_ref[end]
		return vec(M[end, :])
	else
		i0 = searchsortedlast(t_ref, tq)
		i1 = i0 + 1
		w = (tq - t_ref[i0])/(t_ref[i1] - t_ref[i0])
		return vec((1 - w) .* M[i0, :] .+ w .* M[i1, :])
	end
end

T_max_matlab = Float64[]
for i in eachindex(t_matlab)
	T_matlab = data["states_thermal"][i]["T"]
	push!(T_max_matlab, maximum(vec(T_matlab)))
end

matlab_states = haskey(data, "output_isothermal_states") ? data["output_isothermal_states"] : data["output_isothermal"]["states"]
c_e_matlab = [state["Electrolyte"]["c"] for state in matlab_states]
c_e_clean_matlab = convert_matlab_cells_to_matrix(replace(c_e_matlab, NaN => 0.0))
c_e_av_matlab = vec(mean(c_e_clean_matlab, dims = 2))[1:(end-1)]

###################################################
# Julia data

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
inputparams_material = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = load_advanced_dict_input(fn)
# Match MATLAB runOnlyThermal geometry resolution by default.
# Set this to `true` only when intentionally running a higher-resolution Julia case.
use_custom_geometry_resolution = true
if use_custom_geometry_resolution
	inputparams_geometry["Geometry"]["Nh"] = 16
end

inputparams = merge_input_params([inputparams_material, inputparams_geometry])

# Add control parameters
fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
inputparams_control = load_advanced_dict_input(fn)
inputparams_control["Control"]["lowerCutoffVoltage"] = 3.6
inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

# Add thermal parameters
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = load_advanced_dict_input(fn)
inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

# Add thermal model
inputparams["use_thermal"] = true
external_h_nominal = 0.1
inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = external_h_nominal
# Optional cooling correction for parity tests.
# 1.0 = no correction.
h_correction_factor = 1.0
inputparams["ThermalModel"]["externalHeatTransferCoefficient"] *= h_correction_factor
# Parity test toggle for boundary cooling closure:
# true  => m = 1/(1/(ht*k) + 1/hA) (default BattMo.jl behavior)
# false => m = hA                (direct Robin at cell center)
use_boundary_series_resistance = true
inputparams["ThermalModel"]["useBoundarySeriesResistance"] = use_boundary_series_resistance

output = run_simulation(inputparams; accept_invalid = true)

E = output.time_series["Voltage"]
t = output.time_series["Time"]

input = (
	model_settings      = output.simulation.model.settings,
	cell_parameters     = output.simulation.cell_parameters,
	cycling_protocol    = output.simulation.cycling_protocol,
	simulation_settings = output.simulation.settings,
)

model = output.model
multimodel = model.multimodel
states = output.jutul_output.states
parameters = output.simulation.parameters
grids = output.simulation.grids
maps = output.simulation.global_maps
timesteps = output.simulation.time_steps[1:length(states)]

thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)
nc = number_of_cells(thermal_model.domain)
mat_eff = (applied = false, cap_vec = nothing, cond_vec = nothing)
if use_matlab_effective_thermal_vectors
	mat_eff = maybe_apply_matlab_effective_thermal_properties!(thermal_parameters, data, nc)
else
	println("Skipping MATLAB effective thermal vectors (use_matlab_effective_thermal_vectors = false).")
end
println("Thermal boundary model: use_boundary_series_resistance = ", get(thermal_model.system.params, :use_boundary_series_resistance, true))
println("Applied h_correction_factor = ", h_correction_factor)
h_nominal = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]
if use_matlab_boundary_overrides
	maybe_apply_matlab_boundary_override!(thermal_model, thermal_parameters, data, h_nominal)
else
	println("Skipping MATLAB boundary overrides (use_matlab_boundary_overrides = false).")
end

use_matlab_interpolated_sources = use_matlab_source_terms
# Parity controls:
# - source_time_alignment: :left, :mid, :right, :average
# - source_row_shift: integer shift for direct row indexing when not interpolating.
source_time_alignment = :left
source_row_shift = -1
source_pre_first_mode = :zero
sources = []
src_matric = []

matlab_source_compatible = (size(M, 2) == nc)
if !matlab_source_compatible
	println("MATLAB source vectors are not compatible with this Julia thermal grid:")
	println("  MATLAB source vector length = $(size(M, 2))")
	println("  Julia thermal cell count    = $nc")
	println("Falling back to Julia sources for thermal forcing.")
	println("  (use_matlab_source_terms = $(use_matlab_source_terms), compatible = $(matlab_source_compatible))")
	use_matlab_interpolated_sources = false
end
if !use_matlab_interpolated_sources && matlab_source_compatible
	println("Using Julia-computed source terms (use_matlab_source_terms = false).")
end

for state in states
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source_by_type!(thermal_model, model, state, maps)
	push!(sources, stepsources)
	push!(src_matric, src)
end

function choose_source_times(t_end, t_ref, alignment::Symbol)
	t_prev = vcat(0.0, t_end[1:(end-1)])
	t_mid = 0.5 .* (t_prev .+ t_end)
	if alignment == :left
		return t_prev
	elseif alignment == :mid
		return t_mid
	elseif alignment == :right
		return t_end
	elseif alignment == :average
		# Point-based fallback for diagnostics that still ask for a single time per step.
		# The actual :average forcing path uses make_forces_step_average.
		return t_mid
	else
		error("Unknown source_time_alignment = $alignment. Use :left, :mid, :right, or :average.")
	end
end

function make_forces_interpolated(t_eval, t_ref, M; pre_first_mode::Symbol = :hold_first)
	return [(value = interpolate_source_at_time(te, t_ref, M; pre_first_mode = pre_first_mode),) for te in t_eval]
end

function source_average_over_interval(t0, t1, t_ref, M; pre_first_mode::Symbol = :hold_first)
	if t1 <= t0
		return interpolate_source_at_time(t1, t_ref, M; pre_first_mode = pre_first_mode)
	end
	# Break at all source knots inside the interval and integrate piecewise linearly.
	knots = t_ref[(t_ref .> t0) .& (t_ref .< t1)]
	pts = vcat(t0, knots, t1)
	vals = [interpolate_source_at_time(tp, t_ref, M; pre_first_mode = pre_first_mode) for tp in pts]
	intv = zeros(Float64, size(M, 2))
	for j in 2:length(pts)
		dt = pts[j] - pts[j-1]
		intv .+= 0.5 .* dt .* (vals[j] .+ vals[j-1])
	end
	return intv ./ (t1 - t0)
end

function make_forces_step_average(t_end, t_ref, M; pre_first_mode::Symbol = :hold_first)
	t_prev = vcat(0.0, t_end[1:(end-1)])
	forces_loc = Vector{NamedTuple{(:value,), Tuple{Vector{Float64}}}}(undef, length(t_end))
	for i in eachindex(t_end)
		qavg = source_average_over_interval(t_prev[i], t_end[i], t_ref, M; pre_first_mode = pre_first_mode)
		forces_loc[i] = (value = qavg,)
	end
	return forces_loc
end

function make_forces_from_source_rows(M, nsteps; row_shift = 0)
	nrows = size(M, 1)
	forces_loc = Vector{NamedTuple{(:value,), Tuple{Vector{Float64}}}}(undef, nsteps)
	for i in 1:nsteps
		r = clamp(i + row_shift, 1, nrows)
		forces_loc[i] = (value = vec(M[r, :]),)
	end
	return forces_loc
end

forces = NamedTuple[]
if use_matlab_interpolated_sources
	if source_time_alignment == :average
		forces = make_forces_step_average(t, t_source_ref, M; pre_first_mode = source_pre_first_mode)
	else
		t_eval_julia = choose_source_times(t, t_matlab, source_time_alignment)
		forces = make_forces_interpolated(t_eval_julia, t_source_ref, M; pre_first_mode = source_pre_first_mode)
	end
else
	for src in src_matric
		push!(forces, (value = src,))
	end
end

src_matrix = reduce(vcat, (x' for x in src_matric))
if size(src_matrix, 1) == size(M, 1)-1 && size(src_matrix, 2) == size(M, 2)
	diff_sources = src_matrix - M[1:(end-1), :]
else
	diff_sources = nothing
	println("Skipping direct source-matrix subtraction due to shape mismatch:")
	println("  Julia source matrix size = $(size(src_matrix))")
	println("  MATLAB source matrix size = $(size(M))")
end

T0 = 298.15 * ones(nc)

thermal_state0 = setup_state(thermal_model, Dict(:Temperature => T0))

function run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt, forces)
	sim = Simulator(thermal_model;
		state0 = thermal_state0,
		parameters = thermal_parameters,
		copy_state = true)
	states_loc, = simulate(sim, dt; info_level = -1, forces = forces)
	return states_loc
end

# Run on Julia schedule
thermal_states = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, timesteps, forces)

# Run on MATLAB schedule (mirrors runOnlyThermal.m)
dt_matlab = vcat(t_matlab[1], diff(t_matlab))
t_prev_matlab = vcat(0.0, t_matlab[1:(end-1)])
t_mid_matlab = 0.5 .* (t_prev_matlab .+ t_matlab)
if use_matlab_interpolated_sources
	if source_time_alignment == :average
		forces_matlab_grid = make_forces_step_average(t_matlab, t_source_ref, M; pre_first_mode = source_pre_first_mode)
	else
		t_eval_mat = choose_source_times(t_matlab, t_matlab, source_time_alignment)
		forces_matlab_grid = make_forces_interpolated(t_eval_mat, t_source_ref, M; pre_first_mode = source_pre_first_mode)
	end
else
	forces_matlab_grid = make_forces_from_source_rows(M, length(dt_matlab); row_shift = source_row_shift)
end
thermal_states_matgrid = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_matlab_grid)
thermal_states_matgrid_baseline = nothing
if abs(h_correction_factor - 1.0) > 1e-12
	thermal_parameters_baseline = deepcopy(thermal_parameters)
	thermal_parameters_baseline[:ExternalHeatTransferCoefficient] ./= h_correction_factor
	thermal_states_matgrid_baseline = run_thermal_case(thermal_model, thermal_state0, thermal_parameters_baseline, dt_matlab, forces_matlab_grid)
end

# Source timing sensitivity on MATLAB schedule:
# left  = source at step start time t_{n-1}
# mid   = source at midpoint
# right = source at step end time t_n
source_times_left = t_prev_matlab
source_times_mid = t_mid_matlab
source_times_right = t_matlab

if matlab_source_compatible
	forces_left = [(value = interpolate_source_at_time(ts, t_source_ref, M),) for ts in source_times_left]
	forces_mid = [(value = interpolate_source_at_time(ts, t_source_ref, M),) for ts in source_times_mid]
	forces_right = [(value = interpolate_source_at_time(ts, t_source_ref, M),) for ts in source_times_right]

	thermal_states_left = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_left)
	thermal_states_mid = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_mid)
	thermal_states_right = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_right)
else
	thermal_states_left = thermal_states_matgrid
	thermal_states_mid = thermal_states_matgrid
	thermal_states_right = thermal_states_matgrid
end

println("\nThermal budget diagnostics (sampled steps):")
sample_idx = unique(round.(Int, [1, max(2, fld(length(thermal_states), 2)), length(thermal_states)]))
for i in sample_idx
	if i > 1
		b = BattMo.compute_thermal_budget(
			thermal_model,
			thermal_states[i],
			thermal_parameters;
			source = forces[i].value,
			state_prev = thermal_states[i-1],
			dt = timesteps[i],
		)
	else
		b = BattMo.compute_thermal_budget(
			thermal_model,
			thermal_states[i],
			thermal_parameters;
			source = forces[i].value,
		)
	end
	println("  step $i: source = $(b.source_total), cooling = $(b.boundary_cooling_total), dE/dt = $(b.dE_dt)")
end

println("\nStep/time diagnostics:")
println("  Julia grid:  nsteps = $(length(timesteps)), tend = $(sum(timesteps)) s, mean dt = $(mean(timesteps)) s")
println("  MATLAB grid: nsteps = $(length(dt_matlab)), tend = $(sum(dt_matlab)) s, mean dt = $(mean(dt_matlab)) s")

cap = thermal_parameters[:Capacity]
vols = thermal_model.domain.representation[:volumes]
println("\nThermal inertia diagnostic:")
println("  sum(Capacity .* Volume) = $(sum(cap .* vols)) J/K")
println("  Capacity stats: min=$(minimum(cap)), max=$(maximum(cap)), mean=$(mean(cap)), n_unique=$(length(unique(round.(cap; digits = 12))))")

cond = thermal_parameters[:ElectronicConductivity]
println("  Conductivity stats: min=$(minimum(cond)), max=$(maximum(cond)), mean=$(mean(cond)), n_unique=$(length(unique(round.(cond; digits = 12))))")

function print_vector_diff_stats(label, a, b)
	d = a .- b
	println("  $label diff: mean=$(mean(d)), min=$(minimum(d)), max=$(maximum(d)), rmse=$(sqrt(mean(d .^ 2)))")
end

if !isnothing(mat_eff.cap_vec)
	println("  Capacity vs MATLAB effective vector:")
	print_vector_diff_stats("global", cap, mat_eff.cap_vec)
end
if !isnothing(mat_eff.cond_vec)
	println("  Conductivity vs MATLAB effective vector:")
	print_vector_diff_stats("global", cond, mat_eff.cond_vec)
end

function print_region_property_diffs(maps, cap, cond, mat_eff)
	region_order = [
		("NegativeElectrodeCurrentCollector", "neg cc"),
		("NegativeElectrodeActiveMaterial", "neg am"),
		("Electrolyte", "elyte"),
		("PositiveElectrodeActiveMaterial", "pos am"),
		("PositiveElectrodeCurrentCollector", "pos cc"),
	]
	println("\nPer-region thermal property diffs (Julia - MATLAB effective):")
	for (k, tag) in region_order
		if !haskey(maps, k)
			continue
		end
		cellmap = maps[k][1][:cellmap]
		if !isnothing(mat_eff.cap_vec)
			dc = cap[cellmap] .- mat_eff.cap_vec[cellmap]
			println("  Capacity [$tag]: mean=$(mean(dc)), min=$(minimum(dc)), max=$(maximum(dc)), rmse=$(sqrt(mean(dc .^ 2)))")
		end
		if !isnothing(mat_eff.cond_vec)
			dk = cond[cellmap] .- mat_eff.cond_vec[cellmap]
			println("  Conductivity [$tag]: mean=$(mean(dk)), min=$(minimum(dk)), max=$(maximum(dk)), rmse=$(sqrt(mean(dk .^ 2)))")
		end
	end
end

if !isnothing(mat_eff.cap_vec) || !isnothing(mat_eff.cond_vec)
	print_region_property_diffs(maps, cap, cond, mat_eff)
end

function boundary_cooling_geometry_diagnostics(thermal_model, thermal_parameters, maps, h_nominal)
	rep = thermal_model.domain.representation
	bcells = rep[:boundary_neighbors]
	bareas = rep[:boundary_areas]
	extcoef = thermal_parameters[:ExternalHeatTransferCoefficient] # already h*A [W/K]
	nc = number_of_cells(thermal_model.domain)

	cell_region = fill("other", nc)
	region_order = [
		("NegativeElectrodeCurrentCollector", "neg cc"),
		("NegativeElectrodeActiveMaterial", "neg am"),
		("Electrolyte", "elyte"),
		("PositiveElectrodeActiveMaterial", "pos am"),
		("PositiveElectrodeCurrentCollector", "pos cc"),
	]
	for (k, tag) in region_order
		if haskey(maps, k)
			cell_region[maps[k][1][:cellmap]] .= tag
		end
	end

	total_area = 0.0
	total_hA = 0.0
	region_area = Dict{String, Float64}()
	region_hA = Dict{String, Float64}()
	for i in eachindex(bcells)
		if extcoef[i] <= 0
			continue
		end
		c = bcells[i]
		tag = cell_region[c]
		a = bareas[i]
		hA = extcoef[i]
		total_area += a
		total_hA += hA
		region_area[tag] = get(region_area, tag, 0.0) + a
		region_hA[tag] = get(region_hA, tag, 0.0) + hA
	end

	println("\nBoundary cooling geometry diagnostics:")
	println("  active boundary area = ", total_area, " m^2")
	println("  total hA             = ", total_hA, " W/K")
	if h_nominal > 0
		println("  implied area (sum(hA)/h_nominal) = ", total_hA / h_nominal, " m^2")
	end
	for (_, tag) in region_order
		if haskey(region_area, tag)
			println("  [$tag] area = ", region_area[tag], " m^2, hA = ", region_hA[tag], " W/K")
		end
	end
end

boundary_cooling_geometry_diagnostics(thermal_model, thermal_parameters, maps, h_nominal)

cool_end = BattMo.compute_boundary_cooling_power(thermal_model, thermal_states[end], thermal_parameters)
println("\nBoundary cooling diagnostic at final Julia-grid thermal state:")
println("  cooling_total = $(cool_end.total) W")

c_e = output.states["ElectrolyteConcentration"]
c_e_clean = c_e
c_e_av = vec(mean(c_e_clean, dims = 2))

T = thermal_states
T_max = [maximum(state[:Temperature]) for state in thermal_states]
T_max_matgrid = [maximum(state[:Temperature]) for state in thermal_states_matgrid]
T_max_left = [maximum(state[:Temperature]) for state in thermal_states_left]
T_max_mid = [maximum(state[:Temperature]) for state in thermal_states_mid]
T_max_right = [maximum(state[:Temperature]) for state in thermal_states_right]
T_min = [minimum(state[:Temperature]) for state in thermal_states]
T_min_matgrid = [minimum(state[:Temperature]) for state in thermal_states_matgrid]
T_spread = T_max .- T_min
T_spread_matgrid = T_max_matgrid .- T_min_matgrid

T_min_matlab = [minimum(vec(data["states_thermal"][i]["T"])) for i in eachindex(t_matlab)]
T_spread_matlab = T_max_matlab .- T_min_matlab

# Cooling diagnostic: infer MATLAB cooling from dE/dt and source, and compare to Julia cooling.
T_matlab_vecs = [vec(data["states_thermal"][i]["T"]) for i in eachindex(t_matlab)]
if all(length.(T_matlab_vecs) .== nc)
	vols_diag = thermal_model.domain.representation[:volumes]
	E_matlab_steps = [sum(T_matlab_vecs[i] .* cap .* vols_diag) for i in eachindex(T_matlab_vecs)]
	cool_implied_matlab = fill(NaN, length(t_matlab))
	cool_julia = fill(NaN, length(t_matlab))
	for i in 2:length(t_matlab)
		dt_i = t_matlab[i] - t_matlab[i-1]
		dE_dt_i = (E_matlab_steps[i] - E_matlab_steps[i-1]) / dt_i
		qsrc_i = sum(forces_matlab_grid[i].value)
		cool_implied_matlab[i] = qsrc_i - dE_dt_i
		cool_julia[i] = BattMo.compute_boundary_cooling_power(thermal_model, thermal_states_matgrid[i], thermal_parameters).total
	end
	ix = findall(!isnan, cool_implied_matlab)
	if !isempty(ix)
		dcool = cool_julia[ix] .- cool_implied_matlab[ix]
		println("\nCooling comparison (Julia explicit - MATLAB implied) over $(length(ix)) steps:")
		println("  mean Δcool = ", mean(dcool), " W")
		println("  min  Δcool = ", minimum(dcool), " W")
		println("  max  Δcool = ", maximum(dcool), " W")
		mean_cool_julia = mean(cool_julia[ix])
		if mean_cool_julia > 0
			h_correction_factor_est = 1 - mean(dcool)/mean_cool_julia
			println("  suggested h_correction_factor ≈ ", h_correction_factor_est)
		end
	end
else
	println("\nSkipping cooling comparison: MATLAB state vector length does not match Julia thermal nc.")
end

ncmp = min(length(T_max), length(T_max_matlab))
dT_max = T_max[1:ncmp] .- T_max_matlab[1:ncmp]
println("T_max comparison (Julia - MATLAB) in K over $ncmp steps:")
println("  mean dT_max = ", mean(dT_max))
println("  min  dT_max = ", minimum(dT_max))
println("  max  dT_max = ", maximum(dT_max))

ncmp2 = min(length(T_max_matgrid), length(T_max_matlab))
dT_max_matgrid = T_max_matgrid[1:ncmp2] .- T_max_matlab[1:ncmp2]
println("\nT_max comparison on MATLAB schedule (Julia - MATLAB) in K over $ncmp2 steps:")
println("  mean dT_max = ", mean(dT_max_matgrid))
println("  min  dT_max = ", minimum(dT_max_matgrid))
println("  max  dT_max = ", maximum(dT_max_matgrid))
println("  rmse dT_max = ", sqrt(mean(dT_max_matgrid .^ 2)))

if !isnothing(thermal_states_matgrid_baseline)
	T_max_matgrid_baseline = [maximum(state[:Temperature]) for state in thermal_states_matgrid_baseline]
	ncmpb = min(length(T_max_matgrid_baseline), length(T_max_matlab))
	dT_b = T_max_matgrid_baseline[1:ncmpb] .- T_max_matlab[1:ncmpb]
	println("\nT_max before/after h-correction on MATLAB schedule:")
	println("  baseline h=1.0: mean = ", mean(dT_b), ", rmse = ", sqrt(mean(dT_b .^ 2)))
	println("  corrected h=$(h_correction_factor): mean = ", mean(dT_max_matgrid), ", rmse = ", sqrt(mean(dT_max_matgrid .^ 2)))
end

nspread = min(length(T_spread_matgrid), length(T_spread_matlab))
dT_spread = T_spread_matgrid[1:nspread] .- T_spread_matlab[1:nspread]
println("\nTemperature spread comparison (Julia MAT-grid - MATLAB) in K over $nspread steps:")
println("  mean d(Tmax-Tmin) = ", mean(dT_spread))
println("  min  d(Tmax-Tmin) = ", minimum(dT_spread))
println("  max  d(Tmax-Tmin) = ", maximum(dT_spread))

function print_dT_stats(label, tj)
	ncmp_loc = min(length(tj), length(T_max_matlab))
	dT_loc = tj[1:ncmp_loc] .- T_max_matlab[1:ncmp_loc]
	println("  $label: mean = $(mean(dT_loc)), min = $(minimum(dT_loc)), max = $(maximum(dT_loc))")
end

println("\nMATLAB-grid source-time alignment sweep (Julia - MATLAB) [K]:")
print_dT_stats("left    (t_{n-1})", T_max_left)
print_dT_stats("mid     (0.5*(t_{n-1}+t_n))", T_max_mid)
print_dT_stats("right   (t_n)", T_max_right)
forces_avg_sweep = make_forces_step_average(t_matlab, t_source_ref, M; pre_first_mode = :hold_first)
states_avg_sweep = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_avg_sweep)
T_max_avg_sweep = [maximum(st[:Temperature]) for st in states_avg_sweep]
print_dT_stats("average (step-average source)", T_max_avg_sweep)

function lag_stats(a::Vector{Float64}, b::Vector{Float64}, lag::Int)
	if lag >= 0
		# Compare a[1+lag:end] to b[1:end-lag]
		na = length(a) - lag
		nb = length(b)
		n = min(na, nb)
		if n <= 1
			return (n = 0, mean = NaN, min = NaN, max = NaN, rmse = NaN)
		end
		d = a[(1+lag):(lag+n)] .- b[1:n]
	else
		# Compare a[1:end+lag] to b[1-lag:end]
		L = -lag
		na = length(a)
		nb = length(b) - L
		n = min(na, nb)
		if n <= 1
			return (n = 0, mean = NaN, min = NaN, max = NaN, rmse = NaN)
		end
		d = a[1:n] .- b[(1+L):(L+n)]
	end
	return (n = length(d), mean = mean(d), min = minimum(d), max = maximum(d), rmse = sqrt(mean(d .^ 2)))
end

println("\nLag sweep for T_max (Julia MAT-grid, lag in steps):")
for lag in -3:3
	ls = lag_stats(T_max_matgrid, T_max_matlab, lag)
	println("  lag $(lag): n=$(ls.n), mean=$(ls.mean), min=$(ls.min), max=$(ls.max), rmse=$(ls.rmse)")
end

println("\nSource-row shift sweep on MATLAB dt grid (Julia - MATLAB) [K]:")
for s in -3:3
	if !matlab_source_compatible
		println("  source row shift $(s): skipped (MATLAB source vector length mismatch)")
		continue
	end
	forces_s = make_forces_from_source_rows(M, length(dt_matlab); row_shift = s)
	states_s = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_s)
	Tmax_s = [maximum(st[:Temperature]) for st in states_s]
	ncmp_s = min(length(Tmax_s), length(T_max_matlab))
	dT_s = Tmax_s[1:ncmp_s] .- T_max_matlab[1:ncmp_s]
	println("  source row shift $(s): mean=$(mean(dT_s)), min=$(minimum(dT_s)), max=$(maximum(dT_s)), rmse=$(sqrt(mean(dT_s .^ 2)))")
end

println("\nPre-first-time source handling sweep (MATLAB dt grid, Julia - MATLAB) [K]:")
for mode in (:hold_first, :zero)
	if !matlab_source_compatible
		println("  mode $(mode): skipped (MATLAB source vector length mismatch)")
		continue
	end
	t_eval_pf = choose_source_times(t_matlab, t_matlab, source_time_alignment)
	forces_pf = make_forces_interpolated(t_eval_pf, t_source_ref, M; pre_first_mode = mode)
	states_pf = run_thermal_case(thermal_model, thermal_state0, thermal_parameters, dt_matlab, forces_pf)
	Tmax_pf = [maximum(st[:Temperature]) for st in states_pf]
	n_pf = min(length(Tmax_pf), length(T_max_matlab))
	dT_pf = Tmax_pf[1:n_pf] .- T_max_matlab[1:n_pf]
	println("  mode $(mode): mean=$(mean(dT_pf)), min=$(minimum(dT_pf)), max=$(maximum(dT_pf)), rmse=$(sqrt(mean(dT_pf .^ 2)))")
end

function run_isolation_case(;
	use_matlab_effective_thermal_vectors_case::Bool,
	use_matlab_boundary_overrides_case::Bool,
	use_matlab_source_terms_case::Bool,
	use_boundary_series_resistance_case::Bool,
	h_correction_factor_case::Float64,
	source_time_alignment_case::Symbol,
	source_pre_first_mode_case::Symbol,
)
	thermal_model_c, thermal_parameters_c = BattMo.setup_thermal_model(input, grids)
	thermal_model_c.system.params[:use_boundary_series_resistance] = use_boundary_series_resistance_case

	# Scale h from the nominal external coefficient for this test case.
	thermal_parameters_c[:ExternalHeatTransferCoefficient] .*= (h_correction_factor_case / h_correction_factor)
	h_nominal_case = external_h_nominal * h_correction_factor_case

	nc_c = number_of_cells(thermal_model_c.domain)
	if use_matlab_effective_thermal_vectors_case
		maybe_apply_matlab_effective_thermal_properties!(thermal_parameters_c, data, nc_c)
	end
	if use_matlab_boundary_overrides_case
		maybe_apply_matlab_boundary_override!(thermal_model_c, thermal_parameters_c, data, h_nominal_case)
	end

	use_mat_src_c = use_matlab_source_terms_case && (size(M, 2) == nc_c)
	if source_time_alignment_case == :average
		forces_c = use_mat_src_c ?
				   make_forces_step_average(t_matlab, t_source_ref, M; pre_first_mode = source_pre_first_mode_case) :
				   [(value = src_matric[i],) for i in eachindex(dt_matlab)]
	else
		t_eval_c = choose_source_times(t_matlab, t_matlab, source_time_alignment_case)
		forces_c = use_mat_src_c ?
				   make_forces_interpolated(t_eval_c, t_source_ref, M; pre_first_mode = source_pre_first_mode_case) :
				   [(value = src_matric[i],) for i in eachindex(dt_matlab)]
	end

	states_c = run_thermal_case(thermal_model_c, thermal_state0, thermal_parameters_c, dt_matlab, forces_c)
	Tmax_c = [maximum(st[:Temperature]) for st in states_c]
	nc_cmp = min(length(Tmax_c), length(T_max_matlab))
	dT_c = Tmax_c[1:nc_cmp] .- T_max_matlab[1:nc_cmp]
	return (
		mean = mean(dT_c),
		min = minimum(dT_c),
		max = maximum(dT_c),
		rmse = sqrt(mean(dT_c .^ 2)),
	)
end

function run_and_print_isolation_case(label, cfg)
	r = run_isolation_case(;
		use_matlab_effective_thermal_vectors_case = cfg.use_matlab_effective_thermal_vectors_case,
		use_matlab_boundary_overrides_case = cfg.use_matlab_boundary_overrides_case,
		use_matlab_source_terms_case = cfg.use_matlab_source_terms_case,
		use_boundary_series_resistance_case = cfg.use_boundary_series_resistance_case,
		h_correction_factor_case = cfg.h_correction_factor_case,
		source_time_alignment_case = cfg.source_time_alignment_case,
		source_pre_first_mode_case = cfg.source_pre_first_mode_case,
	)
	println("  $label: mean=$(r.mean), min=$(r.min), max=$(r.max), rmse=$(r.rmse)")
	return r
end

base_cfg = (
	use_matlab_effective_thermal_vectors_case = use_matlab_effective_thermal_vectors,
	use_matlab_boundary_overrides_case = use_matlab_boundary_overrides,
	use_matlab_source_terms_case = use_matlab_source_terms,
	use_boundary_series_resistance_case = use_boundary_series_resistance,
	h_correction_factor_case = h_correction_factor,
	source_time_alignment_case = source_time_alignment,
	source_pre_first_mode_case = source_pre_first_mode,
)

println("\nSwitch isolation sweep (MATLAB schedule, Julia - MATLAB) [K]:")
iso_labels = String[]
iso_results = NamedTuple[]

push!(iso_labels, "baseline")
push!(iso_results, run_and_print_isolation_case("baseline", base_cfg))

push!(iso_labels, "flip matlab props")
push!(iso_results, run_and_print_isolation_case(
	"flip use_matlab_effective_thermal_vectors",
	(; base_cfg..., use_matlab_effective_thermal_vectors_case = !base_cfg.use_matlab_effective_thermal_vectors_case),
))
push!(iso_labels, "flip matlab boundary")
push!(iso_results, run_and_print_isolation_case(
	"flip use_matlab_boundary_overrides",
	(; base_cfg..., use_matlab_boundary_overrides_case = !base_cfg.use_matlab_boundary_overrides_case),
))
push!(iso_labels, "flip matlab sources")
push!(iso_results, run_and_print_isolation_case(
	"flip use_matlab_source_terms",
	(; base_cfg..., use_matlab_source_terms_case = !base_cfg.use_matlab_source_terms_case),
))
push!(iso_labels, "flip boundary model")
push!(iso_results, run_and_print_isolation_case(
	"flip use_boundary_series_resistance",
	(; base_cfg..., use_boundary_series_resistance_case = !base_cfg.use_boundary_series_resistance_case),
))
push!(iso_labels, "align :left")
push!(iso_results, run_and_print_isolation_case(
	"source_time_alignment = :left",
	(; base_cfg..., source_time_alignment_case = :left),
))
push!(iso_labels, "align :mid")
push!(iso_results, run_and_print_isolation_case(
	"source_time_alignment = :mid",
	(; base_cfg..., source_time_alignment_case = :mid),
))
push!(iso_labels, "align :right")
push!(iso_results, run_and_print_isolation_case(
	"source_time_alignment = :right",
	(; base_cfg..., source_time_alignment_case = :right),
))
push!(iso_labels, "align :average")
push!(iso_results, run_and_print_isolation_case(
	"source_time_alignment = :average",
	(; base_cfg..., source_time_alignment_case = :average),
))
push!(iso_labels, "prefirst :hold")
push!(iso_results, run_and_print_isolation_case(
	"source_pre_first_mode = :hold_first",
	(; base_cfg..., source_pre_first_mode_case = :hold_first),
))
push!(iso_labels, "prefirst :zero")
push!(iso_results, run_and_print_isolation_case(
	"source_pre_first_mode = :zero",
	(; base_cfg..., source_pre_first_mode_case = :zero),
))
if abs(base_cfg.h_correction_factor_case - 1.0) > 1e-12
	push!(iso_labels, "h = 1.0")
	push!(iso_results, run_and_print_isolation_case(
		"h_correction_factor = 1.0",
		(; base_cfg..., h_correction_factor_case = 1.0),
	))
end

iso_x = collect(1:length(iso_labels))
iso_mean = [r.mean for r in iso_results]
iso_rmse = [r.rmse for r in iso_results]
fiso = Figure(size = (1500, 850))
ax_iso1 = Axis(fiso[1, 1],
	title = "Switch Isolation: mean(ΔTmax) [Julia - MATLAB]",
	ylabel = "mean ΔTmax / K",
	xticks = (iso_x, iso_labels),
	xticklabelrotation = pi/6,
	xticklabelsize = 12)
barplot!(ax_iso1, iso_x, iso_mean, color = :steelblue)
hlines!(ax_iso1, [0.0], color = :black, linestyle = :dash, linewidth = 2)

ax_iso2 = Axis(fiso[2, 1],
	title = "Switch Isolation: RMSE(ΔTmax)",
	ylabel = "RMSE ΔTmax / K",
	xticks = (iso_x, iso_labels),
	xticklabelrotation = pi/6,
	xticklabelsize = 12)
barplot!(ax_iso2, iso_x, iso_rmse, color = :darkorange)
display(GLMakie.Screen(), fiso)

total_sources = src_matric
fsrc = BattMo.plot_thermal_source_contributions(t, sources; total_source = total_sources)
display(GLMakie.Screen(), fsrc)

#########################################################
# Comparison plots

f1 = Figure(size = (1000, 400))
ax1 = Axis(f1[1, 1],
	title = "Maximum Temperature",
	xlabel = "Time / s",
	ylabel = "Temperature / C",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

matlab_ = scatterlines!(ax1,
	t_matlab,
	T_max_matlab .- 273.15;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

julia_ = scatterlines!(ax1,
	t,
	T_max .- 273.15;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)

julia_matgrid_ = scatterlines!(ax1,
	t_matlab[1:length(T_max_matgrid)],
	T_max_matgrid .- 273.15;
	linewidth = 3,
	markersize = 8,
	marker = :utriangle,
	markercolor = :orange,
)

Legend(f1[1, 2],
	[matlab_, julia_, julia_matgrid_],
	["MATLAB", "Julia (Julia dt)", "Julia (MATLAB dt)"])
display(GLMakie.Screen(), f1)

f2 = Figure(size = (1000, 400))
ax2 = Axis(f2[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_v = scatterlines!(ax2,
	t_matlab,
	E_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_v = scatterlines!(ax2,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f2[1, 2], [matlab_v, julia_v], ["MATLAB", "Julia"])
display(GLMakie.Screen(), f2)

f3 = Figure(size = (1000, 400))
ax3 = Axis(f3[1, 1],
	title = "ElectrolyteConcentration",
	xlabel = "Time / s",
	ylabel = "Concentration / mol�m^-3",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_ce = scatterlines!(ax3,
	t_matlab,
	c_e_av_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_ce = scatterlines!(ax3,
	t,
	c_e_av;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f3[1, 2], [matlab_ce, julia_ce], ["MATLAB", "Julia"])
display(GLMakie.Screen(), f3)






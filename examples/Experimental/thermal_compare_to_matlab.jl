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
use_matlab_source_terms = false

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

@show propertynames(output.model.multimodel.models)

input.cell_parameters["ThermalModel"]["EffectiveVolumetricHeatCapacity"] = output.model.multimodel.models[:ThermalModel].parameters["EffectiveVolumetricHeatCapacity"]
input.cell_parameters["ThermalModel"]["EffectiveThermalConductivity"] = output.model.multimodel.models[:ThermalModel].parameters["EffectiveThermalConductivity"]

thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)
nc = number_of_cells(thermal_model.domain)



# Parity controls:
# - source_time_alignment: :left, :mid, :right, :average
# - source_row_shift: integer shift for direct row indexing when not interpolating.
source_time_alignment = :left
source_row_shift = -1
source_pre_first_mode = :zero
sources = []
src_matric = []


for state in states
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source_by_type!(thermal_model, model, state, maps)
	push!(sources, stepsources)
	push!(src_matric, src)
end


forces = NamedTuple[]
if use_matlab_source_terms
	push!(forces, (value = M[1:(end-1), :],))
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

sim = Simulator(thermal_model;
	state0 = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)

states_loc, = simulate(sim, timesteps; info_level = -1, forces = forces)


T_max = [maximum(state[:Temperature]) for state in thermal_states]

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






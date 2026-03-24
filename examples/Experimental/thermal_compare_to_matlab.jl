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
states_heat = data["states_heat"]

@show keys(states_heat[end]["ThermalModel"])

for (k, v) in data
	println("KEY: ", k, " | TYPE: ", typeof(v))
end

effective_thermal_conductivity_matlab = vec(data["effectiveThermalConductivity"])
effective_volumetric_heat_capacity_matlab = vec(data["effectiveVolumetricHeatCapacity"])

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
# For strict thermal parity against the MATLAB runOnlyThermal case, use the MATLAB
# source terms on the MATLAB time grid.
use_matlab_source_terms = true

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

inputparams = merge_input_params([inputparams_material, inputparams_geometry])

fn = string(dirname(pathof(BattMo)), "/../examples/Experimental/jsoninputs/cc_discharge_control.json")
inputparams_control = load_advanced_dict_input(fn)
inputparams = merge_input_params(inputparams_control, inputparams; warn = true)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/simple_thermal.json")
inputparams_thermal = load_advanced_dict_input(fn)
inputparams = merge_input_params(inputparams_thermal, inputparams; warn = true)

# reduce specific heat capacities

function getnested(d, keys::Tuple)
	for k in keys
		d = d[k]
	end
	return d
end

function setnested!(d, keys::Tuple, value)
	lastkey = last(keys)
	parent = getnested(d, keys[1:(end-1)])
	parent[lastkey] = value
end


locations = [
	("NegativeElectrode", "Coating", "ActiveMaterial", "specificHeatCapacity"),
	("PositiveElectrode", "Coating", "ActiveMaterial", "specificHeatCapacity"),
	("NegativeElectrode", "CurrentCollector", "specificHeatCapacity"),
	("PositiveElectrode", "CurrentCollector", "specificHeatCapacity"),
	("Electrolyte", "specificHeatCapacity"),
]

for loc in locations
	oldval = getnested(inputparams.all, loc)
	setnested!(inputparams.all, loc, oldval * 5e-2)
end



inputparams["Control"]["lowerCutoffVoltage"] = 3.6
inputparams["Geometry"]["Nh"] = 16
inputparams["Geometry"]["height"] = 2e-2 + 2*1e-3
inputparams["PositiveElectrode"]["CurrentCollector"]["thickness"] = 80e-6
inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"] = 100e-6


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

effective_thermal_conductivity_julia = output.simulation.parameters[:ThermalModel][:EffectiveThermalConductivity]
effective_volumetric_heat_capacity_julia = output.simulation.parameters[:ThermalModel][:EffectiveVolumetricHeatCapacity]

input.cell_parameters["ThermalModel"]["EffectiveVolumetricHeatCapacity"] = effective_volumetric_heat_capacity_julia
input.cell_parameters["ThermalModel"]["EffectiveThermalConductivity"] = effective_thermal_conductivity_julia

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
thermal_timesteps = timesteps
thermal_time = t
if use_matlab_source_terms
	thermal_timesteps = vcat(t_matlab[1], diff(t_matlab))
	thermal_time = t_matlab
	for i in 1:length(thermal_timesteps)
		push!(forces, (value = vec(M[i, :]),))
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

sim = Simulator(thermal_model;
	state0 = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)

thermal_states, = simulate(sim, thermal_timesteps; info_level = -1, forces = forces)


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
	thermal_time,
	T_max .- 273.15;
	linewidth = 2,
	markersize = 5,
	marker = :circle,
	markercolor = :red,
)


Legend(f1[1, 2],
	[matlab_, julia_],
	["MATLAB", use_matlab_source_terms ? "Julia (MATLAB sources/time)" : "Julia (Julia dt)"])
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
	title = "Effective thermal conductivity comparison",
	xlabel = "-",
	ylabel = "Effective thermal conductivity / W m^-1 K^-1|",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

matlab_ = scatterlines!(ax3,
	effective_thermal_conductivity_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

julia_ = scatterlines!(ax3,
	effective_thermal_conductivity_julia;
	linewidth = 2,
	markersize = 5,
	marker = :circle,
	markercolor = :red,
)


Legend(f3[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f3)

f4 = Figure(size = (1000, 400))
ax4 = Axis(f4[1, 1],
	title = "Effective volumetric heat capacity comparison",
	xlabel = "-",
	ylabel = "Effective volumetric heat capacity / J m^-3 K^-1|",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

matlab_ = scatterlines!(ax4,
	effective_volumetric_heat_capacity_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

julia_ = scatterlines!(ax4,
	effective_volumetric_heat_capacity_julia;
	linewidth = 2,
	markersize = 5,
	marker = :circle,
	markercolor = :red,
)


Legend(f4[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f4)

BattMo.plot_thermal_source_contributions(t, sources; total_source = src_matric)



using GLMakie

"""
	plot_source_comparison(sources, states_heat; t = nothing)

Compares Julia BattMo source terms to MATLAB heat sources stored under
states_heat[end]["ThermalModel"], using GLMakie.

Arguments
---------
- sources :: Vector{Dict{Symbol, Vector{Float64}}}
- states_heat :: Vector{Dict{String, Any}}  (BattMo thermal states)
- t :: Vector (optional)   time axis

Returns
-------
GLMakie Figure with Julia vs MATLAB curves.
"""
function plot_source_comparison(sources, states_heat; t = nothing)

	# ----------------------------------------------------------
	# 1. Extract Julia sources and group them
	# ----------------------------------------------------------

	lastsrc = sources[end]

	# group by source type (strip "(pos)" / "(neg)")
	groups = Dict{String, Vector{Vector{Float64}}}()

	for key in keys(lastsrc)
		name = String(key)
		basetype = strip(split(name, "(")[1])

		if !haskey(groups, basetype)
			groups[basetype] = Vector{Vector{Float64}}()
		end
		push!(groups[basetype], lastsrc[key])
	end

	# Sum positive + negative contributions
	julia_summed = Dict{String, Vector{Float64}}()
	for (basetype, arrs) in groups
		julia_summed[basetype] = reduce(+, arrs)
	end

	# ----------------------------------------------------------
	# 2. Extract MATLAB sources
	# ----------------------------------------------------------

	mat = states_heat[end]["ThermalModel"]

	matlab_sources = Dict(
		"ReactionReversible"   => mat["jHeatRevReactionSource"],
		"ReactionIrreversible" => mat["jHeatIrrevReactionSource"],
		"Ohmic"                => mat["jHeatOhmSource"],
		"Chemical"             => mat["jHeatChemicalSource"],
		"ReactionTotal"        => mat["jHeatReactionSource"],
		"TotalHeat"            => mat["jHeatSource"],
	)

	# ----------------------------------------------------------
	# 3. Time axis
	# ----------------------------------------------------------

	N = maximum(length.(values(julia_summed)))

	if isnothing(t)
		t = 1:N
	end

	# ----------------------------------------------------------
	# 4. Plot comparison
	# ----------------------------------------------------------

	fig = Figure(size = (1200, 800))

	row = 1
	for (label, julia_arr) in julia_summed
		# Only plot if there is a MATLAB equivalent
		haskey(matlab_sources, label) || continue

		matlab_arr = matlab_sources[label]

		ax = Axis(fig[row, 1],
			title = "$label: Julia vs MATLAB",
			xlabel = "Index",
			ylabel = "Value")

		lines!(ax, julia_arr, label = "Julia ($label)", linewidth = 2)
		lines!(ax, vec(matlab_arr), label = "MATLAB ($label)", linewidth = 2, linestyle = :dash)

		axislegend(ax)
		row += 1
	end

	return fig
end

f5 = plot_source_comparison(sources, states_heat; t = t_matlab)
display(GLMakie.Screen(), f5)


grids     = output.simulation.grids
couplings = output.simulation.couplings


components = ["NegativeElectrodeActiveMaterial", "PositiveElectrodeActiveMaterial", "NegativeElectrodeCurrentCollector", "PositiveElectrodeCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide

# # We plot the geometry

# for (i, component) in enumerate(components)
# 	if i == 1
# 		global fig1, ax1 = plot_mesh(grids[component],
# 			color = colors[i],
# 			label = string(component))
# 		# ax.aspect = :data
# 	else
# 		plot_mesh!(ax1,
# 			grids[component],
# 			color = colors[i],
# 			label = string(component))
# 	end
# end
# legend_elements = [
# 	PolyElement(color = colors[i]) for i in eachindex(components)
# ]

# Legend(fig1[1, 2], legend_elements, components)

# display(GLMakie.Screen(), fig1)

# We plot the grid

for (i, component) in enumerate(components)
	if i == 1
		global fig2, ax2 = plot_mesh_edges(grids[component],
			color = colors[i],
			label = string(component))
		# ax2.aspect = :data
	else
		plot_mesh_edges!(ax2,
			grids[component],
			color = colors[i],
			label = string(component))
	end
end
legend_elements = [
	PolyElement(color = colors[i]) for i in eachindex(components)
]

Legend(fig2[1, 2], legend_elements, components)
display(GLMakie.Screen(), fig2)
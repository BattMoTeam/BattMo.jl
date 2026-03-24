using BattMo, GLMakie, MAT, Jutul, Statistics

###############################################
# Retrieve MATLAB data

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/run_only_thermal.mat")

file = matopen(fn)
data = read(file)
close(file)

t_matlab_full = data["time"][:, 1]
t_matlab = t_matlab_full[1:(end-1)]
E_matlab = data["E"][:, 1][1:(end-1)]
sources_matlab = data["sourceTerms"]
states_heat_matlab = data["states_heat"]
heat_source_data_matlab = data["heatSourceData"]

for (k, v) in data
	println("MATLAB data key: ", k, " | type: ", typeof(v))
end

println("")
println("Heat source terms in matlab (states_heat_matlab):")
println(keys(states_heat_matlab[end]["ThermalModel"]))
println("")
println("Heat source terms in matlab (heatSourceData):")
println(keys(heat_source_data_matlab))


effective_thermal_conductivity_matlab = vec(data["effectiveThermalConductivity"])
effective_volumetric_heat_capacity_matlab = vec(data["effectiveVolumetricHeatCapacity"])

# helper function to convert matlab cells to matrix
function convert_matlab_cells_to_matrix(cells)
	outer = vec(cells)
	vectors = [vec(inner[:, 1]) for inner in outer]
	sources_matlab_matrix = reduce(hcat, vectors)
	return permutedims(sources_matlab_matrix)
end

sources_matlab_matrix = convert_matlab_cells_to_matrix(sources_matlab)
t_source_ref = length(t_matlab_full) == size(sources_matlab_matrix, 1) ? t_matlab_full : t_matlab

# Toggle use of MATLAB-retrieved sourced terms in the julia simulation.
use_matlab_source_terms = false

# Compute maximum temperature from matlab data
T_max_matlab = Float64[]
for i in eachindex(t_matlab)
	T_matlab = data["states_thermal"][i]["T"]
	push!(T_max_matlab, maximum(vec(T_matlab)))
end


###################################################
# Run electrochemical simulation in Julia

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



# Adjust input parameters to match the MATLAB simulation

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
inputparams["Geometry"]["Nh"] = 16  # needs to be electrode Nh + 2 * tab Nh from MATLAB geometry
inputparams["Geometry"]["height"] = 2e-2 + 2*1e-3# needs to be electrode height + 2 * tab height from MATLAB geometry
inputparams["PositiveElectrode"]["CurrentCollector"]["thickness"] = 80e-6 # in order to match the MATLAB geometry.
inputparams["NegativeElectrode"]["CurrentCollector"]["thickness"] = 100e-6# in order to match the MATLAB geometry.


# Run simulation

output = run_simulation(inputparams; accept_invalid = true)


#########################################################
# Plot grid geometry

grids     = output.simulation.grids
couplings = output.simulation.couplings


components = ["NegativeElectrodeActiveMaterial", "PositiveElectrodeActiveMaterial", "NegativeElectrodeCurrentCollector", "PositiveElectrodeCurrentCollector"]
colors = [:gray, :green, :blue, :black]
nothing #hide

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


###################################################
# Compare voltage curves


E = output.time_series["Voltage"]
t = output.time_series["Time"]


f1 = Figure(size = (1000, 400))
ax1 = Axis(f1[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_v = scatterlines!(ax1,
	t_matlab,
	E_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_v = scatterlines!(ax1,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f1[1, 2], [matlab_v, julia_v], ["MATLAB", "Julia"])
display(GLMakie.Screen(), f1)


###################################################
# Run thermal simulation


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

# Retrieve effective thermal parameters from the electrochemical simulation.

effective_thermal_conductivity_julia = output.simulation.parameters[:ThermalModel][:EffectiveThermalConductivity]
effective_volumetric_heat_capacity_julia = output.simulation.parameters[:ThermalModel][:EffectiveVolumetricHeatCapacity]

input.cell_parameters["ThermalModel"]["EffectiveVolumetricHeatCapacity"] = effective_volumetric_heat_capacity_julia
input.cell_parameters["ThermalModel"]["EffectiveThermalConductivity"] = effective_thermal_conductivity_julia

# Setup thermal model

thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)
nc = number_of_cells(thermal_model.domain)

sources_julia = []
sources_julia_matrix = []


for state in states
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source_by_type!(thermal_model, model, state, maps)
	push!(sources_julia, stepsources)
	push!(sources_julia_matrix, src)
end

println("")
println("Heat source terms in Julia (sources_julia):")
println(keys(sources_julia[1]))

# Use Julia or MATLAB computed source terms
forces = NamedTuple[]
thermal_timesteps = timesteps
thermal_time = t

if use_matlab_source_terms
	thermal_timesteps = vcat(t_matlab[1], diff(t_matlab))
	thermal_time = t_matlab
	for i in 1:length(thermal_timesteps)
		push!(forces, (value = vec(sources_matlab_matrix[i, :]),))
	end
else
	for src in sources_julia_matrix
		push!(forces, (value = src,))
	end
end

# Compare source term matrix sizes

src_matrix = reduce(vcat, (x' for x in sources_julia_matrix))

println("  Julia source matrix size = $(size(src_matrix))")
println("  MxATLAB source matrix size = $(size(sources_matlab_matrix))")

# Run thermal simulation
T0 = 298.15 * ones(nc)

thermal_state0 = setup_state(thermal_model, Dict(:Temperature => T0))

sim = Simulator(thermal_model;
	state0 = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)

thermal_states, = simulate(sim, thermal_timesteps; info_level = -1, forces = forces)

# Compute T_max from thermal simulation

T_max_julia = [maximum(state[:Temperature]) for state in thermal_states]


#########################################################
# Plot source term contributions

BattMo.plot_thermal_source_contributions(t, sources_julia; total_source = sources_julia_matrix)


#########################################################
# Comparison maximum temperature

f2 = Figure(size = (1000, 400))
ax2 = Axis(f2[1, 1],
	title = "Maximum Temperature",
	xlabel = "Time / s",
	ylabel = "Temperature / C",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

matlab_ = scatterlines!(ax2,
	t_matlab,
	T_max_matlab .- 273.15;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

julia_ = scatterlines!(ax2,
	thermal_time,
	T_max_julia .- 273.15;
	linewidth = 2,
	markersize = 5,
	marker = :circle,
	markercolor = :red,
)


Legend(f2[1, 2],
	[matlab_, julia_],
	["MATLAB", use_matlab_source_terms ? "Julia (MATLAB sources/time)" : "Julia (Julia dt)"])
display(GLMakie.Screen(), f2)


#########################################################
# Comparison effective thermal parameters

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


#########################################################
# Comparison source terms



keys_matlab = filter(k -> !(k in ["Total", "Residual"]), collect(keys(heat_source_data_matlab)))
nkeys = length(keys_matlab)


matlab_to_julia_keymap = Dict(
	# Ohmic current collectors
	"OhmicCurrentCollector_pos_" => Symbol("OhmicCurrentCollector (pos)"),
	"OhmicCurrentCollector_neg_" => Symbol("OhmicCurrentCollector (neg)"),

	# Ohmic active material
	"OhmicActiveMaterial_pos_" => Symbol("OhmicActiveMaterial (pos)"),
	"OhmicActiveMaterial_neg_" => Symbol("OhmicActiveMaterial (neg)"),

	# Electrolyte ohmic
	"OhmicElectrolyte_elyte_" => Symbol("OhmicElectrolyte (elyte)"),

	# Reaction reversible
	"ReactionReversible_pos_" => Symbol("ReactionReversible (pos)"),
	"ReactionReversible_neg_" => Symbol("ReactionReversible (neg)"),

	# Reaction irreversible
	"ReactionIrreversible_pos_" => Symbol("ReactionIrreversible (pos)"),
	"ReactionIrreversible_neg_" => Symbol("ReactionIrreversible (neg)"),

	# Diffusion (electrolyte)
	"DiffusionElectrolyte_elyte_" => Symbol("DiffusionElectrolyte (elyte)"),

	# Total / Residual (if you add them)
	# "Total"    => Symbol("Total"),
	# "Residual" => Symbol("Residual"),
)

# ----- Helper: retrieve and sum Julia heat source totals -----
function get_julia_series(key)
	sym = matlab_to_julia_keymap[key]   # map MATLAB → Julia symbol
	nt = length(sources_julia)
	vals = zeros(nt)

	for i in 1:nt
		d = sources_julia[i]
		if haskey(d, sym)
			v = d[sym]
			vals[i] = v isa Number ? v : sum(v)
		else
			@warn "Missing Julia key $sym at timestep $i"
			vals[i] = NaN
		end
	end

	return vals
end

# ----- Plot each source term -----

ncols = 2
nrows = ceil(Int, nkeys / ncols)

f5 = Figure(size = (1400, 350 * nrows))

for (idx, key) in enumerate(keys_matlab)

	# Determine grid position: (row, col)
	row = ceil(Int, idx / ncols)
	col = idx % ncols == 0 ? ncols : idx % ncols

	mat = heat_source_data_matlab[key]
	time_mat = mat[:, 1]
	values_mat = mat[:, 2]

	values_julia = get_julia_series(key)


	ax = Axis(f5[row, col],
		title = key,
		xlabel = "Time / s",
		ylabel = "Heat / W·m⁻³",
		xticklabelsize = 16,
		yticklabelsize = 16,
	)

	mplot = scatterlines!(
		ax, time_mat, values_mat;
		linewidth = 3,
		marker = :cross,
		markersize = 8,
		color = :black,
	)

	jplot = scatterlines!(
		ax, t, values_julia;
		linewidth = 2,
		marker = :circle,
		markersize = 6,
		color = :red,
	)

	axislegend(ax, [mplot, jplot], ["MATLAB", "Julia"], position = :rt)

end

display(GLMakie.Screen(), f5)



# Total heat 

total_heat_matlab = [
	sum(states_heat_matlab[i]["ThermalModel"]["jHeatSource"])
	for i in 1:length(states_heat_matlab)
]

nt = length(t)
total_heat_julia = zeros(nt)
for it in 1:nt
	step_total = sources_julia_matrix[it]
	total_heat_julia[it] = step_total isa Number ? Float64(step_total) : sum(step_total)
end

f6 = Figure(size = (1000, 400))
ax6 = Axis(f6[1, 1],
	title = "Total Heat Generation",
	xlabel = "Time / s",
	ylabel = "Heat / W m^-3",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

matlab_ = scatterlines!(ax6,
	total_heat_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)

julia_ = scatterlines!(ax6,
	total_heat_julia;
	linewidth = 2,
	markersize = 5,
	marker = :circle,
	markercolor = :red,
)


Legend(f6[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f6)



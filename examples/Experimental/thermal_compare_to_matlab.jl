using BattMo, GLMakie, MAT, Jutul, Statistics


###############################################
# MATLAB data

fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/runOnlyThermal.mat")

file = matopen(fn)
data = read(file)
close(file)

t_matlab = data["time"][:, 1][1:(end-1)]
E_matlab = data["E"][:, 1][1:(end-1)]
sources_matlab = data["sourceTerms"]

# helper function to convert matlab cells to matrix

function convert_matlab_cells_to_matrix(cells)
	# Step 1: ensure we have a simple Vector of inner arrays
	outer = vec(cells)

	# Step 2: convert each (1000×1) inner matrix into a Vector
	vectors = [vec(inner[:, 1]) for inner in outer]

	# Step 3: stack vectors horizontally into a matrix (1000 × 52)
	M = reduce(hcat, vectors)

	# Step 4: transpose to get (52 × 1000)
	return permutedims(M)
end

M = convert_matlab_cells_to_matrix(sources_matlab)


T_max_matlab = Float64[]
for i in eachindex(t_matlab)
	T_matlab = data["states_thermal"][i]["T"]
	push!(T_max_matlab, maximum(vec(T_matlab)))
end
matlab_states = data["output_isothermal"]["states"]
c_e_matlab = [state["Electrolyte"]["c"] for state in matlab_states]
c_e_clean_matlab = convert_matlab_cells_to_matrix(replace(c_e_matlab, NaN => 0.0))
c_e_av_matlab = vec(mean(c_e_clean_matlab, dims = 2))[1:(end-1)]
c_s_ne_matlab = [state["NegativeElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["cSurface"] for state in matlab_states]
c_s_ne_clean_matlab = convert_matlab_cells_to_matrix(replace(c_s_ne_matlab, NaN => 0.0))
c_s_ne_av_matlab = vec(mean(c_s_ne_clean_matlab, dims = 2))[1:(end-1)]
c_s_pe_matlab = [state["PositiveElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["cSurface"] for state in matlab_states]
c_s_pe_clean_matlab = convert_matlab_cells_to_matrix(replace(c_s_pe_matlab, NaN => 0.0))
c_s_pe_av_matlab = vec(mean(c_s_pe_clean_matlab, dims = 2))[1:(end-1)]


###################################################
# Julia data

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/lithium_ion_battery_nmc_graphite.json")
inputparams_material = load_advanced_dict_input(fn)

fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/3d_demo_geometry.json")
inputparams_geometry = load_advanced_dict_input(fn)
inputparams_geometry["Geometry"]["Nh"] = 16

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

# Add Thermal Model
inputparams["use_thermal"] = true
inputparams["ThermalModel"]["externalHeatTransferCoefficient"] = 0.1

output = run_simulation(inputparams; accept_invalid = true);

E = output.time_series["Voltage"]

grids     = output.simulation.grids
couplings = output.simulation.couplings


input = (
	model_settings      = output.simulation.model.settings,
	cell_parameters     = output.simulation.cell_parameters,
	cycling_protocol    = output.simulation.cycling_protocol,
	simulation_settings = output.simulation.settings,
)

model      = output.model
multimodel = model.multimodel
states     = output.jutul_output.states
parameters = output.simulation.parameters
grids      = output.simulation.grids
maps       = output.simulation.global_maps
timesteps  = output.simulation.time_steps[1:length(states)]


thermal_model, thermal_parameters = BattMo.setup_thermal_model(input, grids)

forces = []
sources = []
src_matric = []

for (i, state) in enumerate(states)
	state = BattMo.get_state_with_secondary_variables(multimodel, state, parameters)
	src, stepsources = BattMo.get_energy_source!(thermal_model, model, state, maps)

	# push!(forces, (value = src,))
	push!(forces, (value = M[i, :],))
	push!(sources, stepsources)
	push!(src_matric, src)
end

src_matrix = reduce(vcat, (x' for x in src_matric))

diff_sources = src_matrix - M[1:(end-1), :]

nc = number_of_cells(thermal_model.domain)
T0 = 298.15*ones(nc)

thermal_state0 = setup_state(thermal_model, Dict(:Temperature => T0))

thermal_sim = Simulator(thermal_model;
	state0     = thermal_state0,
	parameters = thermal_parameters,
	copy_state = true)
thermal_states, = simulate(thermal_sim, timesteps; info_level = -1, forces = forces)

t = output.time_series["Time"]
c_e = output.states["ElectrolyteConcentration"]

c_e_clean = c_e
c_e_av = vec(mean(c_e_clean, dims = 2))


T = thermal_states
T_max = [maximum(state[:Temperature]) for state in thermal_states]

# Compare on common prefix in case one output has one extra stored state.
ncmp = min(length(T_max), length(T_max_matlab))
ΔT_max = T_max[1:ncmp] .- T_max_matlab[1:ncmp]
println("T_max comparison (Julia - MATLAB) in K over $ncmp steps:")
println("  mean ΔT_max = ", mean(ΔT_max))
println("  min  ΔT_max = ", minimum(ΔT_max))
println("  max  ΔT_max = ", maximum(ΔT_max))


#########################################################
# Comparison plot

f1 = Figure(size = (1000, 400))
ax1 = Axis(f1[1, 1],
	title = "Maximum Temperature",
	xlabel = "Time / s",
	ylabel = "Temperature / \u00B0C",
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
Legend(f1[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
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
matlab_ = scatterlines!(ax2,
	t_matlab,
	E_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_ = scatterlines!(ax2,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f2[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f2)


f3 = Figure(size = (1000, 400))
ax3 = Axis(f3[1, 1],
	title = "ElectrolyteConcentration",
	xlabel = "Time / s",
	ylabel = "Concentration / mol·m⁻³",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
matlab_ = scatterlines!(ax3,
	t_matlab,
	c_e_av_matlab;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
)
julia_ = scatterlines!(ax3,
	t,
	c_e_av;
	linewidth = 4,
	markersize = 10,
	marker = :circle,
	markercolor = :red,
)
Legend(f3[1, 2],
	[matlab_, julia_],
	["MATLAB", "Julia"])
display(GLMakie.Screen(), f3)


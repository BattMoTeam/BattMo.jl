export get_output_time_series, get_output_metrics, get_output_states

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
function get_output_time_series(output::NamedTuple; quantities::Union{Nothing, Vector{String}} = nothing)

	selected_pairs = []
	available_quantities = ["Time", "Voltage", "Current"]

	voltage, current = extract_time_series_data(output)
	time = extract_output_times(output)

	push!(selected_pairs, :Time => time)

	if !isnothing(quantities)

		for q in quantities
			if q == "Voltage"
				push!(selected_pairs, :Voltage => voltage)
			elseif q == "Current"
				push!(selected_pairs, :Current => current)
			elseif q == "Time"
				push!(selected_pairs, :Time => time)
			else
				error("Quantitiy $q is not available in this data")
			end
		end
	else
		push!(selected_pairs, :Time => time)
		push!(selected_pairs, :Current => current)
		push!(selected_pairs, :Voltage => voltage)
	end

	return (; selected_pairs...)
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
- `:CycleNumber`
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
	output::NamedTuple;
	metrics::Union{Nothing, Vector{String}} = nothing,
)
	model = output[:extra][:model]
	states = output[:states]

	cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]

	# Prepare selected output fields
	selected = Dict{Symbol, Any}()

	# Metric storage
	discharge_cap::Vector{Float64} = Float64[]
	charge_cap::Vector{Float64} = Float64[]
	discharge_energy::Vector{Float64} = Float64[]
	charge_energy::Vector{Float64} = Float64[]
	round_trip_efficiency::Vector{Float64} = Float64[]


	# Identify unique non-zero cycles
	unique_cycles = unique(cycle_array)
	cycles_above_zero = filter(x -> x > 0, unique_cycles)

	if isempty(cycles_above_zero)
		# Compute globally
		push!(discharge_cap, compute_discharge_capacity(output))
		push!(charge_cap, compute_charge_capacity(output))
		push!(discharge_energy, compute_discharge_energy(output))
		push!(charge_energy, compute_charge_energy(output))
		push!(round_trip_efficiency, compute_round_trip_efficiency(output))
		capacity = compute_capacity(output)
	else
		# Compute per cycle
		for cycle in cycle_array
			push!(discharge_cap, compute_discharge_capacity(output; cycle_number = cycle))
			push!(charge_cap, compute_charge_capacity(output; cycle_number = cycle))
			push!(discharge_energy, compute_discharge_energy(output; cycle_number = cycle))
			push!(charge_energy, compute_charge_energy(output; cycle_number = cycle))
			push!(round_trip_efficiency, compute_round_trip_efficiency(output; cycle_number = cycle))
		end
		capacity = compute_capacity(output)

	end

	# Dictionary of all available quantities
	available_quantities = Dict(
		"CycleNumber"         => cycle_array,
		"DischargeCapacity"   => discharge_cap,
		"ChargeCapacity"      => charge_cap,
		"DischargeEnergy"     => discharge_energy,
		"ChargeEnergy"        => charge_energy,
		"RoundTripEfficiency" => round_trip_efficiency,
		"Capacity"            => capacity,
	)

	# Add only requested quantities

	if !isnothing(metrics)
		for q in metrics
			if haskey(available_quantities, q)
				selected[Symbol(q)] = available_quantities[q]
			else
				error("Metric \"$q\" is not available. Available metrics are: $(join(keys(available_quantities), ", "))")
			end
		end
	else
		for q in keys(available_quantities)
			if haskey(available_quantities, q)
				selected[Symbol(q)] = available_quantities[q]
			else
				error("Metric \"$q\" is not available. Available metrics are: $(join(keys(available_quantities), ", "))")
			end
		end
	end

	return (; selected...)
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
  - `:NeAmRadius`: Radial coordinate for the negative electrode active material
  - `:PeAmRadius`: Radial coordinate for the positive electrode active material
- Extracts spatially resolved state data (e.g., concentration, potential) using `extract_spatial_data`.
- Filters and returns only requested quantities if `quantities` is specified.
- Ensures returned data is not `nothing`; raises an error if a requested quantity is missing or unavailable.

# Returns
A `NamedTuple` containing the selected spatial quantities and coordinates. Possible keys include:
- `:Time`
- `:Position`
- `:NeAmRadius`
- `:PeAmRadius`
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
function get_output_states(output::NamedTuple; quantities::Union{Nothing, Vector{String}} = nothing)
	# Get time and coordinates
	time = extract_output_times(output)
	padded_states = get_padded_states(output)
	x = get_x_coords(output[:extra][:model].multimodel)
	r_coords = get_r_coords(output)
	r_ne = r_coords.ne_radii
	r_pe = r_coords.pe_radii

	# Extract data
	output_data = extract_spatial_data(padded_states)

	# Initialize available quantities
	available_quantities = Dict{Symbol, Any}(
		:Time => time,
		:Position => x,
		:NeAmRadius => r_ne,
		:PeAmRadius => r_pe,
	)

	# Insert only available output_data
	for (k, v) in output_data
		available_quantities[k] = v
	end

	# Create selected output dict
	selected = Dict{Symbol, Any}()

	if isnothing(quantities)
		# Return all available quantities
		for (k, v) in available_quantities
			if !isnothing(v)
				selected[k] = v
			end
		end
	else
		# Return only requested and available quantities
		for q in quantities
			symq = Symbol(q)
			if !haskey(available_quantities, symq) || isnothing(available_quantities[symq])
				error("Quantity \"$q\" is not available. Available quantities are: $(join(Symbol.(keys(available_quantities)), ", "))")
			end
			selected[symq] = available_quantities[symq]
		end
	end

	return (; selected...)
end


function get_r_coords(output)

	particle_radius_ne = output[:extra][:cell_parameters]["NegativeElectrode"]["ActiveMaterial"]["ParticleRadius"]
	number_of_cells_ne = output[:extra][:simulation_settings]["GridResolution"]["NegativeElectrodeActiveMaterial"]
	particle_radius_pe = output[:extra][:cell_parameters]["PositiveElectrode"]["ActiveMaterial"]["ParticleRadius"]
	number_of_cells_pe = output[:extra][:simulation_settings]["GridResolution"]["PositiveElectrodeActiveMaterial"]

	ne_radii = range(0; stop = particle_radius_ne, length = number_of_cells_ne)
	pe_radii = range(0; stop = particle_radius_pe, length = number_of_cells_pe)
	return (ne_radii = ne_radii, pe_radii = pe_radii)

end


function extract_spatial_data(states::Vector)
	# Map from quantity names to symbol chains used to extract data
	var_map = Dict(
		:NeAmSurfaceConcentration => [:NeAm, :Cs],
		:PeAmSurfaceConcentration => [:PeAm, :Cs],
		:NeAmConcentration        => [:NeAm, :Cp],
		:PeAmConcentration        => [:PeAm, :Cp],
		:NeAmDiffusionCoefficient => [:NeAm, :DiffusionCoefficient],
		:PeAmDiffusionCoefficient => [:PeAm, :DiffusionCoefficient],
		:NeAmReactionRateConst    => [:NeAm, :ReactionRateConst],
		:PeAmReactionRateConst    => [:PeAm, :ReactionRateConst],
		:ElectrolyteConcentration => [:Elyte, :C],
		:NeAmPotential            => [:NeAm, :Phi],
		:ElectrolytePotential     => [:Elyte, :Phi],
		:PeAmPotential            => [:PeAm, :Phi],
		:NeAmTemperature          => [:NeAm, :Temperature],
		:PeAmTemperature          => [:PeAm, :Temperature],
		:NeAmOpenCircuitPotential => [:NeAm, :Ocp],
		:PeAmOpenCircuitPotential => [:PeAm, :Ocp],
		:NeAmCharge               => [:NeAm, :Charge],
		:ElectrolyteCharge        => [:Elyte, :Charge],
		:PeAmCharge               => [:PeAm, :Charge],
		:ElectrolyteMass          => [:Elyte, :Mass],
		:ElectrolyteDiffusivity   => [:Elyte, :Diffusivity],
		:ElectrolyteConductivity  => [:Elyte, :Conductivity],
		:SEIThickness             => [:NeAm, :SEIlength],
		:NormalizedSEIThickness   => [:NeAm, :normalizedSEIlength],
		:SEIVoltageDrop           => [:NeAm, :SEIvoltageDrop],
		:NormalizedSEIVoltageDrop => [:NeAm, :normalizedSEIvoltageDrop])

	output_data = Dict{Symbol, Any}()

	for q in keys(var_map)
		qsym = Symbol(q)

		# Validate if the quantity exists in the known map
		@assert haskey(var_map, qsym) "Quantity \"$q\" is not a valid or supported variable."

		# Check if the variable actually exists in the first state
		chain = var_map[qsym]
		try
			_ = foldl(getindex, chain; init = states[1])
		catch
			# Skip quantity if not available
			continue
		end

		# Extract data across all time steps
		raw = [foldl(getindex, chain; init = state) for state in states]  # List of arrays

		# Combine into [nx, nr, nt]
		data = [foldl(getindex, chain; init = state) for state in states]

		data = cat(raw...; dims = 3)

		# Permute to [nt, nx, nr]
		data = permutedims(data, (3, 2, 1))

		if size(data, 2) == 1
			output_data[qsym] = dropdims(data; dims = 2)
		else
			output_data[qsym] = data
		end
	end

	return output_data
end




function get_x_coords(model::MultiModel{:LithiumIonBattery})

	pp = physical_representation(model.models[:Elyte].data_domain)
	primitives = Jutul.plot_primitives(pp, :meshscatter)

	return primitives.points[:, 1]
end

function get_padded_states(output::NamedTuple)
	multimodel = output[:extra][:model].multimodel
	states = output[:states]
	model_keys = keys(multimodel.models)

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
	start_idx = Dict{Symbol, Any}()
	end_idx = Dict{Symbol, Any}()
	for k in model_keys
		start_idx[k] = Dict{Symbol, Any}()
		end_idx[k] = Dict{Symbol, Any}()
		padded_state[k] = Dict{Symbol, Any}()
	end

	# Get start indices
	# mykeys = [:NeCc, :NeAm, :Elyte, :PeAm, :PeCc]
	if :NeCc in model_keys
		start_idx[:NeCc] = 1
		start_idx[:NeAm] = ncells[:NeCc] + 1
	else
		start_idx[:NeAm] = 1
	end

	start_idx[:Elyte] = start_idx[:NeAm]
	start_idx[:PeAm] = ncells[:Elyte] - ncells[:PeAm] + 1

	if :PeCc in model_keys
		start_idx[:PeCc] = ncells[:Elyte] + 1
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

function extract_time_series_data(output::NamedTuple)

	states = output[:states]


	E = [state[:Control][:Phi][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	#time_series_data = Dict{String, Vector{Float64}}("voltage" => E, "current" => I)

	return (voltage = E, current = I)

end


function extract_output_times(output::NamedTuple)

	states = output[:states]
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
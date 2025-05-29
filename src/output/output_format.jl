export get_output_time_series, get_output_metrics, get_output_states

# for debugging
export extract_time_series_data, extract_output_times, get_multimodel_centroids, extract_spatial_data, get_simple_output


function get_output_time_series(output::NamedTuple, quantities::Vector{String})

	selected_pairs = []
	available_quantities = ["Voltage", "Current"]

	voltage, current = extract_time_series_data(output)
	time = extract_output_times(output)

	push!(selected_pairs, :Time => time)

	for q in quantities
		if q == "Voltage"
			push!(selected_pairs, :Voltage => voltage)
		elseif q == "Current"
			push!(selected_pairs, :Current => current)
		else
			error("Quantitiy $q is not available in this data")
		end
	end


	return (; selected_pairs...)
end

function get_output_metrics(
	output::NamedTuple,
	metrics::Vector{String},
)
	model = output[:extra][:model]
	states = output[:states]

	cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]

	# Prepare selected output fields
	selected = Dict{Symbol, Any}()
	selected[:CycleNumber] = cycle_array

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
	else
		# Compute per cycle
		for cycle in unique_cycles
			push!(discharge_cap, compute_discharge_capacity(output; cycle_number = cycle))
			push!(charge_cap, compute_charge_capacity(output; cycle_number = cycle))
			push!(discharge_energy, compute_discharge_energy(output; cycle_number = cycle))
			push!(charge_energy, compute_charge_energy(output; cycle_number = cycle))
			push!(round_trip_efficiency, compute_round_trip_efficiency(output; cycle_number = cycle))
		end
	end

	# Dictionary of all available quantities
	available_quantities = Dict(
		"DischargeCapacity"   => discharge_cap,
		"ChargeCapacity"      => charge_cap,
		"DischargeEnergy"     => discharge_energy,
		"ChargeEnergy"        => charge_energy,
		"RoundTripEfficiency" => round_trip_efficiency,
	)

	# Add only requested quantities
	for q in metrics
		if haskey(available_quantities, q)
			selected[Symbol(q)] = available_quantities[q]
		else
			error("Metric \"$q\" is not available. Available metrics are: $(join(keys(available_quantities), ", "))")
		end
	end

	return (; selected...)
end



function get_output_states(output::NamedTuple, quantities::Vector{String})
	# Get time
	time = extract_output_times(output)

	# Get padded states
	padded_states = get_padded_states(output)

	# Extract spatial data
	output_data = extract_spatial_data(padded_states, quantities)

# NamedTuple("Time":[nt],"X":[nx],"NeAmRadius":[nr_ne],"PeAmRadius":[nr_pe], ...
# "NeAmConcentration": [nt,nx,nr_ne], "PeAmPotential": [nt,nx,nr_pe])

	# Get coordinates
	x = get_x_coords(output[:extra][:model]) 

	return (; Time = time, x = x, output_data...)

end


function extract_spatial_data(states::Vector, quantities::Vector{String})

	# Define a mapping from variable names to symbol chains
	var_map = Dict(
		:NeAmSurfaceConcentration      => [:NeAm, :Cs],
		:PeAmSurfaceConcentration      => [:PeAm, :Cs],
		:NeAmConcentration            => [:NeAm, :Cp],
		:PeAmConcentration            => [:PeAm, :Cp],
		:ElectrolyteConcentration     => [:Elyte, :C],
		:NeAmPotential                => [:NeAm, :Phi],
		:ElectrolytePotential         => [:Elyte, :Phi],
		:PeAmPotential                => [:PeAm, :Phi],
		:NeAmTemperature              => [:NeAm, :Temperature],
		:PeAmTemperature              => [:PeAm, :Temperature],
		:NeAmOpenCircuitPotential     => [:NeAm, :Ocp],
		:PeAmOpenCircuitPotential     => [:PeAm, :Ocp],
		:NeAmCharge                   => [:NeAm, :Charge],
		:ElectrolyteCharge            => [:Elyte, :Charge],
		:PeAmCharge                   => [:PeAm, :Charge],
		:ElectrolyteMass              => [:Elyte, :Mass],
		:ElectrolyteDiffusivity       => [:Elyte, :Diffusivity],
		:ElectrolyteConductivity      => [:Elyte, :Conductivity]
	)

	output_data = Dict{Symbol, Any}()
	
	for q in quantities

		chain = var_map[Symbol(q)]
		data = [foldl(getindex, chain; init=state) for state in states]
		data = cat(data...; dims=3)
		data = permutedims(data, (3,2,1))

		if size(data, 2) == 1
			output_data[Symbol(q)] = dropdims(data; dims=2)
		else
			output_data[Symbol(q)] = data
		end

	end
	
	return output_data
end


function get_x_coords(model::MultiModel{:Battery})

	pp = physical_representation(model.models[:Elyte].data_domain)
	primitives = Jutul.plot_primitives(pp, :meshscatter)

	return primitives.points[:, 1]
end

function get_padded_states(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})
	model = output[:extra][:model]
	states = output[:states]
	model_keys = keys(model.models)

	n = length(model_keys)
	ncells = Dict{Symbol, Any}()
	active = BitArray(undef, n)
	active .= false
	total_number_of_cells = 0
	for (i, k) in enumerate(model_keys)
		pp = physical_representation(model[k].data_domain)
		if pp isa CurrentAndVoltageDomain
			keep = false
		else
			gg = model[k].domain.representation
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

function extract_time_series_data(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})

	states = output[:states]


	E = [state[:Control][:Phi][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	#time_series_data = Dict{String, Vector{Float64}}("voltage" => E, "current" => I)

	return (voltage = E, current = I)

end


function extract_output_times(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})

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
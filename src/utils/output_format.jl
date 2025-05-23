export get_output_time_series, get_output_metrics, get_output_states


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

	# Get spatial grid centroids (xyz)
	grid_data = get_multimodel_centroids(output[:extra][:model])
	xyz = grid_data.mm_grid_centroids
	map = grid_data.mm_grid_map

	# Extract the spatial data
	spatial_data = extract_spatial_data(output)

	# Radial discretization points
	radial_grid = nothing

	# Prepare selected output fields
	selected = Dict{Symbol, Any}()
	selected[:Time] = time
	selected[:xyz] = xyz
	# selected[:Radius] = radial_grid


	# Supported quantities
	available_quantities = Dict(
		"ElectrolytePotential" => spatial_data.Elyte_potential,
		"PeAmPotential" => spatial_data.PeAm_potential,
		"NeAmPotential" => spatial_data.NeAm_potential,
		"ElectrolyteConcentration" => spatial_data.Elyte_concentration,
		"PeAmSurfaceConcentration" => spatial_data.PeAm_surface_concentration,
		"NeAmSurfaceConcentration" => spatial_data.NeAm_surface_concentration,
		"PeAmConcentration" => spatial_data.PeAmParticle_concentration,
		"NeAmConcentration" => spatial_data.NeAmParticle_concentration,
		"NeAmTemperature" => spatial_data.NeAm_Temperature,
		"PeAmTemperature" => spatial_data.PeAm_Temperature,
		"NeAmOpenCicruitPotential" => spatial_data.NeAm_ocp,
		"PeAmOpenCicruitPotential" => spatial_data.PeAm_ocp,
		"NeAmCharge" => spatial_data.NeAm_charge,
		"ElyteCharge" => spatial_data.Elyte_charge,
		"PeAmCharge" => spatial_data.PeAm_charge,
		"ElectrolyteMass" => spatial_data.Elyte_mass,
		"ElectrolyteDiffusivity" => spatial_data.Elyte_diffusivity,
		"ElectrolyteConductivity" => spatial_data.Elyte_conductivity,
	)

	# Add only requested quantities
	for q in quantities
		if haskey(available_quantities, q)
			selected[Symbol(q)] = available_quantities[q]
		else
			error("Quantity $q is not available in the output.")
		end
	end

	# Convert to NamedTuple
	return (; selected...)
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



function get_multimodel_centroids(model::MultiModel{:Battery})


	# TODO get this to loop through all the models in the multi model
	Ne_grid = physical_representation(model[:NeAm])[:cell_centroids]
	Pe_grid = physical_representation(model[:PeAm])[:cell_centroids]
	Elyte_grid = physical_representation(model[:Elyte])[:cell_centroids]

	mm_grid_centroids = cat(Ne_grid, Pe_grid, Elyte_grid, dims = 2)
	mm_grid_centroids = unique(eachcol(mm_grid_centroids)) # unique coordinates
	mm_grid_centroids = hcat(mm_grid_centroids)


	NeAm_map = zeros(Int, eachindex(Ne_grid[1, :]))
	for i in eachindex(Ne_grid[1, :])  # Iterate over columns of Ne_grid
		for j in eachindex(mm_grid_centroids)  # Iterate over columns of grd
			if Ne_grid[:, i] == mm_grid_centroids[j]
				NeAm_map[i] = j
			end
		end
	end


	PeAm_map = zeros(Int, eachindex(Pe_grid[1, :]))
	for i in eachindex(Pe_grid[1, :])  # Iterate over columns of Pe_grid
		for j in eachindex(mm_grid_centroids)  # Iterate over columns of grd
			if Pe_grid[:, i] == mm_grid_centroids[j]
				PeAm_map[i] = j
			end
		end
	end

	Elyte_map = zeros(Int, eachindex(Elyte_grid[1, :]))
	for i in eachindex(Elyte_grid[1, :])  # Iterate over columns of Elyte_grid
		for j in eachindex(mm_grid_centroids)  # Iterate over columns of grd
			if Elyte_grid[:, i] == mm_grid_centroids[j]
				Elyte_map[i] = j
			end
		end
	end

	mm_grid_map = Dict(:NeAm => NeAm_map, :PeAm => PeAm_map, :Elyte => Elyte_map)


	return (mm_grid_centroids = mm_grid_centroids, mm_grid_map = mm_grid_map)

end


function extract_spatial_data(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})

	states = output[:states]


	# Surface Concentration (at the face of the surface cell)
	NeAm_surface_concentration = [state[:NeAm][:Cs] for state in states]
	PeAm_surface_concentration = [state[:PeAm][:Cs] for state in states]

	# Concentration (at the center of the discretization cells)
	NeAmParticle_concentration = [state[:NeAm][:Cp] for state in states]
	PeAmParticle_concentration = [state[:PeAm][:Cp] for state in states]
	Elyte_concentration = [state[:Elyte][:C] for state in states]

	# Potential
	NeAm_potential = [state[:NeAm][:Phi] for state in states]
	Elyte_potential = [state[:Elyte][:Phi] for state in states]
	PeAm_potential = [state[:PeAm][:Phi] for state in states]

	# Temperature
	NeAm_Temperature = [state[:NeAm][:Temperature] for state in states]
	PeAm_Temperature = [state[:PeAm][:Temperature] for state in states]

	# OCP
	NeAm_ocp = [state[:NeAm][:Ocp] for state in states]
	PeAm_ocp = [state[:PeAm][:Ocp] for state in states]

	# charge
	NeAm_charge = [state[:NeAm][:Charge] for state in states]
	Elyte_charge = [state[:Elyte][:Charge] for state in states]
	PeAm_charge = [state[:PeAm][:Charge] for state in states]

	# Mass
	Elyte_mass = [state[:Elyte][:Mass] for state in states]

	# Diffusivity
	Elyte_diffusivity = [state[:Elyte][:Diffusivity] for state in states]

	# Conductivity
	Elyte_conductivity = [state[:Elyte][:Conductivity] for state in states]




	return (
		NeAm_surface_concentration = NeAm_surface_concentration,
		PeAm_surface_concentration = PeAm_surface_concentration,
		NeAmParticle_concentration = NeAmParticle_concentration,
		PeAmParticle_concentration = PeAmParticle_concentration,
		Elyte_concentration = Elyte_concentration,
		NeAm_potential = NeAm_potential,
		Elyte_potential = Elyte_potential,
		PeAm_potential = PeAm_potential,
		NeAm_Temperature = NeAm_Temperature,
		PeAm_Temperature = PeAm_Temperature,
		NeAm_ocp = NeAm_ocp,
		PeAm_ocp = PeAm_ocp,
		NeAm_charge = NeAm_charge,
		Elyte_charge = Elyte_charge,
		PeAm_charge = PeAm_charge,
		Elyte_mass = Elyte_mass,
		Elyte_diffusivity = Elyte_diffusivity,
		Elyte_conductivity = Elyte_conductivity)

end


function get_simple_output(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})

	# Extract the time series data
	time_series = extract_time_series_data(output)

	# Extract output times
	output_times = extract_output_times(output)

	# Extract the model coordinates
	model_coords, mm_grid_map = get_multimodel_centroids(output[:extra][:model])

	# Extract the spatial data
	spatial_data = extract_spatial_data(output)

	return (time = output_times, coords = model_coords, time_series = time_series,
		Elyte_potential = spatial_data.Elyte_potential, PeAm_potential = spatial_data.PeAm_potential,
		NeAm_potential = spatial_data.NeAm_potential, PeAmParticle_potential = spatial_data.PeAmParticle_potential,
		NeAmParticle_potential = spatial_data.NeAmParticle_potential, Elyte_concentration = spatial_data.Elyte_concentration,
		PeAm_concentration = spatial_data.PeAm_concentration, NeAm_concentration = spatial_data.NeAm_concentration,
		PeAmParticle_concentration = spatial_data.PeAmParticle_concentration, NeAmParticle_concentration = spatial_data.NeAmParticle_concentration,
		Temperature = spatial_data.Temperature)

end

export get_output_time_series

export get_simple_coords
export extract_spatial_data
export get_model_coords
export get_multimodel_centroids
export get_simple_output

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
	Ne_grid = physical_representation(modelz[:NeAm])[:cell_centroids]
	Pe_grid = physical_representation(modelz[:PeAm])[:cell_centroids]
	Elyte_grid = physical_representation(modelz[:Elyte])[:cell_centroids]

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
	nx = output[:cellSpecifications][:nx]
	ny = output[:cellSpecifications][:ny]
	nz = output[:cellSpecifications][:nz]
	nt = output[:cellSpecifications][:nt]
	Elyte_potential = Array{Float64, 4}(undef, nx, ny, nz, nt)

	return states

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
# output.time = Vector{Float64}(nt)

# output.coords
# 			 .xyz = Array{Float64,2}(nc,3)
# 			 .r = Array{Float64,1}(nr)

# output.time_series
#                   .potential = Array{Float64,1}(nt)
#                   .concentration = Array{Float64}(nt)
#                   .cycle_number = Array{Float64}(nt)
# 				  .protocol_step = Array{Float64}(nt)

# 	                                              
# output.Elyte_potential = Array{Float64,2}(nc,nt)

# output.PeAm_potential = Array{Float64,2}(nc,nt)

# output.NeAm_potential = Array{Float64,2}(nc,nt)

# output.PeAmParticle_potential = Array{Float64,3)(nc,nr,nt)

# output.NeAmParticle_potential = Array{Float64,3)(nc,nr,nt)

# output.Elyte_concentration  = Array{Float64,2}(nc,nt)

# output.PeAm_concentrationn = Array{Float64,2}(nc,nt)

# output.NeAm_concentration = Array{Float64,2}(nc,nt)

# output.PeAmParticle_concentration = Array{Float64,3)(nc,nr,nt)

# output.NeAmParticle_concentration = Array{Float64,3)(nc,nr,nt)

# output.Temperature = Array{Float64,2}(nc,nt)
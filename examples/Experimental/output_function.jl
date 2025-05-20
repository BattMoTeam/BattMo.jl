using BattMo, GLMakie, Jutul

cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
model_settings = load_model_settings(; from_default_set = "P2D")

model_setup = LithiumIonBattery(; model_settings)

sim = Simulation(model_setup, cell_parameters, cycling_protocol);

output = solve(sim;)

time_series = get_output_time_series(output, ["Voltage", "Current"])


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

function get_output_state(output::NamedTuple, quantities::Vector{String})
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


states = get_output_state(output, ["PeAmPotential", "NeAmPotential"])
@info keys(states)

t = time_series[:Time]
I = time_series[:Current]
E = time_series[:Voltage]


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Voltage", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, E; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f

ax = Axis(f[1, 2], title = "Current", xlabel = "Time / s", ylabel = "Current / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, I; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f


using LinearAlgebra

export
	compute_electrode_coating_mass,
	compute_electrode_theoretical_density,
	compute_separator_mass,
	compute_current_collector_mass,
	compute_electrolyte_mass,
	compute_cell_mass,
	compute_electrode_volume_fraction,
	compute_electrode_mass_loading,
	compute_electrode_maximum_capacity,
	compute_np_ratio,
	compute_cell_theoretical_capacity,
	compute_round_trip_efficiency,
	compute_discharge_capacity,
	compute_charge_capacity,
	compute_charge_energy,
	compute_discharge_energy,
	compute_cell_volume,
	get_equilibrium_kpis


#########################################
# Get all equilibrium KPIs
#########################################

function get_equilibrium_kpis(cell_parameters::CellParameters)
	cell_kpis_from_set = Dict(
		"Positive Electrode Coating Mass" => compute_electrode_coating_mass(cell_parameters, "PositiveElectrode"),
		"Negative Electrode Coating Mass" => compute_electrode_coating_mass(cell_parameters, "NegativeElectrode"),
		"Separator Mass" => compute_separator_mass(cell_parameters),
		"Positive Electrode Current Collector Mass" => compute_current_collector_mass(cell_parameters, "PositiveElectrode"),
		"Negative Electrode Current Collector Mass" => compute_current_collector_mass(cell_parameters, "NegativeElectrode"),
		"Electrolyte Mass" => compute_electrolyte_mass(cell_parameters),
		"Cell Mass" => compute_cell_mass(cell_parameters),
		"Cell Volume" => compute_cell_volume(cell_parameters),
		"Positive Electrode Mass Loading" => compute_electrode_mass_loading(cell_parameters, "PositiveElectrode"),
		"Negative Electrode Mass Loading" => compute_electrode_mass_loading(cell_parameters, "NegativeElectrode"),
		"Cell Theoretical Capacity" => compute_cell_theoretical_capacity(cell_parameters),
		"Cell N:P Ratio" => compute_np_ratio(cell_parameters),
		"Cell Mass Composition" => compute_cell_mass_composition(cell_parameters),
	)

	return cell_kpis_from_set

end


#########################################
# Cell Mass calculations
#########################################

function compute_electrode_coating_mass(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	effective_density = params[electrode]["Coating"]["EffectiveDensity"]
	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	thickness = params[electrode]["Coating"]["Thickness"]

	return effective_density * area * thickness
end



function compute_electrode_theoretical_density(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	component_mass_fractions = [params[electrode]["ActiveMaterial"]["MassFraction"],
		params[electrode]["ConductiveAdditive"]["MassFraction"],
		params[electrode]["Binder"]["MassFraction"]]
	component_densities = [params[electrode]["ActiveMaterial"]["Density"],
		params[electrode]["ConductiveAdditive"]["Density"],
		params[electrode]["Binder"]["Density"]]

	return 1 / sum(component_mass_fractions ./ component_densities)
end



function compute_separator_mass(params::CellParameters)
	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	density = params["Separator"]["Density"]
	thickness = params["Separator"]["Thickness"]
	porosity = params["Separator"]["Porosity"]
	return thickness * area * (1 - porosity) * density
end



function compute_current_collector_mass(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	thickness = params[electrode]["CurrentCollector"]["Thickness"]
	density = params[electrode]["CurrentCollector"]["Density"]
	return area * thickness * density
end


"""

"""
function compute_electrolyte_mass(params::CellParameters)

	electrolyte_density = params["Electrolyte"]["Density"]
	cell_area = params["Cell"]["ElectrodeGeometricSurfaceArea"]

	#separator (sep)
	sep_porosity = params["Separator"]["Porosity"]
	sep_volume = cell_area * params["Separator"]["Thickness"]

	#positive electrode (pe)
	pe_theoretical_density = compute_electrode_theoretical_density(params, "PositiveElectrode")
	pe_effective_density = params["PositiveElectrode"]["Coating"]["EffectiveDensity"]
	pe_volume = cell_area * params["PositiveElectrode"]["Coating"]["Thickness"]
	pe_porosity = 1.0 - (pe_effective_density / pe_theoretical_density)

	#negative electrode (ne)
	ne_theoretical_density = compute_electrode_theoretical_density(params, "NegativeElectrode")
	ne_effective_density = params["NegativeElectrode"]["Coating"]["EffectiveDensity"]
	ne_volume = cell_area * params["NegativeElectrode"]["Coating"]["Thickness"]
	ne_porosity = 1.0 - (ne_effective_density / ne_theoretical_density)

	component_volumes = [pe_volume, ne_volume, sep_volume]
	component_porosities = [pe_porosity, ne_porosity, sep_porosity]

	return electrolyte_density * dot(component_volumes, component_porosities)
end

function compute_cell_mass(params::CellParameters; print_breakdown::Bool = false)

	masses = Dict(
		"mass_positive_electrode" => compute_electrode_coating_mass(params, "PositiveElectrode"),
		"mass_negative_electrode" => compute_electrode_coating_mass(params, "NegativeElectrode"),
		"mass_separator" => compute_separator_mass(params),
		"mass_electrolyte" => compute_electrolyte_mass(params),
	)
	total_cell_mass = masses["mass_positive_electrode"] + masses["mass_negative_electrode"] + masses["mass_separator"] + masses["mass_electrolyte"]
	if haskey(params["NegativeElectrode"], "CurrentCollector")
		masses["mass_positive_electrode_current_collector"] = compute_current_collector_mass(params, "PositiveElectrode")
		masses["mass_negative_electrode_current_collector"] = compute_current_collector_mass(params, "NegativeElectrode")
		masses["total_cell_mass"] = total_cell_mass + masses["mass_positive_electrode_current_collector"] + masses["mass_negative_electrode_current_collector"]
	else
		masses["mass_positive_electrode_current_collector"] = 0
		masses["mass_negative_electrode_current_collector"] = 0
		masses["total_cell_mass"] = total_cell_mass
	end

	composition = compute_cell_mass_composition(params)

	if print_breakdown
		print("""
				Component                 | Mass/kg |  Percentage
		-------------------------------------------------------------
		Cell                                 | $(round(masses["total_cell_mass"], digits=5)) |    100
		Positive Electrode                   | $(round(masses["mass_positive_electrode"], digits=5)) |    $(round(composition["positive_electrode"], digits=1))
		Negative Electrode                   | $(round(masses["mass_negative_electrode"], digits=5)) |    $(round(composition["negative_electrode"], digits=1))
		Positive Electrode Current Collector | $(round(masses["mass_positive_electrode_current_collector"], digits=5)) |    $(round(composition["positive_electrode_current_collector"], digits=1))
		Negative Electrode Current Collector | $(round(masses["mass_negative_electrode_current_collector"], digits=5)) |    $(round(composition["negative_electrode_current_collector"], digits=1))
		Electrolyte                          | $(round(masses["mass_electrolyte"], digits=5)) |    $(round(composition["electrolyte"], digits=1))
		Separator                            | $(round(masses["mass_separator"], digits=5)) |    $(round(composition["separator"], digits=1))
		""")

	end

	return total_cell_mass
end

function compute_cell_mass_composition(params::CellParameters)

	masses = Dict(
		"mass_positive_electrode" => compute_electrode_coating_mass(params, "PositiveElectrode"),
		"mass_negative_electrode" => compute_electrode_coating_mass(params, "NegativeElectrode"),
		"mass_separator" => compute_separator_mass(params),
		"mass_electrolyte" => compute_electrolyte_mass(params),
	)
	total_cell_mass = masses["mass_positive_electrode"] + masses["mass_negative_electrode"] + masses["mass_separator"] + masses["mass_electrolyte"]
	if haskey(params["NegativeElectrode"], "CurrentCollector")
		masses["mass_positive_electrode_current_collector"] = compute_current_collector_mass(params, "PositiveElectrode")
		masses["mass_negative_electrode_current_collector"] = compute_current_collector_mass(params, "NegativeElectrode")
		masses["total_cell_mass"] = total_cell_mass + masses["mass_positive_electrode_current_collector"] + masses["mass_negative_electrode_current_collector"]
	else
		masses["mass_positive_electrode_current_collector"] = 0
		masses["mass_negative_electrode_current_collector"] = 0
		masses["total_cell_mass"] = total_cell_mass
	end
	composition = Dict(
		"cell" => 100,
		"positive_electrode" => 100 * masses["mass_positive_electrode"] / masses["total_cell_mass"],
		"negative_electrode" => 100 * masses["mass_negative_electrode"] / masses["total_cell_mass"],
		"positive_electrode_current_collector" => 100 * get(masses, "mass_positive_electrode_current_collector", 0) / masses["total_cell_mass"],
		"negative_electrode_current_collector" => 100 * get(masses, "mass_negative_electrode_current_collector", 0) / masses["total_cell_mass"],
		"electrolyte" => 100 * masses["mass_electrolyte"] / masses["total_cell_mass"],
		"separator" => 100 * masses["mass_separator"] / masses["total_cell_mass"],
	)
	return composition
end

function compute_cell_volume(params::CellParameters)
	case = params["Cell"]["Case"]
	if case == "Pouch"

		ne_thickness = params["NegativeElectrode"]["Coating"]["Thickness"]
		pe_thickness = params["PositiveElectrode"]["Coating"]["Thickness"]
		sep_thickness = params["Separator"]["Thickness"]
		thickness = ne_thickness + pe_thickness + sep_thickness

		if haskey(params["NegativeElectrode"], "CurrentCollector")
			ne_cc_thickness = params["NegativeElectrode"]["CurrentCollector"]["Thickness"]
			pe_cc_thickness = params["PositiveElectrode"]["CurrentCollector"]["Thickness"]
			thickness = thickness + ne_cc_thickness + pe_cc_thickness
		else

			print("Volume calculated without taking into account current collectors.")
		end
		if haskey(params["Cell"], "ElectrodeGeometricSurfaceArea")
			area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
		else
			length = params["Cell"]["ElectrodeLength"]
			width = params["Cell"]["ElectrodeWidth"]
			area = length * width
		end

		volume = area * thickness

	elseif case == "Cylindrical"
		if haskey(params["Cell"], "Height") && haskey(params["Cell"], "OuterRadius")
			height = params["Cell"]["Height"]
			radius = params["Cell"]["OuterRadius"]

			volume = pi * radius^2 * height
		else
			volume = nothing
			print("Parameter set doesn't contain the required parameters to calculate the volume: ['Cell']['Height'] and ['Cell']['OuterRadius']")
		end


	else
		error("Cell Case not recognized: $case.")

	end
	return volume
end

#########################################
# Cell XXXX calculations
#########################################


function compute_electrode_volume_fraction(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	effective_density = params[electrode]["Coating"]["EffectiveDensity"]
	theoretical_density = compute_electrode_theoretical_density(params, electrode)
	return effective_density / theoretical_density
end

"""
Computes the Areal mass loading of active material on current collector (kg/m^2)
"""
function compute_electrode_mass_loading(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos.")
	end

	electrode_mass = compute_electrode_coating_mass(params, electrode)
	active_material_mass = electrode_mass * params[electrode]["ActiveMaterial"]["MassFraction"]
	electrode_area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	return active_material_mass / electrode_area
end

function compute_electrode_maximum_capacity(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos.")
	end

	electrode_mass = compute_electrode_coating_mass(params, electrode)
	mass_fraction = params[electrode]["ActiveMaterial"]["MassFraction"]
	max_concentration = params[electrode]["ActiveMaterial"]["MaximumConcentration"]
	density = params[electrode]["ActiveMaterial"]["Density"]
	stoichiometry_100 = params[electrode]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"]
	stoichiometry_0 = params[electrode]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"]

	stoichiometric_range = abs(stoichiometry_100 - stoichiometry_0)
	active_material_mass = electrode_mass * mass_fraction
	faraday_constant_Ah = FARADAY_CONSTANT / 3600.0

	return stoichiometric_range * (max_concentration / density) * active_material_mass * faraday_constant_Ah
end

function compute_np_ratio(params::CellParameters)
	pe_maximum_capacity = compute_electrode_maximum_capacity(params, "PositiveElectrode")
	ne_maximum_capacity = compute_electrode_maximum_capacity(params, "NegativeElectrode")
	return ne_maximum_capacity / pe_maximum_capacity
end

function compute_cell_theoretical_capacity(params::CellParameters)
	pe_maximum_capacity = compute_electrode_maximum_capacity(params, "PositiveElectrode")
	ne_maximum_capacity = compute_electrode_maximum_capacity(params, "NegativeElectrode")
	return min(pe_maximum_capacity, ne_maximum_capacity)
end


#########################################
# Cell XXXX from the output structure
#########################################

function compute_capacity(jutul_output::NamedTuple)
	states = jutul_output[:states]
	t = [state[:Control][:Controller].time for state in states]
	I = [state[:Control][:Current][1] for state in states]

	capacity_array = Float64[]
	push!(capacity_array, 0.0)
	for i in 2:lastindex(t)

		dt = t[i] - t[i-1]           # Time step
		avg_I = (I[i] + I[i-1]) / 2  # Average current over the interval
		dQ = avg_I * dt / 3600       # Capacity in Ah
		push!(capacity_array, capacity_array[end] + dQ)

	end

	return capacity_array

end

function compute_discharge_capacity(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]

	if hasproperty(states[end][:Control][:Controller], :numberOfCycles) && states[end][:Control][:Controller].numberOfCycles > 0
		if isnothing(cycle_number)

			error("""Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

							compute_discharge_capacity(output; cycle_number = 1)

			""")

		end
	end
	return compute_discharge_capacity(states; cycle_number = cycle_number)
end

# Helper function to get valid (non-singleton) cycle numbers
function get_valid_cycles(states)
	cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]
	cycle_counts = Dict{Int, Int}()

	for cycle in cycle_array
		cycle_counts[cycle] = get(cycle_counts, cycle, 0) + 1
	end

	# Only keep cycles that appear more than once
	valid_cycles = [cycle for (cycle, count) in cycle_counts if count > 1]
	return valid_cycles, cycle_array
end

# Updated discharge capacity function
function compute_discharge_capacity(states; cycle_number = nothing)
	t = [state[:Control][:Controller].time for state in states]
	I = [state[:Control][:Current][1] for state in states]

	valid_cycles, cycle_array = get_valid_cycles(states)

	if !isnothing(cycle_number)
		if cycle_number ∉ valid_cycles
			return 0.0  # Skip singleton cycle
		end

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]

		discharge_index = findall(x -> x > 0.0000001, I_cycle)  # Assuming discharge = I > 0
		if length(discharge_index) < 2
			return 0.0  # Not enough points to compute
		end

		I_discharge = I_cycle[discharge_index]
		t_discharge = t_cycle[discharge_index]

		diff_t = diff(t_discharge)
		I_mid = I_discharge[2:end]  # Align with Δt

		capacity = sum(diff_t .* I_mid) / 3600  # Convert to Ah
	else
		diff_t = diff(t)
		I_mid = I[2:end]
		capacity = sum(diff_t .* I_mid) / 3600
	end

	return capacity
end



function compute_charge_capacity(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]

	if hasproperty(states[end][:Control][:Controller], :numberOfCycles) && states[end][:Control][:Controller].numberOfCycles > 0
		if isnothing(cycle_number)

			error("""Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

							compute_charge_capacity(output; cycle_number = 1)

			""")

		end
	end

	return compute_charge_capacity(states; cycle_number = cycle_number)
end

function compute_charge_capacity(states; cycle_number = nothing)

	t = [state[:Control][:Controller].time for state in states]
	I = [state[:Control][:Current][1] for state in states]

	if !isnothing(cycle_number)
		cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]

		total_number_of_cycles = states[end][:Control][:Controller].numberOfCycles

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]

		charge_index = findall(x -> x < -0.0000001, I_cycle)
		if length(charge_index) < 2
			return 0.0  # Not enough points to compute
		end

		I_charge = I_cycle[charge_index]
		t_charge = t_cycle[charge_index]

		diff_t = diff(t_charge)
		I_mid = I_charge[2:end]  # Align with Δt

		capacity = sum(diff_t .* I_mid) / 3600  # Convert to Ah
	else
		diff_t = diff(t)
		I_mid = I[2:end]
		capacity = sum(diff_t .* I_mid) / 3600
	end
	return capacity
end


function compute_round_trip_efficiency(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]
	if hasproperty(states[end][:Control][:Controller], :numberOfCycles) && states[end][:Control][:Controller].numberOfCycles > 0
		if isnothing(cycle_number)

			error("""Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

							compute_round_trip_efficiency(output; cycle_number = 1)

			""")

		end
	end

	return computeEnergyEfficiency(states; cycle_number = cycle_number)
end

function compute_discharge_energy(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]

	if hasproperty(states[end][:Control][:Controller], :numberOfCycles) && states[end][:Control][:Controller].numberOfCycles > 0
		if isnothing(cycle_number)

			error("""Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

							compute_discharge_energy(output; cycle_number = 1)

			""")

		end
	end

	return compute_discharge_energy(states; cycle_number = cycle_number)
end

function compute_discharge_energy(states; cycle_number = nothing)
	# Only take discharge curves
	t = [state[:Control][:Controller].time for state in states]
	E = [state[:Control][:ElectricPotential][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	if !isnothing(cycle_number)
		cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]

		total_number_of_cycles = states[end][:Control][:Controller].numberOfCycles

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]
		E_cycle = E[cycle_index]

		discharge_index = findall(x -> x > 0.0000001, I_cycle)
		I_discharge = I_cycle[discharge_index]
		t_discharge = t_cycle[discharge_index]
		E_discharge = E_cycle[discharge_index]

		dt = diff(t_discharge)

		Emid = (E_discharge[2:end] + E_discharge[1:end-1]) ./ 2
		Imid = (I_discharge[2:end] + I_discharge[1:end-1]) ./ 2

		energy = sum(Emid .* Imid .* dt)

	else
		dt = diff(t)

		Emid = (E[2:end] + E[1:end-1]) ./ 2
		Imid = (I[2:end] + I[1:end-1]) ./ 2

		energy = sum(Emid .* Imid .* dt)

	end

	return energy

end

function compute_charge_energy(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]

	if hasproperty(states[end][:Control][:Controller], :numberOfCycles) && states[end][:Control][:Controller].numberOfCycles > 0
		if isnothing(cycle_number)

			error("""Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

							compute_discharge_energy(output; cycle_number = 1)

			""")

		end
	end

	return compute_charge_energy(states; cycle_number = cycle_number)
end

function compute_charge_energy(states; cycle_number = nothing)
	# Only take discharge curves
	t = [state[:Control][:Controller].time for state in states]
	E = [state[:Control][:ElectricPotential][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	if !isnothing(cycle_number)
		cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]

		total_number_of_cycles = states[end][:Control][:Controller].numberOfCycles

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]
		E_cycle = E[cycle_index]

		charge_index = findall(x -> x < -0.0000001, I_cycle)
		I_charge = I_cycle[charge_index]
		t_charge = t_cycle[charge_index]
		E_charge = E_cycle[charge_index]

		dt = diff(t_charge)

		Emid = (E_charge[2:end] + E_charge[1:end-1]) ./ 2
		Imid = (I_charge[2:end] + I_charge[1:end-1]) ./ 2

		energy = sum(Emid .* abs.(Imid) .* dt)

	else
		dt = diff(t)

		Emid = (E[2:end] + E[1:end-1]) ./ 2
		Imid = (I[2:end] + I[1:end-1]) ./ 2

		energy = sum(Emid .* abs.(Imid) .* dt)

	end

	return energy

end

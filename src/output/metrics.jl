export
	compute_round_trip_efficiency,
	compute_discharge_capacity,
	compute_charge_capacity,
	compute_charge_energy,
	compute_discharge_energy,
	compute_capacity




function compute_capacity(output::SimulationOutput, type)
	return compute_capacity(output.jutul_output, type)
end

function compute_capacity(jutul_output::NamedTuple, type)
	states = jutul_output[:states]
	t = [state[:Control][:Controller].time for state in states]

	if type == "Cumulative"
		I = abs.([state[:Control][:Current][1] for state in states])
	elseif type == "Net"
		I = .-[state[:Control][:Current][1] for state in states]
	else
		error("The type $type is not recognized. The following types are accepted: Cumulative, Net")
	end

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

function compute_discharge_capacity(output::SimulationOutput; cycle_number = nothing)
	return compute_discharge_capacity(output.jutul_output; cycle_number = cycle_number)
end

function compute_discharge_capacity(jutul_output::NamedTuple; cycle_number = nothing)
	states = jutul_output[:states]
	state_end = states[end]

	if hasproperty(state_end[:Control][:Controller], :numberOfCycles) && state_end[:Control][:Controller].numberOfCycles > 0
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

	cycle_array = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : [state[:Control][:Controller].cycle_count for state in states]
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
		I_mid = abs.(I_discharge[2:end])  # Align with Δt

		capacity = sum(diff_t .* I_mid) / 3600  # Convert to Ah
	else
		diff_t = diff(t)
		I_mid = abs.(I[2:end])
		capacity = sum(diff_t .* I_mid) / 3600
	end

	return capacity
end

function compute_charge_capacity(output::SimulationOutput; cycle_number = nothing)
	return compute_charge_capacity(output.jutul_output; cycle_number = cycle_number)
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
		cycle_array = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : [state[:Control][:Controller].cycle_count for state in states]

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
		I_mid = abs.(I_charge[2:end])  # Align with Δt

		capacity = sum(diff_t .* I_mid) / 3600  # Convert to Ah
	else
		diff_t = diff(t)
		I_mid = abs.(I[2:end])
		capacity = sum(diff_t .* I_mid) / 3600
	end
	return capacity
end

function compute_round_trip_efficiency(output::SimulationOutput; cycle_number = nothing)
	return compute_round_trip_efficiency(output.jutul_output; cycle_number = cycle_number)
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

function compute_discharge_energy(output::SimulationOutput; cycle_number = nothing)
	return compute_discharge_energy(output.jutul_output; cycle_number = cycle_number)
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
		cycle_array = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : [state[:Control][:Controller].cycle_count for state in states]

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]
		E_cycle = E[cycle_index]

		discharge_index = findall(x -> x > 0.0000001, I_cycle)
		I_discharge = I_cycle[discharge_index]
		t_discharge = t_cycle[discharge_index]
		E_discharge = E_cycle[discharge_index]

		dt = diff(t_discharge)

		Emid = (E_discharge[2:end] + E_discharge[1:(end-1)]) ./ 2
		Imid = (I_discharge[2:end] + I_discharge[1:(end-1)]) ./ 2

		energy = sum(Emid .* Imid .* dt)

	else
		dt = diff(t)

		Emid = (E[2:end] + E[1:(end-1)]) ./ 2
		Imid = (I[2:end] + I[1:(end-1)]) ./ 2

		energy = sum(Emid .* Imid .* dt)

	end

	return energy

end


function compute_charge_energy(output::SimulationOutput; cycle_number = nothing)
	return compute_charge_energy(output.jutul_output; cycle_number = cycle_number)
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
		cycle_array = hasproperty(states[1][:Control][:Controller], :numberOfCycles) ? [state[:Control][:Controller].numberOfCycles for state in states] : [state[:Control][:Controller].cycle_count for state in states]

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I_cycle = I[cycle_index]
		t_cycle = t[cycle_index]
		E_cycle = E[cycle_index]

		charge_index = findall(x -> x < -0.0000001, I_cycle)
		I_charge = I_cycle[charge_index]
		t_charge = t_cycle[charge_index]
		E_charge = E_cycle[charge_index]

		dt = diff(t_charge)

		Emid = (E_charge[2:end] + E_charge[1:(end-1)]) ./ 2
		Imid = (I_charge[2:end] + I_charge[1:(end-1)]) ./ 2

		energy = sum(Emid .* abs.(Imid) .* dt)

	else
		dt = diff(t)

		Emid = (E[2:end] + E[1:(end-1)]) ./ 2
		Imid = (I[2:end] + I[1:(end-1)]) ./ 2

		energy = sum(Emid .* abs.(Imid) .* dt)

	end

	return energy

end

export
    compute_lithium_inventory,
    compute_round_trip_efficiency,
    compute_discharge_capacity,
    compute_charge_capacity,
    compute_charge_energy,
    compute_discharge_energy,
    compute_capacity

"""
    compute_lithium_inventory(sim::Simulation, state; baseline_state)

Compute lithium inventories in mol from a raw Jutul P2D state and fixed simulation geometry.
Particle concentrations are averaged with radial shell volumes. `sei_added` counts only
growth since the explicitly supplied BOL `baseline_state`, which must be retained across
restarts with the same mesh and SEI normalization. `total = mobile + sei_added` is conserved
in a closed cell. `sei_loss_ah` is the inventory loss in Ah, not the delivered RPT capacity.
For example, use `output.jutul_output.states[end]` and the original `sim.initial_state`.
"""
function compute_lithium_inventory(sim::Simulation, state; baseline_state)
    model = sim.model.multimodel
    electrode_names = (:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial)
    negative, positive = map(electrode_names) do name
        system = model[name].system
        discretisation_type(system) == :P2Ddiscretization ||
            throw(ArgumentError("Lithium inventory requires P2D particle concentrations."))
        shell_volumes = system.discretization[:vols]
        particle_volume = sum(shell_volumes)
        concentrations = state[name][:ParticleConcentration]
        parameters = sim.parameters[name]
        volumes = parameters[:Volume]
        solid_fractions = parameters[:VolumeFraction]
        active_fraction = system.params[:volume_fractions][1]
        sum(eachindex(volumes)) do cell
            average_concentration = sum(
                shell_volumes[shell] * concentrations[shell, cell]
                    for shell in eachindex(shell_volumes)
            ) / particle_volume
            volumes[cell] * solid_fractions[cell] * active_fraction * average_concentration
        end
    end
    electrolyte_parameters = sim.parameters[:Electrolyte]
    electrolyte = sum(
        electrolyte_parameters[:Volume][cell] * electrolyte_parameters[:VolumeFraction][cell] *
            state[:Electrolyte][:ElectrolyteConcentration][cell]
            for cell in eachindex(electrolyte_parameters[:Volume])
    )
    mobile = negative + positive + electrolyte
    sei_added = zero(mobile)
    name = :NegativeElectrodeActiveMaterial
    if model[name] isa SEImodel
        params = model[name].system.params
        thickness = state[name][:NormalizedSEIThickness]
        baseline_thickness = baseline_state[name][:NormalizedSEIThickness]
        length(thickness) == length(baseline_thickness) ||
            throw(DimensionMismatch("The BOL state must use the same electrode mesh."))
        area = sim.parameters[name][:Volume] .* params[:volumetric_surface_area]
        conversion = params[:InitialThickness] * params[:StoichiometricCoefficient] / params[:MolarVolume]
        sei_added = sum(
            area[cell] * conversion * (thickness[cell] - baseline_thickness[cell])
                for cell in eachindex(thickness)
        )
    end
    return (;
        negative, positive, electrolyte, sei_added, mobile,
        total = mobile + sei_added,
        sei_loss_ah = FARADAY_CONSTANT * sei_added / 3600,
    )
end


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

        dt = t[i] - t[i - 1]           # Time step
        avg_I = (I[i] + I[i - 1]) / 2  # Average current over the interval
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

            error(
                """Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

                				compute_discharge_capacity(output; cycle_number = 1)

                """
            )

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

            error(
                """Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

                				compute_charge_capacity(output; cycle_number = 1)

                """
            )

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

            error(
                """Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

                				compute_round_trip_efficiency(output; cycle_number = 1)

                """
            )

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

            error(
                """Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

                				compute_discharge_energy(output; cycle_number = 1)

                """
            )

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

        Emid = (E_discharge[2:end] + E_discharge[1:(end - 1)]) ./ 2
        Imid = (I_discharge[2:end] + I_discharge[1:(end - 1)]) ./ 2

        energy = sum(Emid .* Imid .* dt)

    else
        dt = diff(t)

        Emid = (E[2:end] + E[1:(end - 1)]) ./ 2
        Imid = (I[2:end] + I[1:(end - 1)]) ./ 2

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

            error(
                """Your states contain data for multiple cycles. Please provide the cycle number from which you'd like to compute the capacity:

                				compute_discharge_energy(output; cycle_number = 1)

                """
            )

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

        Emid = (E_charge[2:end] + E_charge[1:(end - 1)]) ./ 2
        Imid = (I_charge[2:end] + I_charge[1:(end - 1)]) ./ 2

        energy = sum(Emid .* abs.(Imid) .* dt)

    else
        dt = diff(t)

        Emid = (E[2:end] + E[1:(end - 1)]) ./ 2
        Imid = (I[2:end] + I[1:(end - 1)]) ./ 2

        energy = sum(Emid .* abs.(Imid) .* dt)

    end

    return energy

end

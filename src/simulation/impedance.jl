export compute_impedance, impedance_simulation

"""
    impedance_simulation(cell_parameters; soc = 0.5)

Set up a zero-current P2D lithium-ion battery simulation for impedance
calculations at the given state of charge.
"""
function impedance_simulation(
        cell_parameters::CellParameters;
        soc::Real = 0.5,
        model_settings = load_model_settings(; from_default_set = "p2d"),
        simulation_settings = load_simulation_settings(; from_default_set = "p2d"),
        initial_temperature::Real = 298.15,
    )
    0 <= soc <= 1 || throw(ArgumentError("soc must be between zero and one"))

    cycling_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => [0.0, 1.0],
            "Currents" => [0.0, 0.0],
            "LowerVoltageLimit" => 0.0,
            "UpperVoltageLimit" => 6.0,
            "InitialStateOfCharge" => soc,
            "InitialTemperature" => initial_temperature,
        )
    )
    model = LithiumIonBattery(; model_settings)
    return Simulation(
        model,
        cell_parameters,
        cycling_protocol;
        simulation_settings,
    )
end

function impedance_jacobian!(storage, simulator, model, forces, dt)
    Jutul.update_state_dependents!(storage, model, dt, forces; time = 0.0)
    Jutul.update_linearized_system!(storage, model, simulator.executor)
    return copy(storage.LinearizedSystem.jac)
end

"""
    compute_impedance(simulation, frequencies; state = simulation.initial_state)

Compute the small-signal battery impedance in ohms at `frequencies` in Hz.

The linearization uses the Jutul backward-Euler Jacobian at two time-step
sizes to recover the algebraic and accumulation matrices. The perturbation is
applied to the external boundary-current equation and the returned response is
the terminal-voltage perturbation per ampere.
"""
function compute_impedance(
        simulation::Simulation,
        frequencies::AbstractVector{<:Real};
        state = simulation.initial_state,
        assembly_dt::Real = 1.0,
    )
    assembly_dt > 0 || throw(ArgumentError("assembly_dt must be positive"))
    all(f -> f >= 0, frequencies) ||
        throw(ArgumentError("frequencies must be non-negative"))

    model = simulation.model.multimodel
    simulator = Simulator(
        model;
        state0 = deepcopy(state),
        parameters = simulation.parameters,
        copy_state = true,
    )
    storage = simulator.storage

    jac_dt = impedance_jacobian!(
        storage,
        simulator,
        model,
        simulation.forces,
        assembly_dt,
    )
    jac_2dt = impedance_jacobian!(
        storage,
        simulator,
        model,
        simulation.forces,
        2 * assembly_dt,
    )

    accumulation = 2 * assembly_dt * (jac_dt - jac_2dt)
    algebraic = 2 * jac_2dt - jac_dt

    voltage_index = only(
        setup_subset_residual_map(model, storage, [:Control], :ElectricPotential)
    )
    current_equation_index = only(
        setup_subset_equation_map(model, storage, [:Control], :charge_conservation)
    )
    current_perturbation = zeros(size(algebraic, 1))
    current_perturbation[current_equation_index] = 1.0

    return map(frequencies) do frequency
        system = algebraic + (2im * pi * frequency) * accumulation
        response = system \ current_perturbation
        response[voltage_index]
    end
end

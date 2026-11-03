using BattMo
using Jutul
using Test

@testset "Input current capacity uses accepted interval currents" begin
    times = [0.0, 2.0, 5.0]
    currents = [10.0, -3.0, 2.0]
    states = [
        Dict(
            :Control => Dict(
                :Controller => BattMo.InputCurrentController(current, time, false),
                :Current => [current],
            ),
        ) for (time, current) in zip(times, currents)
    ]
    hour = Jutul.si_unit("hour")
    expected_cumulative = [0.0, 6.0, 12.0] ./ hour
    expected_net = [0.0, 6.0, 0.0] ./ hour
    @test BattMo.compute_capacity((; states), "Cumulative") ≈ expected_cumulative atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity((; states), "Net") ≈ expected_net atol = 1.0e-12 rtol = 0

    # Excluding the initial state must not discard the charge carried by the first step.
    accepted_states = (; states = states[2:end])
    @test BattMo.compute_capacity(accepted_states, "Cumulative") ≈ expected_cumulative[2:end] atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity(accepted_states, "Net") ≈ expected_net[2:end] atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity((; states = states[2:2]), "Net") ≈ [6.0 / hour] atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity((; states = states[1:1]), "Net") ≈ [0.0] atol = 1.0e-12 rtol = 0

    # Existing interpolation-based reporting remains unchanged for other policies.
    for (state, time, current) in zip(states, times, currents)
        state[:Control][:Controller] = BattMo.FunctionController(current, time, false)
    end
    @test BattMo.compute_capacity((; states), "Cumulative") ≈ [0.0, 13.0, 20.5] ./ hour atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity((; states), "Net") ≈ [0.0, -7.0, -5.5] ./ hour atol = 1.0e-12 rtol = 0
end

@testset "Capacity includes adaptive substates on the report grid" begin
    function saved_current_state(time, current; voltage_control = false)
        target = voltage_control ? 4.2 : current
        return Dict{Symbol, Any}(
            :Control => Dict{Symbol, Any}(
                :Controller => BattMo.InputCurrentController(target, time, voltage_control),
                :Current => [current],
            ),
        )
    end

    initial_state = saved_current_state(0.0, 9.0)
    first_substate = saved_current_state(1.0, -4.0; voltage_control = true)
    first_substate[:substates] = [saved_current_state(0.5, -2.0)]
    first_report = saved_current_state(2.0, 2.0)
    # Some output includes the report endpoint among its saved substates.
    first_report[:substates] = [first_substate, deepcopy(first_report)]
    last_report = saved_current_state(4.0, 3.0)
    last_report[:substates] = [saved_current_state(3.0, -1.0; voltage_control = true)]
    states = [initial_state, first_report, last_report]
    original_states = repr(states)
    hour = Jutul.si_unit("hour")

    # Each endpoint current applies only to its accepted interval, including CV intervals.
    for (type, expected) in (("Cumulative", [0.0, 5.0, 9.0]), ("Net", [0.0, 1.0, -1.0]))
        @test BattMo.compute_capacity((; states), type) ≈ expected ./ hour atol = 1.0e-12 rtol = 0
        @test BattMo.compute_capacity((; states = states[2:end]), type) ≈
            expected[2:end] ./ hour atol = 1.0e-12 rtol = 0
    end
    expanded = BattMo.expand_report_states(states)
    @test [state[:Control][:Controller].time for state in expanded.states] ==
        [0.0, 0.5, 1.0, 2.0, 3.0, 4.0]
    @test expanded.report_indices == [1, 4, 6]
    @test all(expanded.states[index] === state for (index, state) in zip(expanded.report_indices, states))
    @test BattMo.expand_report_states(states[2:end]).report_indices == [3, 5]
    @test repr(states) == original_states
    @test_throws ArgumentError BattMo.expand_report_states(reverse(states))
    @test isempty(BattMo.expand_report_states(empty(states)).states)
    @test isempty(BattMo.expand_report_states(empty(states)).report_indices)
    @test isempty(BattMo.compute_capacity((; states = empty(states)), "Net"))

    # Other policies keep trapezoidal integration, now including accepted substates.
    for state in [expanded.states; first_report[:substates][end]]
        controller = state[:Control][:Controller]
        state[:Control][:Controller] =
            BattMo.FunctionController(controller.target, controller.time, controller.target_is_voltage)
    end
    @test BattMo.compute_capacity((; states), "Cumulative") ≈
        [0.0, 7.25, 10.75] ./ hour atol = 1.0e-12 rtol = 0
    @test BattMo.compute_capacity((; states), "Net") ≈ [0.0, 0.75, -0.75] ./ hour atol = 1.0e-12 rtol = 0
end

@testset "Input current preserves timestep charge" begin
    times = [0.0, 2.0, 6.0, 10.0]
    currents = [-8.0, -8.0, -2.0, 0.0]
    policy = BattMo.InputCurrentPolicy(times, currents, 3.0, 4.2)
    expected_charge = BattMo.trapz(times, currents)

    # Coarse timesteps and adaptive substeps must deliver the same prescribed charge.
    for partition in (times, [0.0, 10.0], [0.0, 0.25, 2.0, 3.0, 5.5, 6.0, 9.0, 10.0])
        applied_charge = 0.0
        for index in 2:length(partition)
            start_time = partition[index - 1]
            end_time = partition[index]
            state0 = (Controller = BattMo.InputCurrentController(0.0, start_time, false),)
            state = (
                Controller = BattMo.InputCurrentController(0.0, start_time, false),
                ElectricPotential = [3.7],
            )
            BattMo.update_controller!(state, state0, policy, end_time - start_time)
            @test !state.Controller.target_is_voltage
            @test state.Controller.time ≈ end_time atol = 1.0e-12 rtol = 0
            applied_charge += state.Controller.target * (end_time - start_time)
        end
        @test applied_charge ≈ expected_charge atol = 1.0e-12 rtol = 1.0e-12
    end

    # An interval crossing several knots integrates the original linear profile.
    interior_times = [1.0, 2.0, 6.0, 9.0]
    interior_currents = policy.current_function.(interior_times)
    @test BattMo.average_input_current(policy, 1.0, 9.0) * 8.0 ≈
        BattMo.trapz(interior_times, interior_currents) atol = 1.0e-12 rtol = 1.0e-12

    # Outside the recorded interval the instantaneous interpolation remains capped.
    @test BattMo.average_input_current(policy, -2.0, 12.0) * 14.0 ≈
        expected_charge - 16.0 atol = 1.0e-12 rtol = 1.0e-12
    @test BattMo.average_input_current(policy, 6.0, 6.0) ≈ -2.0 atol = 1.0e-12 rtol = 0
    @test policy.current_function(4.0) ≈ -5.0 atol = 1.0e-12 rtol = 0
end

@testset "Input current voltage limits use timestep average" begin
    function controller_target(currents, voltage; previous_voltage_control = false)
        policy = BattMo.InputCurrentPolicy([0.0, 10.0], currents, 3.0, 4.2)
        state0 = (Controller = BattMo.InputCurrentController(0.0, 0.0, previous_voltage_control),)
        state = (
            Controller = BattMo.InputCurrentController(0.0, 0.0, false),
            ElectricPotential = [voltage],
        )
        BattMo.update_controller!(state, state0, policy, 10.0)
        return state.Controller
    end

    # A taper reaching zero still carries charge during the timestep.
    charging = controller_target([-10.0, 0.0], 4.2)
    @test charging.target_is_voltage
    @test charging.target ≈ 4.2 atol = 1.0e-12 rtol = 0

    # The timestep can discharge overall even if its final current is negative.
    discharging = controller_target([5.0, -1.0], 2.9)
    @test discharging.target_is_voltage
    @test discharging.target ≈ 3.0 atol = 1.0e-12 rtol = 0

    rest = controller_target([0.0, 0.0], 4.3; previous_voltage_control = true)
    @test !rest.target_is_voltage
    @test rest.target ≈ 0.0 atol = 1.0e-12 rtol = 0

    near_cutoff = controller_target([5.0, 5.0], 3.0 * (1 + 5.0e-5); previous_voltage_control = true)
    @test near_cutoff.target_is_voltage
    @test near_cutoff.target ≈ 3.0 atol = 1.0e-12 rtol = 0

    reversed = controller_target([-5.0, -5.0], 3.0; previous_voltage_control = true)
    @test !reversed.target_is_voltage
    @test reversed.target ≈ -5.0 atol = 1.0e-12 rtol = 0
end

@testset "InputCurrentSeries" begin

    @test begin

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        model_settings = load_model_settings(; from_default_set = "p2d")
        simulation_settings = load_simulation_settings(; from_default_set = "p2d")

        model_setup = LithiumIonBattery(; model_settings)

        n_discharge = 20
        n_rest = 10
        t_discharge = range(0.0, 1000, n_discharge)
        t_rest = t_discharge[end] .+ range(0.0, 500, n_rest)
        times = [t_discharge; t_rest[2:end]]
        currents = [5.0 .* ones(n_discharge); zeros(n_rest - 1)]

        cycling_protocol = CyclingProtocol(
            Dict(
                "Protocol" => "InputCurrentSeries",
                "Times" => times,
                "Currents" => currents,
                "LowerVoltageLimit" => 2.4,
                "UpperVoltageLimit" => 4.1,
                "InitialStateOfCharge" => 0.99,
                "InitialTemperature" => 298.15,
            )
        )

        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series

        I = time_series["Current"]
        V = time_series["Voltage"]

        # The simulation should produce at least as many time steps as the series
        @test length(I) >= length(times) - 1

        # Voltage should stay above the lower cutoff voltage
        @test all(V .>= 2.4 - 1.0e-3)

        # Voltage should stay below the upper cutoff voltage
        @test all(V .<= 4.1 + 1.0e-3)

        # Initial current should be approximately 5 A (discharging)
        @test I[2] ≈ 5.0 atol = 1.0e-1

        true

    end

end

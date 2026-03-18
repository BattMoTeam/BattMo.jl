using BattMo
using Test
import Random: seed!

@testset "InputCurrentSeries" begin

    @test begin

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        model_settings = load_model_settings(; from_default_set = "p2d")
        simulation_settings = load_simulation_settings(; from_default_set = "p2d")

        model_setup = LithiumIonBattery(; model_settings)

        # Build a simple discharging time series with 30 slightly non-uniform steps:
        # 20 steps of ~125 s discharge at ~5 A, then 10 steps of ~50 s rest at 0 A.
        # The slightly non-uniform spacing (±10 s jitter) exercises the interpolator.
        seed!(42)
        n_discharge = 20
        n_rest = 10
        t_discharge = cumsum(125.0 .+ 10.0 .* (0.5 .- rand(n_discharge)))
        t_rest = t_discharge[end] .+ cumsum(50.0 .+ 5.0 .* (0.5 .- rand(n_rest)))
        times = [0.0; t_discharge; t_rest]
        currents = [5.0 .* ones(n_discharge + 1); zeros(n_rest)]

        cycling_protocol = CyclingProtocol(Dict(
            "Protocol"             => "InputCurrentSeries",
            "Times"                => times,
            "Currents"             => currents,
            "LowerVoltageLimit"    => 2.4,
            "UpperVoltageLimit"    => 4.1,
            "InitialStateOfCharge" => 0.99,
            "InitialTemperature"   => 298.15,
        ))

        sim    = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series

        I = time_series["Current"]
        V = time_series["Voltage"]

        # The simulation should produce at least as many time steps as the series
        @test length(I) >= length(times) - 1

        # Voltage should stay above the lower cutoff voltage
        @test all(V .>= 2.4 - 1e-3)

        # Voltage should stay below the upper cutoff voltage
        @test all(V .<= 4.1 + 1e-3)

        # Initial current should be approximately 5 A (discharging)
        @test I[2] ≈ 5.0 atol = 1e-1

        true

    end

end

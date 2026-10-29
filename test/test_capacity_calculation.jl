using BattMo
using Test


@testset "capacity calculation" begin

    @test begin

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")

        model_setup = LithiumIonBattery()

        sim = Simulation(model_setup, cell_parameters, cycling_protocol)

        output = solve(sim)

        cumulative_capacity = output.time_series["CumulativeCapacity"]
        net_capacity = output.time_series["NetCapacity"]
        discharge_capacity = output.metrics["DischargeCapacity"]
        charge_capacity = output.metrics["ChargeCapacity"]

        # The CCCV protocol uses the current ramp up of the default model settings, which refines the first time step
        @test length(cumulative_capacity) ≈ 790 atol = 1
        @test length(net_capacity) ≈ 790 atol = 1
        @test cumulative_capacity[5] ≈ 0.060563677082886805 atol = 1.0e-2
        @test cumulative_capacity[end - 5] ≈ 23.108119914501906 atol = 1.0e-1
        @test net_capacity[5] ≈ 0.060563677082886805 atol = 1.0e-2
        @test net_capacity[end - 5] ≈ 0.6254236157341587 atol = 1.0e-1

        @test length(discharge_capacity) ≈ 3 atol = 1
        @test length(charge_capacity) ≈ 3 atol = 1
        @test discharge_capacity[1] ≈ 3.6764157469683036 atol = 1.0e-1
        @test discharge_capacity[2] ≈ 3.6764157469683036 atol = 1.0e-1
        @test charge_capacity[1] ≈ 4.308165734095956 atol = 1.0e-1
        @test charge_capacity[2] ≈ 3.692554997719367 atol = 1.0e-1


        true

    end

end

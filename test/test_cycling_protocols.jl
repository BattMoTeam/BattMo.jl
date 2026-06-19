using BattMo
using Test

@testset "CCCV switch ramp-up" begin
    policy = BattMo.CyclingCVPolicy(
        3.0,
        4.0,
        1.0e-4,
        1.0e-4,
        "charging",
        1;
        ImaxDischarge = 1.0,
        ImaxCharge = 1.0,
        use_ramp_up = true,
        rampup_time = 100.0,
    )

    controller0 = BattMo.CcCvController()
    controller0.ctrlType = BattMo.cc_charge1
    controller0.time = 0.0
    controller0.target = -1.0

    controller = copy(controller0)

    state0 = (
        Controller = controller0,
        ElectricPotential = [4.0],
        Current = [-1.0],
    )
    state = (
        Controller = controller,
        ElectricPotential = [4.01],
        Current = [-0.8],
    )

    BattMo.update_control_type_in_controller!(state, state0, policy, 10.0)

    @test controller.ctrlType == BattMo.cv_charge2
    @test controller.ramp_active
    @test controller.ramp_target_is_voltage

    BattMo.update_values_in_controller!(state, policy)

    @test controller.target_is_voltage
    @test controller.target ≈ 4.01

    controller.time = 60.0
    BattMo.update_values_in_controller!(state, policy)

    @test 4.0 < controller.target < 4.01
end

@testset "CCCV CVCurrentCutoff" begin
    policy = BattMo.CyclingCVPolicy(
        3.0,
        4.0,
        1.0e-4,
        1.0e-4,
        "charging",
        1;
        ImaxDischarge = 1.0,
        ImaxCharge = 1.0,
        cv_current_cutoff = 0.05,
    )

    controller = BattMo.CcCvController()
    controller.ctrlType = BattMo.cv_charge2
    controller.dIdt = 1.0

    before_state = (
        Controller = controller,
        ElectricPotential = [4.0],
        Current = [-0.06],
    )
    before_flags = BattMo.setupRegionSwitchFlags(policy, before_state, BattMo.cv_charge2)
    @test before_flags.beforeSwitchRegion
    @test !before_flags.afterSwitchRegion

    after_state = (
        Controller = controller,
        ElectricPotential = [4.0],
        Current = [-0.04],
    )
    after_flags = BattMo.setupRegionSwitchFlags(policy, after_state, BattMo.cv_charge2)
    @test !after_flags.beforeSwitchRegion
    @test after_flags.afterSwitchRegion
end
@testset "Crate" begin

    @test begin

        ############################
        # cc_discharge

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        model_settings = load_model_settings(; from_default_set = "p2d")
        simulation_settings = load_simulation_settings(; from_default_set = "p2d")

        model_setup = LithiumIonBattery(; model_settings)

        cycling_protocol["DRate"] = 1

        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series

        I_1 = time_series["Current"]

        @test I_1[2] ≈ 2.2957366076223953 atol = 1.0e-1

        cycling_protocol["DRate"] = 2

        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series

        I_2 = time_series["Current"]

        @test I_2[2] ≈ I_1[2] * 2 atol = 1.0e-2


        ############################
        # cc_charge

        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_charge")
        cycling_protocol["CRate"] = 1
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series

        I_1 = time_series["Current"]

        @test I_1[2] ≈ -2.2957366076223953 atol = 1.0e-1

        cycling_protocol["CRate"] = 2
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series

        I_2 = time_series["Current"]

        @test I_2[2] ≈ I_1[2] * 2 atol = 1.0e-2

        ############################
        # constant_current_cycling

        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_cycling")
        cycling_protocol["CRate"] = 1
        cycling_protocol["DRate"] = 1
        cycling_protocol["InitialControl"] = "charging"
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series

        I_1 = time_series["Current"]

        @test I_1[2] ≈ -5.090421803494574 atol = 1.0e-1
        @test I_1[50] ≈ 5.090421803494574 atol = 1.0e-1

        cycling_protocol["CRate"] = 2
        cycling_protocol["DRate"] = 2
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series

        I_2 = time_series["Current"]

        @test I_2[2] ≈ I_1[2] * 2 atol = 1.0e-2
        @test I_2[50] ≈ I_1[50] * 2 atol = 1.0e-2


        ############################
        # cccv

        cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")
        cycling_protocol["CRate"] = 1
        cycling_protocol["DRate"] = 1
        cycling_protocol["InitialControl"] = "charging"
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series


        I_1 = time_series["Current"]


        @test I_1[2] ≈ -5.090421803494574 atol = 1.0e-1
        @test I_1[765] ≈ 5.090421803494574 atol = 1.0e-1

        cycling_protocol["CRate"] = 2
        cycling_protocol["DRate"] = 2
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)
        time_series = output.time_series

        I_2 = time_series["Current"]

        @test I_2[2] ≈ I_1[2] * 2 atol = 1.0e-2
        @test I_2[200] ≈ I_1[765] * 2 atol = 1.0e-2

        true

    end

end


@testset "defaults" begin

    @test begin

        ############################
        # cc_discharge

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        model_settings = load_model_settings(; from_default_set = "p2d")
        simulation_settings = load_simulation_settings(; from_default_set = "p2d")

        model_setup = LithiumIonBattery(; model_settings)

        cycling_protocol["DRate"] = 1

        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series
        states = output.states

        I = time_series["Current"]
        V = time_series["Voltage"]

        c_pe = states["PositiveElectrode"]["ActiveMaterial"]["SurfaceConcentration"]

        @test length(I) ≈ 73 atol = 0
        @test I[2] ≈ 2.2957366076223953 atol = 1.0e-1
        @test V[2] ≈ 4.052549590713088 atol = 1.0e-1
        @test I[50] ≈ 5.090421803494574 atol = 1.0e-1
        @test V[50] ≈ 3.387878052062845 atol = 1.0e-1
        @test I[end] ≈ 5.090421803494574 atol = 1.0e-1
        @test V[end] ≈ 2.525881189309425 atol = 1.0e-1

        @test c_pe[2, 23] ≈ 18084.221948561288 atol = 1.0e-1
        @test c_pe[end, 23] ≈ 57329.88050522005 atol = 1.0e-1


        cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")


        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        time_series = output.time_series
        states = output.states

        I = time_series["Current"]
        V = time_series["Voltage"]

        c_pe = states["PositiveElectrode"]["ActiveMaterial"]["SurfaceConcentration"]

        @test length(I) ≈ 66 atol = 0
        @test I[2] ≈ 0.06995247074831962 atol = 1.0e-1
        @test V[2] ≈ 3.274161650306443 atol = 1.0e-1
        @test I[50] ≈ 0.15510820410462878 atol = 1.0e-1
        @test V[50] ≈ 2.970719407727666 atol = 1.0e-1
        @test I[end] ≈ 0.15510820410462878 atol = 1.0e-1
        @test V[end] ≈ 2.4828541359956477 atol = 1.0e-1

        @test c_pe[2, 23] ≈ 4136.663569002932 atol = 1.0e-1
        @test c_pe[end, 23] ≈ 23253.507723804327 atol = 1.0e-1

        true


    end

end

using BattMo
using Test

function coarse_sequential_calibration_simulation()
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] =
        cell_parameters["Separator"]["BruggemanCoefficient"]

    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    cycling_protocol["InitialStateOfCharge"] = 0.8
    cycling_protocol["LowerVoltageLimit"] = 2.0
    cycling_protocol["DRate"] = 0.5

    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["NegativeElectrodeCoatingGridPoints"] = 3
    simulation_settings["PositiveElectrodeCoatingGridPoints"] = 3
    simulation_settings["NegativeElectrodeParticleGridPoints"] = 3
    simulation_settings["PositiveElectrodeParticleGridPoints"] = 3
    simulation_settings["SeparatorGridPoints"] = 2

    model = LithiumIonBattery()
    return Simulation(
        model,
        cell_parameters,
        cycling_protocol;
        simulation_settings,
        time_steps = [1.0, 1.0, 1.0],
    )
end

@testset "Sequential calibration helpers" begin
    catalog = sequential_parameter_catalog()

    @test haskey(catalog, "ne_j0")
    @test catalog["ne_j0"].scaling == :log
    @test catalog["ne_bg"].scaling == :linear

    groups = create_clustered_parameter_groups(
        ["ne_j0", "pe_j0", "ne_D", "pe_D"],
        [10.0, 1.0, 0.01, 0.001];
        strategy = :magnitude,
    )

    @test first(groups).name == "High_Sensitivity"
    @test first(groups).parameters == ["ne_j0"]
    @test issorted([group.priority for group in groups])

    @test_throws ArgumentError create_clustered_parameter_groups(["ne_j0"], [1.0, 2.0])
    @test_throws ArgumentError create_clustered_parameter_groups(
        ["ne_j0"],
        [1.0];
        strategy = :unknown,
    )
end

@testset "Sequential calibration" begin
    sim = coarse_sequential_calibration_simulation()
    solver_settings = load_solver_settings(; from_default_set = "direct")

    output = solve(sim; solver_settings, info_level = -1)
    time = output.time_series["Time"]
    voltage = output.time_series["Voltage"]
    target_voltage = voltage .+ 1.0e-3

    initial_reaction_rate =
        sim.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]
    result = calibrate_sequential_group(
        sim,
        time,
        target_voltage,
        ["ne_j0"];
        solver_settings,
        maxit = 1,
        print = 0,
    )
    calibrated_reaction_rate =
        result.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]

    @test isfinite(result.value)
    @test !isempty(result.history)
    @test length(result.x) == 1
    @test length(result.initial) == 1
    @test result.x != result.initial
    @test calibrated_reaction_rate ≈ 10.0^only(result.x)
    @test calibrated_reaction_rate != initial_reaction_rate
    @test initial_reaction_rate ==
        sim.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]
end

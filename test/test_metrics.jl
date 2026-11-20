using BattMo
using Jutul
using Test


@testset "capacity calculation" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cccv")

    ms = load_model_settings(; from_default_set = "p2d")
    delete!(ms, "RampUp")
    model_setup = LithiumIonBattery(; model_settings = ms)

    sim = Simulation(model_setup, cell_parameters, cycling_protocol)

    output = solve(sim)

    cumulative_capacity = output.time_series["CumulativeCapacity"]
    net_capacity = output.time_series["NetCapacity"]
    discharge_capacity = output.metrics["DischargeCapacity"]
    charge_capacity = output.metrics["ChargeCapacity"]

    @test length(cumulative_capacity) ≈ 785 atol = 1
    @test length(net_capacity) ≈ 785 atol = 1
    @test cumulative_capacity[5] ≈ 0.2828012113052541 atol = 1.0e-1
    @test cumulative_capacity[end - 5] ≈ 23.041417830290328 atol = 1.0e-1
    @test net_capacity[5] ≈ 0.2828012113052541 atol = 1.0e-1
    @test net_capacity[end - 5] ≈ 0.5587215315225628 atol = 1.0e-1

    @test length(discharge_capacity) ≈ 3 atol = 1
    @test length(charge_capacity) ≈ 3 atol = 1
    @test discharge_capacity[1] ≈ 3.6764157469683036 atol = 1.0e-1
    @test discharge_capacity[2] ≈ 3.6764157469683036 atol = 1.0e-1
    @test charge_capacity[1] ≈ 4.237077101465274 atol = 1.0e-1
    @test charge_capacity[2] ≈ 3.6936471729205147 atol = 1.0e-1
end

@testset "Empty and noncycling output metrics" begin
    failed_report = (; ministeps = [(; success = false)])
    empty_output = (; states = Dict{Symbol, Any}[], reports = [failed_report])
    @test isempty(get_output_metrics(empty_output))
    @test isempty(get_output_metrics(empty_output; metrics = String[]))
    @test_throws "Metric \"DischargeCapacity\" is not available. Available metrics are: none" get_output_metrics(
        empty_output; metrics = ["DischargeCapacity"],
    )
    @test isempty(empty_output.states)
    @test empty_output.reports == [failed_report]

    for controller in (BattMo.InputCurrentController(), BattMo.FunctionController())
        output = (; states = [Dict(:Control => Dict(:Controller => controller))])
        @test isempty(get_output_metrics(output))
        @test isempty(get_output_metrics(output; metrics = String[]))
        @test_throws "Available metrics are: none" get_output_metrics(output; metrics = ["CycleIndex"])
    end
end

@testset "Requested cycling output metrics" begin
    # One complete cycle followed by the first state of the next cycle.
    times = [0.0, 1.0, 2.0, 3.0, 4.0]
    currents = [2.0, 2.0, -2.0, -2.0, 0.0]
    cycles = [1, 1, 1, 1, 2]
    states = [
        Dict(
            :Control => Dict(
                :Controller => BattMo.CCController(cycle, current, time, false, missing),
                :Current => [current], :ElectricPotential => [3.0],
            ),
        ) for (time, current, cycle) in zip(times, currents, cycles)
    ]
    output = (; states)
    hour = Jutul.si_unit("hour")
    all_metrics = get_output_metrics(output)
    @test all_metrics["CycleIndex"] == [1]
    @test all_metrics["DischargeCapacity"] ≈ [2.0 / hour] atol = 1.0e-12 rtol = 0
    @test all_metrics["ChargeCapacity"] ≈ [2.0 / hour] atol = 1.0e-12 rtol = 0

    selected = get_output_metrics(output; metrics = ["CycleIndex", "DischargeCapacity"])
    @test Set(keys(selected)) == Set(["CycleIndex", "DischargeCapacity"])
    @test selected["CycleIndex"] == [1]
    @test selected["DischargeCapacity"] ≈ [2.0 / hour] atol = 1.0e-12 rtol = 0
    @test isempty(get_output_metrics(output; metrics = String[]))
    @test_throws "Metric \"UnknownMetric\" is not available." get_output_metrics(
        output; metrics = ["DischargeCapacity", "UnknownMetric"],
    )
end

@testset "P2D output states are padded to the electrolyte grid" begin
    # Electrode fields are placed in the electrolyte cells and padded with NaN outside their
    # electrode; particle fields have the radial position as last dimension.
    protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => [0.0, 10.0, 20.0],
            "Currents" => [2.0, 2.0, 2.0],
            "LowerVoltageLimit" => 2.4,
            "UpperVoltageLimit" => 4.3,
            "InitialStateOfCharge" => 0.5,
        )
    )
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    output = solve(Simulation(LithiumIonBattery(; model_settings), cell_parameters, protocol); info_level = -1)
    first_state = first(output.jutul_output.states)
    last_state = last(output.jutul_output.states)
    nt = length(output.jutul_output.states)
    electrolyte_cells = length(first_state[:Electrolyte][:ElectrolyteConcentration])
    negative_cells = 1:length(first_state[:NegativeElectrodeActiveMaterial][:SurfaceConcentration])
    positive_cells = (electrolyte_cells - length(first_state[:PositiveElectrodeActiveMaterial][:SurfaceConcentration]) + 1):electrolyte_cells

    surface = output.states["NegativeElectrode"]["ActiveMaterial"]["SurfaceConcentration"]
    @test size(surface) == (nt, electrolyte_cells)
    @test all(isnan, surface[:, (last(negative_cells) + 1):end])
    @test surface[end, negative_cells] == last_state[:NegativeElectrodeActiveMaterial][:SurfaceConcentration]

    particles = output.states["PositiveElectrode"]["ActiveMaterial"]["ParticleConcentration"]
    radial_cells = size(first_state[:PositiveElectrodeActiveMaterial][:ParticleConcentration], 1)
    @test size(particles) == (nt, electrolyte_cells, radial_cells)
    @test all(isnan, particles[:, 1:(first(positive_cells) - 1), :])
    @test particles[end, positive_cells, :] == transpose(last_state[:PositiveElectrodeActiveMaterial][:ParticleConcentration])
end

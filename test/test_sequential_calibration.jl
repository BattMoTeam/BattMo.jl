using BattMo
using Test

# Keep this suite free of model construction, simulation, and optimization.
# Numerical gradient/cache checks live in test_adjoints.jl.

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

@testset "Regional electrolyte Bruggeman parameters" begin
    catalog = sequential_parameter_catalog()
    regions = ("NegativeElectrode", "Separator", "PositiveElectrode")
    shortnames = ("elyte_bg_ne", "elyte_bg_sep", "elyte_bg_pe")
    coefficients = (1.2, 1.6, 2.1)

    @test length(BattMo.select_sequential_parameters(["ne_bg", "pe_bg", shortnames...])) == 5
    for (shortname, region, coefficient) in zip(shortnames, regions, coefficients)
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cell_parameters["Electrolyte"]["BruggemanCoefficient"] = Dict(zip(regions, coefficients))
        expected = deepcopy(cell_parameters.all)
        expected["Electrolyte"]["BruggemanCoefficient"][region] = 2.7
        parameter = catalog[shortname]

        @test BattMo.sequential_parameter_value(cell_parameters, parameter) == coefficient
        @test BattMo.set_sequential_parameter!(cell_parameters, parameter, 2.7) === cell_parameters
        @test cell_parameters.all == expected
    end
end

@testset "Sequential parameter selection and coordinates" begin
    @test_throws ArgumentError BattMo.select_sequential_parameters(["ne_j0", "ne_j0"])
    @test_throws ArgumentError BattMo.select_sequential_parameters(["unknown_parameter"])
    @test_throws ArgumentError BattMo.select_sequential_parameters(String[])

    parameters = BattMo.select_sequential_parameters(["ne_bg", "ne_j0"])
    @test [parameter.shortname for parameter in parameters] == ["ne_bg", "ne_j0"]
    for (parameter, value) in zip(parameters, (1.7, 2.5e-11))
        coordinate = BattMo.scale_sequential_parameter(parameter, value)
        recovered = BattMo.unscale_sequential_parameter(parameter, coordinate)
        @test isapprox(recovered, value; atol = 0.0, rtol = 1.0e-12)
    end
    @test isapprox(BattMo.scale_sequential_parameter(parameters[1], 1.7), 1.7; atol = 0.0, rtol = 1.0e-12)
    @test isapprox(BattMo.scale_sequential_parameter(parameters[2], 1.0e-10), -10.0; atol = 1.0e-12, rtol = 0.0)

    unsupported = SequentialCalibrationParameter("unsupported", [["value"]], 1.0, 2.0, :unknown)
    @test_throws ArgumentError BattMo.scale_sequential_parameter(unsupported, 1.5)
    @test_throws ArgumentError BattMo.unscale_sequential_parameter(unsupported, 1.5)
end

@testset "Tied sequential parameters" begin
    parameters = Dict("negative" => Dict("diffusion" => 2.0e-14), "positive" => Dict("diffusion" => 2.0e-14), "untouched" => Dict("value" => 3.0))
    tied = SequentialCalibrationParameter("tied_diffusion", [["negative", "diffusion"], ["positive", "diffusion"]], 1.0e-15, 1.0e-9, :log)
    @test isapprox(BattMo.sequential_parameter_value(parameters, tied), 2.0e-14; atol = 0.0, rtol = 1.0e-12)
    parameters["positive"]["diffusion"] = 3.0e-14
    @test_throws ArgumentError BattMo.sequential_parameter_value(parameters, tied)

    expected = deepcopy(parameters)
    expected["negative"]["diffusion"] = 4.0e-14
    expected["positive"]["diffusion"] = 4.0e-14
    @test BattMo.set_sequential_parameter!(parameters, tied, 4.0e-14) === parameters
    @test parameters == expected
end

@testset "Sequential grouping strategies" begin
    names = ["ne_j0", "pe_j0", "ne_D", "ne_bg", "elyte_bg", "custom_parameter"]
    datasets = ([8.0, -4.0, 2.0, -1.0, 0.5, 0.1], [1.0, 1.0e-2, 1.0e-4, 1.0e-8, 1.0e-10, 0.0], zeros(6))
    for strategy in (:magnitude, :physical, :hybrid_adaptive)
        @test isempty(create_clustered_parameter_groups(String[], Float64[]; strategy))
        for sensitivities in datasets
            original_names = copy(names)
            original_sensitivities = copy(sensitivities)
            groups = create_clustered_parameter_groups(names, sensitivities; strategy)
            opposite_groups = create_clustered_parameter_groups(names, -sensitivities; strategy)

            @test sort(vcat([group.parameters for group in groups]...)) == sort(names)
            @test [group.priority for group in groups] == collect(eachindex(groups))
            @test issorted([group.mean_sensitivity for group in groups]; rev = true)
            @test all(group -> isfinite(group.mean_sensitivity) && group.mean_sensitivity >= 0.0, groups)
            @test [group.parameters for group in groups] == [group.parameters for group in opposite_groups]
            @test names == original_names
            @test sensitivities == original_sensitivities
            if all(iszero, sensitivities)
                @test all(group -> iszero(group.mean_sensitivity), groups)
            end
        end
        for invalid in (NaN, Inf, -Inf)
            @test_throws ArgumentError create_clustered_parameter_groups(names, [invalid, 1.0, 2.0, 3.0, 4.0, 5.0]; strategy)
        end
    end

    groups = create_clustered_parameter_groups(names, first(datasets); strategy = :physical)
    by_name = Dict(group.name => group.parameters for group in groups)
    @test by_name["Electrode_Kinetics"] == ["ne_j0", "pe_j0"]
    @test by_name["Solid_Diffusion"] == ["ne_D"]
    @test by_name["Electrode_Transport"] == ["ne_bg"]
    @test by_name["Electrolyte_Transport"] == ["elyte_bg"]
    @test by_name["Ungrouped"] == ["custom_parameter"]
end

@testset "Sequential problem setup" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] = 1.7
    original_parameters = deepcopy(cell_parameters.all)
    time = [0.0, 1.0, 2.0]
    voltage = [4.1, 4.0, 3.9]
    original_time = copy(time)
    original_voltage = copy(voltage)

    # Setup only reads cell parameters; the model-building callback is left unevaluated.
    sim = (; cell_parameters)
    problem = BattMo.setup_sequential_problem(sim, time, voltage, ["ne_j0", "elyte_bg"])
    initial_rate = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]
    @test [parameter.shortname for parameter in problem.parameters] == ["ne_j0", "elyte_bg"]
    @test isapprox(problem.x0, [log10(initial_rate), 1.7]; atol = 0.0, rtol = 1.0e-12)
    @test problem.lower == [-13.0, 1.0e-10]
    @test problem.upper == [-6.0, 10.0]
    @test problem.calibration.sim.cell_parameters !== cell_parameters
    @test problem.calibration.sim.cell_parameters.all == original_parameters

    @testset "Initial bounds and data validation" begin
        for invalid_rate in (1.0e-14, 1.0e-5, NaN)
            invalid_parameters = deepcopy(cell_parameters)
            invalid_parameters["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = invalid_rate
            @test_throws ArgumentError BattMo.setup_sequential_problem((; cell_parameters = invalid_parameters), time, voltage, ["ne_j0"])
        end
        @test_throws AssertionError BattMo.setup_sequential_problem(sim, time[1:2], voltage, ["ne_j0"])
        @test_throws AssertionError BattMo.setup_sequential_problem(sim, [0.0, 1.0, 1.0], voltage, ["ne_j0"])
    end

    @testset "Custom bounds and scaling in the catalog" begin
        catalog = sequential_parameter_catalog()
        catalog["ne_j0"].lower_bound = 1.0e-12
        catalog["ne_j0"].upper_bound = 1.0e-8
        catalog["elyte_bg"].scaling = :log
        custom_problem = BattMo.setup_sequential_problem(sim, time, voltage, ["ne_j0", "elyte_bg"]; catalog)
        @test isapprox(custom_problem.x0, [log10(initial_rate), log10(1.7)]; atol = 0.0, rtol = 1.0e-12)
        @test isapprox(custom_problem.lower, [-12.0, -10.0]; atol = 1.0e-12, rtol = 0.0)
        @test isapprox(custom_problem.upper, [-8.0, 1.0]; atol = 1.0e-12, rtol = 0.0)

        default_catalog = sequential_parameter_catalog()
        @test default_catalog["ne_j0"].lower_bound == 1.0e-13
        @test default_catalog["ne_j0"].upper_bound == 1.0e-6
        @test default_catalog["elyte_bg"].scaling == :linear
    end

    @testset "Independent parameter updates and group setup" begin
        updated_parameters = problem.calibration.sim.cell_parameters
        BattMo.set_sequential_parameter!(updated_parameters, first(problem.parameters), 2.5e-11)
        expected = deepcopy(original_parameters)
        expected["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = 2.5e-11
        @test updated_parameters.all == expected
        @test cell_parameters.all == original_parameters

        # Carry a known parameter update into the next group without fitting it.
        next_problem = BattMo.setup_sequential_problem((; cell_parameters = updated_parameters), time, voltage, ["elyte_bg"])
        @test next_problem.x0 == [1.7]
        @test next_problem.calibration.sim.cell_parameters.all == expected
        @test next_problem.calibration.sim.cell_parameters !== updated_parameters
        BattMo.set_sequential_parameter!(next_problem.calibration.sim.cell_parameters, only(next_problem.parameters), 2.1)
        expected["Electrolyte"]["BruggemanCoefficient"] = 2.1
        @test next_problem.calibration.sim.cell_parameters.all == expected
        @test updated_parameters["Electrolyte"]["BruggemanCoefficient"] == 1.7
        @test cell_parameters.all == original_parameters
    end
    @test time == original_time
    @test voltage == original_voltage
end

using BattMo
using Test

"""Validate a bundled cell-parameter set and solve one short time step."""
function test_default_cell_parameter_set(parameter_set_name::AbstractString, model_setup)
    cell_parameters = load_cell_parameters(; from_default_set = parameter_set_name)
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")

    @test validate_parameter_set(cell_parameters, model_setup.settings)

    simulation = Simulation(
        model_setup,
        cell_parameters,
        cycling_protocol;
        simulation_settings,
        time_steps = [1.0],
    )
    @test simulation.is_valid

    output = solve(simulation; info_level = -1)
    voltage = output.time_series["Voltage"]
    current = output.time_series["Current"]

    @test !isempty(voltage)
    @test all(isfinite, voltage)
    @test all(value -> 0.0 < value < 6.0, voltage)
    @test !isempty(current)
    @test all(isfinite, current)
    return nothing
end

@testset "default cell parameter sets" begin
    @testset "chen_2020" begin
        test_default_cell_parameter_set("chen_2020", LithiumIonBattery())
    end

    @testset "xu_2015" begin
        test_default_cell_parameter_set("xu_2015", LithiumIonBattery())
    end

    @testset "chayambuka_2022" begin
        model_settings = load_model_settings(; from_default_set = "p2d")
        model_settings["ButlerVolmer"] = "Chayambuka"
        model_setup = SodiumIonBattery(; model_settings)
        test_default_cell_parameter_set("chayambuka_2022", model_setup)
    end
end

@testset "ElectrodeGeometricSurfaceArea is the per-layer area" begin
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    model_setup = LithiumIonBattery()

    function capacities(cell_parameters)
        sim = Simulation(model_setup, cell_parameters, cycling_protocol)
        simulated = computeCellCapacity(sim.model.multimodel) / 3600
        return simulated, compute_cell_theoretical_capacity(cell_parameters)
    end

    reference = load_cell_parameters(; from_default_set = "chen_2020")
    area = reference["Cell"]["ElectrodeGeometricSurfaceArea"]
    @test compute_number_of_electrode_pairs(reference) == 1
    @test compute_total_electrode_area(reference) ≈ area
    simulated_ref, kpi_ref = capacities(reference)

    # (NumberOfLayersInParallel, DoubleCoatedElectrodes, CloseOffWithNegativeElectrode, number of electrode pairs)
    cases = [
        (34, false, false, 34),
        (17, true, true, 34),   # 2 * 17 - 1 pairs inside the stack, plus one facing the closing negative electrode
        (17, true, false, 33),  # the outer positive electrode coating does not face a negative electrode
        (1, true, false, 1),    # both outer coatings of a single double coated layer are unpaired
    ]
    for (n_layers, double_coated, close_off, n_pairs) in cases
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = area / n_pairs
        cell_parameters["Cell"]["NumberOfLayersInParallel"] = n_layers
        cell_parameters["Cell"]["DoubleCoatedElectrodes"] = double_coated
        cell_parameters["Cell"]["CloseOffWithNegativeElectrode"] = close_off
        @test compute_number_of_electrode_pairs(cell_parameters) == n_pairs
        @test compute_total_electrode_area(cell_parameters) ≈ area

        simulated, kpi = capacities(cell_parameters)
        @test simulated ≈ simulated_ref rtol = 1.0e-10
        if !double_coated
            # Only without unpaired outer coatings is all the coating mass in the KPIs active in the simulation.
            @test kpi ≈ kpi_ref rtol = 1.0e-10
        end
    end
end

@testset "electrolyte Bruggeman coefficient given once or per region" begin
    # The electrolyte Bruggeman coefficient is either one value, used in all three regions, or one value per
    # region. In the "Electrolyte" section of a cell parameter JSON file, the per-region form reads
    #
    #     "BruggemanCoefficient": {
    #         "NegativeElectrode": 1.5,
    #         "Separator": 2.0,
    #         "PositiveElectrode": 1.5
    #     },
    #
    # and in Julia it is set by
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] = Dict("NegativeElectrode" => 1.5, "Separator" => 2.0, "PositiveElectrode" => 1.5)

    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    model_setup = LithiumIonBattery()

    # Coefficients the electrolyte model gets in the negative electrode, separator and positive electrode
    function bruggeman_by_region(cell_parameters)
        sim = Simulation(model_setup, cell_parameters, cycling_protocol)
        coefficients = sim.parameters[:Electrolyte][:BruggemanCoefficient]
        coupling = sim.couplings["Electrolyte"]
        regions = ("NegativeElectrodeActiveMaterial", "Separator", "PositiveElectrodeActiveMaterial")
        return [unique(coefficients[coupling[region]["cells"]]) for region in regions]
    end

    @test bruggeman_by_region(cell_parameters) == [[1.5], [2.0], [1.5]]

    # Different values in the two electrodes show that each region gets its own value
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] = Dict("NegativeElectrode" => 1.2, "Separator" => 2.0, "PositiveElectrode" => 1.7)
    @test bruggeman_by_region(cell_parameters) == [[1.2], [2.0], [1.7]]

    # One value, as in the default parameter sets, is used in all three regions
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] = 1.5
    @test bruggeman_by_region(cell_parameters) == [[1.5], [1.5], [1.5]]

    # The per-region form must name all three regions
    cell_parameters["Electrolyte"]["BruggemanCoefficient"] = Dict("NegativeElectrode" => 1.5, "Separator" => 2.0)
    @test_throws ErrorException bruggeman_by_region(cell_parameters)
end

@testset "Chayambuka data tables" begin
    @test size(BattMo.data_pe_ocp, 1) == 27
    @test size(BattMo.data_ne_ocp, 1) == 54
    @test size(BattMo.data_pe_D, 1) == 142
    @test size(BattMo.data_ne_D, 1) == 163
    @test size(BattMo.data_pe_k, 1) == 140
    @test size(BattMo.data_ne_k, 1) == 163
    @test size(BattMo.data_elyte_cond, 1) == 128
    @test size(BattMo.data_elyte_diff, 1) == 136
end

@testset "binder and additive inference" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    target_parameters = deepcopy(cell_parameters)
    initial_parameters = deepcopy(cell_parameters)

    pe_vf = 0.65
    ne_vf = 0.62
    pe_am_vf = 0.55
    ne_am_vf = 0.52
    pe_remaining = pe_vf - pe_am_vf
    ne_remaining = ne_vf - ne_am_vf

    calculate_mass_fractions_and_effective_density_from_volume_fractions!(
        target_parameters,
        pe_vf,
        ne_vf,
        ne_am_vf,
        pe_am_vf;
        ne_b_vf = 0.25 * ne_remaining,
        ne_add_vf = 0.75 * ne_remaining,
        pe_b_vf = 0.75 * pe_remaining,
        pe_add_vf = 0.25 * pe_remaining,
    )
    target_np_ratio = compute_np_ratio(target_parameters)

    calculate_mass_fractions_and_effective_density_from_volume_fractions!(
        initial_parameters,
        pe_vf,
        ne_vf,
        ne_am_vf,
        pe_am_vf;
        ne_b_vf = 0.5 * ne_remaining,
        ne_add_vf = 0.5 * ne_remaining,
        pe_b_vf = 0.5 * pe_remaining,
        pe_add_vf = 0.5 * pe_remaining,
    )
    initial_error = abs(compute_np_ratio(initial_parameters) - target_np_ratio)

    inferred_parameters, result = infer_binder_additive_by_np_ratio!(
        cell_parameters,
        pe_vf,
        ne_vf,
        pe_am_vf,
        ne_am_vf;
        target_np_ratio,
        verbose = false,
    )

    final_error = abs(compute_np_ratio(inferred_parameters) - target_np_ratio)
    @test final_error < initial_error
    @test result["objective_value"] ≈ final_error^2 atol = 1.0e-12
    @test all(0.0 .<= [result["x_ne"], result["x_pe"]] .<= 1.0)
    @test result["ne_b_vf"] + result["ne_add_vf"] ≈ ne_remaining
    @test result["pe_b_vf"] + result["pe_add_vf"] ≈ pe_remaining
end

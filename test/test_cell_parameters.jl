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

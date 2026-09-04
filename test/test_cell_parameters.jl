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

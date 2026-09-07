using BattMo
using Test

@testset "parameter file paths" begin
    default_parameter_path = parameter_file_path()
    cell_parameter_path = parameter_file_path("cell_parameters", "chen_2020")

    @test default_parameter_path isa String
    @test isdir(default_parameter_path)
    @test isfile(cell_parameter_path)
    @test splitext(cell_parameter_path) |> last == ".json"
    @test_throws "File not found at" parameter_file_path("cell_parameters", "BadName")
    @test parameter_file_path("cell_parameters", "BadName"; check = false) isa String
end

@testset "load parameter sets from files" begin
    cell_parameter_path = parameter_file_path("cell_parameters", "chen_2020.json")
    cycling_protocol_path = parameter_file_path("cycling_protocols", "cc_discharge.json")
    model_settings_path = parameter_file_path("model_settings", "p2d.json")
    simulation_settings_path = parameter_file_path("simulation_settings", "p2d.json")

    @test load_cell_parameters(; from_file_path = cell_parameter_path) isa CellParameters
    @test load_cycling_protocol(; from_file_path = cycling_protocol_path) isa CyclingProtocol
    @test load_model_settings(; from_file_path = model_settings_path) isa ModelSettings
    @test load_simulation_settings(; from_file_path = simulation_settings_path) isa SimulationSettings
end

@testset "load bundled parameter sets" begin
    @test load_cell_parameters(; from_default_set = "chen_2020") isa CellParameters
    @test load_cycling_protocol(; from_default_set = "cccv") isa CyclingProtocol
    @test load_model_settings(; from_default_set = "p2d") isa ModelSettings
    @test load_simulation_settings(; from_default_set = "p2d") isa SimulationSettings
end

@testset "load parameter sets from model template" begin
    model_settings = load_model_settings(; from_default_set = "p2d")
    model_setup = LithiumIonBattery(; model_settings)

    @test load_cell_parameters(; from_model_template = model_setup) isa CellParameters
    @test load_simulation_settings(; from_model_template = model_setup) isa SimulationSettings
    @test load_solver_settings(; from_model_template = model_setup) isa SolverSettings

    empty_simulation_settings = load_simulation_settings(
        ; from_model_template = model_setup, empty = true
    )
    @test empty_simulation_settings["TimeStepDuration"] == 0
end

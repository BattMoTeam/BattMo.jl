using BattMo
using Test

@testset "sei layer" begin
    @test begin
        file_path_cell = string(
            dirname(pathof(BattMo)),
            "/../test/data/jsonfiles/cell_parameters/",
            "cell_parameter_set_SEI_example.json",
        )
        file_path_model = string(
            dirname(pathof(BattMo)),
            "/../test/data/jsonfiles/model_settings/",
            "model_settings_P2D.json",
        )
        file_path_cycling = string(
            dirname(pathof(BattMo)),
            "/../test/data/jsonfiles/cycling_protocols/",
            "CCCV.json",
        )
        file_path_simulation = string(
            dirname(pathof(BattMo)),
            "/../test/data/jsonfiles/simulation_settings/",
            "simulation_settings_P2D.json",
        )

        cell_parameters = read_cell_parameters(file_path_cell)
        cycling_protocol = read_cycling_protocol(file_path_cycling)
        model_settings = read_model_settings(file_path_model)
        simulation_settings = read_simulation_settings(file_path_simulation)

        ########################################

        model_settings["UseSEIModel"] = true
        model_settings["SEIModel"] = "Bolay"

        model = LithiumIonBatteryModel(; model_settings)

        cycling_protocol["TotalNumberOfCycles"] = 10

        sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings)

        output = solve(sim)

        true
    end
end

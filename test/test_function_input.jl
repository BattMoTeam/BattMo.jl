using BattMo
using Test

@testset "current function" begin

    @test begin
        include("../examples/example_functions/current_function.jl")
        model_setup = LithiumIonBattery()
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        simulation_settings = load_simulation_settings(; from_default_set = "p2d")
        simulation_settings["TimeStepDuration"] = 1


        cycling_protocol = load_cycling_protocol(
            ; from_default_set = "user_defined_current_function"
        )

        cycling_protocol["TotalTime"] = 1800

        sim = Simulation(
            model_setup,
            cell_parameters,
            cycling_protocol;
            simulation_settings,
            time_steps = [1.0],
        )

        output = solve(sim)

        true
    end

end


@testset "cell functions" begin
    @testset "functions defined in Main" begin
        # Including the Xu fixture first exercises lookup of functions already defined in Main.
        include("./data/julia_files/function_parameters_Xu2015.jl")

        model_setup = LithiumIonBattery()
        cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")

        negative_active_material = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
        positive_active_material = cell_parameters["PositiveElectrode"]["ActiveMaterial"]
        electrolyte = cell_parameters["Electrolyte"]
        negative_ocp = negative_active_material["OpenCircuitPotential"]
        positive_ocp = positive_active_material["OpenCircuitPotential"]

        negative_ocp["FunctionName"] = "open_circuit_potential_graphite_Xu_2015_test"
        positive_ocp["FunctionName"] = "open_circuit_potential_lfp_Xu_2015_test"
        electrolyte["IonicConductivity"] =
            Dict("FunctionName" => "electrolyte_conductivity_Xu_2015_test")
        electrolyte["DiffusionCoefficient"] =
            Dict("FunctionName" => "electrolyte_diffusivity_Xu_2015_test")

        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; time_steps = [1.0])
        output = solve(sim)

        @test haskey(output.time_series, "Voltage")
    end

    @testset "functions loaded from FilePath" begin
        # Unique fixture names ensure that function resolution reaches the explicit file path.
        model_settings = load_model_settings(; from_default_set = "p2d")
        model_settings["ButlerVolmer"] = "Chayambuka"
        model_setup = SodiumIonBattery(; model_settings)
        cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")

        file_path = "../../../../test/data/julia_files/function_parameters_chayambuka_2022.jl"
        negative_active_material = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
        positive_active_material = cell_parameters["PositiveElectrode"]["ActiveMaterial"]
        negative_diffusion = negative_active_material["DiffusionCoefficient"]
        negative_reaction_rate = negative_active_material["ReactionRateConstant"]
        positive_diffusion = positive_active_material["DiffusionCoefficient"]
        positive_reaction_rate = positive_active_material["ReactionRateConstant"]

        negative_diffusion["FunctionName"] = "calc_ne_D_test"
        negative_diffusion["FilePath"] = file_path
        negative_reaction_rate["FunctionName"] = "calc_ne_k_test"
        negative_reaction_rate["FilePath"] = file_path
        positive_diffusion["FunctionName"] = "calc_pe_D_test"
        positive_diffusion["FilePath"] = file_path
        positive_reaction_rate["FunctionName"] = "calc_pe_k_test"
        positive_reaction_rate["FilePath"] = file_path

        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; time_steps = [1.0])
        output = solve(sim)

        @test haskey(output.time_series, "Voltage")
    end
end


@testset "cell string expressions" begin

    @test begin

        model_setup = LithiumIonBattery()
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

        negative_ocp_expression =
            "1.9793 * exp(-39.3631*(c/cmax)) + 0.2482" *
            " - 0.0909 * tanh(29.8538*((c/cmax) - 0.1234))" *
            " - 0.04478 * tanh(14.9159*((c/cmax) - 0.2769))" *
            " - 0.0205 * tanh(30.4444*((c/cmax) - 0.6103))"
        positive_ocp_expression =
            "-0.8090 * (c/cmax) + 4.4875" *
            " - 0.0428 * tanh(18.5138*((c/cmax) - 0.5542))" *
            " - 17.7326 * tanh(15.7890*((c/cmax) - 0.3117))" *
            " + 17.5842 * tanh(15.9308*((c/cmax) - 0.3120))"
        conductivity_expression =
            "0.1297*(c/1000)^3 - 2.51*(c/1000)^(1.5) + 3.329*(c/1000)"
        diffusivity_expression =
            "8.794*10^(-11)*(c/1000)^2" *
            " - 3.972*10^(-10)*(c/1000) + 4.862*10^(-10)"

        negative_active_material = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
        positive_active_material = cell_parameters["PositiveElectrode"]["ActiveMaterial"]
        electrolyte = cell_parameters["Electrolyte"]

        negative_active_material["OpenCircuitPotential"] = negative_ocp_expression
        positive_active_material["OpenCircuitPotential"] = positive_ocp_expression
        electrolyte["IonicConductivity"] = conductivity_expression
        electrolyte["DiffusionCoefficient"] = diffusivity_expression


        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

        sim = Simulation(model_setup, cell_parameters, cycling_protocol; time_steps = [1.0])

        output = solve(sim)

        true
    end

end

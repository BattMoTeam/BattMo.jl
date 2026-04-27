using BattMo
using Test

@testset "voltage breakdown output" begin

    @test begin
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        cycling_protocol["DRate"] = 0.2

        simulation_settings = load_simulation_settings(; from_default_set = "p2d")
        simulation_settings["TimeStepDuration"] = 300

        model_setup = LithiumIonBattery()
        sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
        output = solve(sim)

        breakdown = compute_voltage_breakdown(output)

        required_keys = [
            "Time",
            "Voltage",
            "Current",
            "OpenCircuitVoltage",
            "OpenCircuitVoltageAverage",
            "OpenCircuitVoltageSurface",
            "PositiveSolidConcentrationOverpotential",
            "NegativeSolidConcentrationOverpotential",
            "ElectrolyteConcentrationOverpotential",
            "PositiveReactionOverpotential",
            "NegativeReactionOverpotential",
            "ElectrolytePotentialDrop",
            "ElectrolyteOhmicPotentialDrop",
            "PositiveSolidPotentialDrop",
            "NegativeSolidPotentialDrop",
            "ReconstructedVoltage",
            "ResidualVoltage",
        ]

        n = length(breakdown["Time"])
        for k in required_keys
            @test haskey(breakdown, k)
            @test length(breakdown[k]) == n
        end
        @test haskey(breakdown, "KineticOverpotentialMode")

        @test maximum(abs.(breakdown["OpenCircuitVoltage"] .- breakdown["OpenCircuitVoltageAverage"])) < 1.0e-12
        @test maximum(abs.(breakdown["OpenCircuitVoltageSurface"] .- (breakdown["OpenCircuitVoltageAverage"] .+ breakdown["PositiveSolidConcentrationOverpotential"] .+ breakdown["NegativeSolidConcentrationOverpotential"]))) < 1.0e-6
        @test maximum(abs.(breakdown["ElectrolytePotentialDrop"] .- (breakdown["ElectrolyteOhmicPotentialDrop"] .+ breakdown["ElectrolyteConcentrationOverpotential"]))) < 1.0e-6

        zero_current = findall(abs.(breakdown["Current"]) .< 1.0e-12)
        if !isempty(zero_current)
            @test maximum(abs.(breakdown["PositiveReactionOverpotential"][zero_current])) < 1.0e-6
            @test maximum(abs.(breakdown["NegativeReactionOverpotential"][zero_current])) < 1.0e-6
        end

        @test maximum(abs.(breakdown["ResidualVoltage"])) < 0.1

        true
    end

end

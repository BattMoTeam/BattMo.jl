using BattMo, Jutul, Test

function solve_p2d_discharge(flow_discretization)
    model_settings = load_model_settings(; from_default_set = "p2d")
    model_settings["PotentialFlowDiscretization"] = flow_discretization
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol)
    return sim, solve(sim; info_level = -1)
end

@testset "Potential flow discretization" begin
    sim_ad, output_ad = solve_p2d_discharge("GeneralAD")
    sim_tpfa, output_tpfa = solve_p2d_discharge("TwoPointDiscretization")
    # The setting reaches the active materials and the electrolyte, not only the current collectors
    for key in (:NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial)
        @test sim_ad.model.multimodel[key].domain.discretizations.flow isa Jutul.PotentialFlow
        @test sim_tpfa.model.multimodel[key].domain.discretizations.flow isa Jutul.TwoPointPotentialFlowHardCoded
    end
    # Both evaluate the same two-point fluxes, so the solutions agree to rounding
    @test isapprox(output_tpfa.time_series["Voltage"], output_ad.time_series["Voltage"]; atol = 1.0e-8)
end

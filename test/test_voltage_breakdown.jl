using BattMo
using Test

@testset "Voltage breakdown uses spherical-shell average concentrations" begin
    cell = load_cell_parameters(; from_default_set = "chen_2020")
    protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    settings = load_simulation_settings(; from_default_set = "p2d")
    settings["NegativeElectrodeCoatingGridPoints"] = 2
    settings["PositiveElectrodeCoatingGridPoints"] = 2
    settings["SeparatorGridPoints"] = 2
    settings["NegativeElectrodeParticleGridPoints"] = 2
    settings["PositiveElectrodeParticleGridPoints"] = 3
    # Construct the model, but exercise only postprocessing of synthetic saved states.
    simulation = Simulation(LithiumIonBattery(), cell, protocol; simulation_settings = settings)
    negative = simulation.model.multimodel[:NegativeElectrodeActiveMaterial].system
    positive = simulation.model.multimodel[:PositiveElectrodeActiveMaterial].system
    maximum_negative = negative[:maximum_concentration]
    maximum_positive = positive[:maximum_concentration]
    temperature = 298.15
    negative_ocp(concentration) = BattMo.eval_ocp_from_system(negative, concentration, temperature)
    positive_ocp(concentration) = BattMo.eval_ocp_from_system(positive, concentration, temperature)

    negative_profiles = [0.2 0.8; 0.8 0.2; 0.6 0.6] .* maximum_negative
    positive_profiles = [0.3 0.55 0.8; 0.8 0.55 0.3; 0.5 0.5 0.5] .* maximum_positive
    # Equal radial widths have shell volumes proportional to i^3 - (i - 1)^3.
    negative_weights = [1.0, 7.0] ./ 8
    positive_weights = [1.0, 7.0, 19.0] ./ 27
    expected_negative_ocp = negative_ocp.(negative_profiles * negative_weights)
    expected_positive_ocp = positive_ocp.(positive_profiles * positive_weights)
    surface_negative_ocp = negative_ocp.(negative_profiles[:, end])
    surface_positive_ocp = positive_ocp.(positive_profiles[:, end])

    # Native output pads electrode-cell positions with NaNs, retaining separate radial dimensions.
    negative_particles = fill(NaN, 3, 6, 2)
    positive_particles = fill(NaN, 3, 6, 3)
    negative_particles[:, 1, :] .= 0.4 * maximum_negative
    negative_particles[:, 2, :] .= negative_profiles
    positive_particles[:, 5, :] .= positive_profiles
    positive_particles[:, 6, :] .= 0.65 * maximum_positive
    negative_potential = fill(NaN, 3, 6)
    positive_potential = fill(NaN, 3, 6)
    negative_potential[:, 1:2] .= [0.0 0.01; 0.0 -0.02; 0.0 0.03]
    positive_potential[:, 5:6] .= [3.9 3.88; 4.1 4.13; 3.8 3.76]
    negative_surface_ocp = fill(NaN, 3, 6)
    positive_surface_ocp = fill(NaN, 3, 6)
    negative_surface_ocp[:, 1] .= negative_ocp(0.4 * maximum_negative)
    negative_surface_ocp[:, 2] .= surface_negative_ocp
    positive_surface_ocp[:, 5] .= surface_positive_ocp
    positive_surface_ocp[:, 6] .= positive_ocp(0.65 * maximum_positive)
    fields = Dict{String, Any}(
        "NegativeElectrodeActiveMaterialPotential" => negative_potential,
        "PositiveElectrodeActiveMaterialPotential" => positive_potential,
        "NegativeElectrodeActiveMaterialOpenCircuitPotential" => negative_surface_ocp,
        "PositiveElectrodeActiveMaterialOpenCircuitPotential" => positive_surface_ocp,
        "NegativeElectrodeActiveMaterialParticleConcentration" => negative_particles,
        "PositiveElectrodeActiveMaterialParticleConcentration" => positive_particles,
        "ElectrolytePotential" => repeat([-0.1 -0.1 -0.09 -0.09 -0.08 -0.08], 3, 1),
    )
    time_series = Dict{String, Any}(
        "Time" => [1.0, 2.0, 3.0], "Voltage" => [3.89, 4.14, 3.77], "Current" => [1.0, -1.0, 0.0],
    )
    input = FullSimulationInput(Dict("CellParameters" => cell.all))
    make_output(flat_states) = SimulationOutput(
        time_series, BattMo.nest_output_states(flat_states), Dict{String, Any}(), input,
        (;), simulation.model, simulation,
    )
    breakdown = compute_voltage_breakdown(make_output(fields))
    expected_equilibrium = expected_positive_ocp - expected_negative_ocp
    @test breakdown["OpenCircuitVoltageAverage"] ≈ expected_equilibrium atol = 1.0e-12 rtol = 0
    @test breakdown["OpenCircuitVoltage"] ≈ expected_equilibrium atol = 1.0e-12 rtol = 0
    @test breakdown["NegativeSolidConcentrationOverpotential"] ≈
        expected_negative_ocp - surface_negative_ocp atol = 1.0e-12 rtol = 0
    @test breakdown["PositiveSolidConcentrationOverpotential"] ≈
        surface_positive_ocp - expected_positive_ocp atol = 1.0e-12 rtol = 0
    @test breakdown["OpenCircuitVoltageSurface"] ≈
        surface_positive_ocp - surface_negative_ocp atol = 1.0e-12 rtol = 0
    @test breakdown["OpenCircuitVoltageAverage"] +
        breakdown["PositiveSolidConcentrationOverpotential"] +
        breakdown["NegativeSolidConcentrationOverpotential"] ≈
        breakdown["OpenCircuitVoltageSurface"] atol = 1.0e-12 rtol = 0

    # Ensure the fixture distinguishes volume averaging from the old arithmetic mean in both electrodes.
    arithmetic_negative_ocp = negative_ocp.(vec(sum(negative_profiles; dims = 2)) ./ 2)
    arithmetic_positive_ocp = positive_ocp.(vec(sum(positive_profiles; dims = 2)) ./ 3)
    @test maximum(abs, expected_negative_ocp - arithmetic_negative_ocp) > 1.0e-3
    @test maximum(abs, expected_positive_ocp - arithmetic_positive_ocp) > 1.0e-3
    @test abs(breakdown["NegativeSolidConcentrationOverpotential"][3]) <= 1.0e-12
    @test abs(breakdown["PositiveSolidConcentrationOverpotential"][3]) <= 1.0e-12

    # Changing only the radial reference leaves the surface OCP and all other physical fields fixed.
    uniform_fields = deepcopy(fields)
    for index in 1:3
        uniform_fields["NegativeElectrodeActiveMaterialParticleConcentration"][index, 2, :] .=
            negative_profiles[index, end]
        uniform_fields["PositiveElectrodeActiveMaterialParticleConcentration"][index, 5, :] .=
            positive_profiles[index, end]
    end
    uniform_breakdown = compute_voltage_breakdown(make_output(uniform_fields))
    @test uniform_breakdown["NegativeSolidConcentrationOverpotential"] ≈ zeros(3) atol = 1.0e-12 rtol = 0
    @test uniform_breakdown["PositiveSolidConcentrationOverpotential"] ≈ zeros(3) atol = 1.0e-12 rtol = 0
    @test uniform_breakdown["OpenCircuitVoltageAverage"] ≈ breakdown["OpenCircuitVoltageSurface"] atol = 1.0e-12 rtol = 0
    for field in ("ReconstructedVoltage", "ResidualVoltage", "Voltage", "Time")
        @test uniform_breakdown[field] ≈ breakdown[field] atol = 1.0e-12 rtol = 0
    end

    # Older/minimal outputs without radial profiles retain the existing surface-OCP fallback.
    fallback_fields = copy(fields)
    delete!(fallback_fields, "NegativeElectrodeActiveMaterialParticleConcentration")
    delete!(fallback_fields, "PositiveElectrodeActiveMaterialParticleConcentration")
    fallback_breakdown = compute_voltage_breakdown(make_output(fallback_fields))
    @test fallback_breakdown["OpenCircuitVoltageAverage"] ≈ breakdown["OpenCircuitVoltageSurface"] atol = 1.0e-12 rtol = 0
    @test fallback_breakdown["NegativeSolidConcentrationOverpotential"] == zeros(3)
    @test fallback_breakdown["PositiveSolidConcentrationOverpotential"] == zeros(3)
    @test fallback_breakdown["ReconstructedVoltage"] ≈ breakdown["ReconstructedVoltage"] atol = 1.0e-12 rtol = 0
    @test fallback_breakdown["ResidualVoltage"] ≈ breakdown["ResidualVoltage"] atol = 1.0e-12 rtol = 0
end

using BattMo
using Test

@testset "interpolate_state_at_voltage" begin

    # Run a short discharge simulation to get a sequence of states
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model = LithiumIonBattery()

    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    simulation_settings["PositiveElectrodeCoatingGridPoints"] = 5
    simulation_settings["NegativeElectrodeCoatingGridPoints"] = 5
    simulation_settings["PositiveElectrodeParticleGridPoints"] = 5
    simulation_settings["NegativeElectrodeParticleGridPoints"] = 5
    simulation_settings["SeparatorGridPoints"] = 2

    protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    protocol["InitialStateOfCharge"] = 0.99
    protocol["DRate"] = 1.0
    protocol["LowerVoltageLimit"] = 3.0

    sim = Simulation(model, cell_parameters, protocol;
                     simulation_settings, output_all_secondary_variables = true)
    output = solve(sim; info_level = -1)
    states = output.jutul_output.states

    voltages = [s[:Control][:ElectricPotential][1] for s in states]
    times    = [s[:Control][:Controller].time for s in states]

    @testset "basic interpolation" begin
        # Pick a target voltage in the middle of the discharge curve
        v_mid = (voltages[5] + voltages[6]) / 2
        result = interpolate_state_at_voltage(states, v_mid)

        # The interpolated voltage should match the target
        result_v = result[:Control][:ElectricPotential][1]
        @test abs(result_v - v_mid) < 1e-10

        # Time should also be interpolated
        result_t = result[:Control][:Controller].time
        @test times[5] < result_t < times[6]

        # All expected components should be present
        @test haskey(result, :NegativeElectrodeActiveMaterial)
        @test haskey(result, :PositiveElectrodeActiveMaterial)
        @test haskey(result, :Electrolyte)
        @test haskey(result, :Control)

        # Concentrations should be between the two bracketing states
        ne_conc1 = states[5][:NegativeElectrodeActiveMaterial][:SurfaceConcentration]
        ne_conc2 = states[6][:NegativeElectrodeActiveMaterial][:SurfaceConcentration]
        ne_conc_interp = result[:NegativeElectrodeActiveMaterial][:SurfaceConcentration]
        for i in eachindex(ne_conc_interp)
            lo = min(ne_conc1[i], ne_conc2[i])
            hi = max(ne_conc1[i], ne_conc2[i])
            @test lo <= ne_conc_interp[i] <= hi
        end
    end

    @testset "exact match at existing state" begin
        # Target voltage equals an existing state exactly
        target_v = voltages[3]
        result = interpolate_state_at_voltage(states, target_v)
        result_v = result[:Control][:ElectricPotential][1]
        @test abs(result_v - target_v) < 1e-10
    end

    @testset "usable as initial state" begin
        # The interpolated state can be passed directly as initial_state to Simulation;
        # setup_initial_state handles missing secondary variables automatically.
        v_target = (voltages[8] + voltages[9]) / 2
        interp_state = interpolate_state_at_voltage(states, v_target)

        # The interpolated state from a simulation run with output_all_secondary_variables=true
        # already has all required secondary variables
        @test haskey(interp_state[:NegativeElectrodeActiveMaterial], :SolidDiffFlux)
        @test haskey(interp_state[:Electrolyte], :DmuDc)
        @test haskey(interp_state[:Electrolyte], :ChemCoef)
    end

    @testset "error cases" begin
        # Not enough states
        @test_throws ErrorException interpolate_state_at_voltage(states[1:1], 3.5)

        # Voltage out of range (above all states during discharge)
        v_max = maximum(voltages) + 1.0
        @test_throws ErrorException interpolate_state_at_voltage(states, v_max)

        # Voltage out of range (below all states)
        v_min = minimum(voltages) - 1.0
        @test_throws ErrorException interpolate_state_at_voltage(states, v_min)
    end

end

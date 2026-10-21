module InitialStateTests

using BattMo, Test
import Serialization

"""Simulate an inclusive input-sample range, restarting its clock and optionally restoring a state."""
function restart_simulation(output_ref, indices; initial_state = nothing)
    protocol = deepcopy(output_ref.input["CyclingProtocol"])
    protocol["Times"] = protocol["Times"][indices] .- protocol["Times"][first(indices)]

    # Simulate using the raw input. Do not use output_ref.time_series["Current"]:
    # those are solved interval averages, possibly modified by voltage limits.
    protocol["Currents"] = output_ref.input["CyclingProtocol"]["Currents"][indices]

    reference = output_ref.simulation

    return Simulation(
        LithiumIonBattery(; model_settings = deepcopy(reference.model.settings)),
        reference.cell_parameters, CyclingProtocol(protocol);
        simulation_settings = reference.settings, initial_state,
    )
end

@testset "Restart from ordinary saved output at 50% SOC" begin
    @testset "SEI = $sei" for sei in (false, true)
        negative = :NegativeElectrodeActiveMaterial
        positive = :PositiveElectrodeActiveMaterial
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

        # Make SEI growth measurable before the first restart during charging.
        cell_parameters["NegativeElectrode"]["Interphase"]["InterstitialConcentration"] = 1.5
        model_settings = load_model_settings(; from_default_set = "p2d")
        delete!(model_settings, "RampUp")
        if sei
            model_settings["SEIModel"] = "Bolay"
        end
        settings = load_simulation_settings(; from_default_set = "p2d")
        for electrode in ("NegativeElectrode", "PositiveElectrode")
            settings[electrode * "CoatingGridPoints"] = 2
            settings[electrode * "ParticleGridPoints"] = 4
        end
        settings["SeparatorGridPoints"] = 2

        # Charge, rest, discharge, rest; negative current charges the cell.
        time_ref = collect(0.0:30.0:480.0)
        current_ref = 2.5 .* [0, -1, -1, -1, -1, -1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0]
        protocol = CyclingProtocol(
            Dict(
                "Protocol" => "InputCurrentSeries",
                "Times" => time_ref, "Currents" => current_ref,
                "LowerVoltageLimit" => 2.0, "UpperVoltageLimit" => 4.3,
                "InitialStateOfCharge" => 0.5,
            )
        )
        sim_ref = Simulation(
            LithiumIonBattery(; model_settings), cell_parameters, protocol;
            simulation_settings = settings,
        )

        # Resolve the small SEI growth and keep substeps identical across restarts.
        solver_settings = load_solver_settings(; from_default_set = "direct")
        tolerances = Dict(string(name) => Dict("default" => 1.0e-10) for name in keys(sim_ref.model.multimodel.models))
        for scaling in BattMo.get_scalings(sim_ref.model.multimodel, sim_ref.parameters)
            tolerances[string(scaling.model_label)][string(scaling.equation_label)] = scaling.value * 1.0e-10
        end
        solver_settings["NonLinearSolver"]["Tolerances"] = tolerances
        solve_options = (;
            solver_settings, info_level = -1, max_timestep = 10.0,
            always_update_secondary = true, output_substates = true, error_on_incomplete = true,
        )
        output_ref = solve(sim_ref; solve_options..., include_initial_state = true)

        @testset "include_initial_state" begin
            output_without_initial = solve(sim_ref; solve_options..., include_initial_state = false)
            @test output_ref.time_series["Time"] ≈ time_ref atol = 1.0e-12 rtol = 0.0
            for name in ("Time", "Current", "Voltage")
                @test output_without_initial.time_series[name] ≈
                    output_ref.time_series[name][2:end] atol = 1.0e-12 rtol = 0.0
            end
        end

        state_fields = [
            (negative, :ParticleConcentration, 1.0e-6),
            (negative, :SurfaceConcentration, 1.0e-6),
            (positive, :ParticleConcentration, 1.0e-6),
            (positive, :SurfaceConcentration, 1.0e-6),
            (:Electrolyte, :ElectrolyteConcentration, 1.0e-7),
        ]
        if sei
            append!(
                state_fields, [
                    (negative, :NormalizedSEIThickness, 1.0e-10),
                    (negative, :NormalizedSEIVoltageDrop, 1.0e-10),
                    (negative, :SEIThickness, 1.0e-18),
                    (negative, :SEIVoltageDrop, 1.0e-8),
                ]
            )
        end
        restart_state = nothing
        boundaries = [1, 4, 12, length(time_ref)]

        mktempdir() do directory
            for chunk in 1:(length(boundaries) - 1)
                indices = boundaries[chunk]:boundaries[chunk + 1]
                simulation = restart_simulation(output_ref, indices; initial_state = restart_state)
                output = solve(simulation; solve_options..., include_initial_state = true)

                # Save the raw endpoint, including substeps, without repairing it in the test.
                endpoint = last(output.jutul_output.states)
                checkpoint_path = joinpath(directory, "restart.jls")
                Serialization.serialize(checkpoint_path, endpoint)
                restart_state = Serialization.deserialize(checkpoint_path)
            end
        end

        # Compare only the final result of the uninterrupted and restarted runs.
        reference = last(output_ref.jutul_output.states)
        restarted = restart_state
        final_time = restarted[:Control][:Controller].time + time_ref[boundaries[end - 1]]
        @test final_time ≈ last(time_ref) atol = 1.0e-12 rtol = 0.0
        @test restarted[:Control][:Current] ≈ reference[:Control][:Current] atol = 1.0e-7 rtol = 0.0
        @test restarted[:Control][:ElectricPotential] ≈ reference[:Control][:ElectricPotential] atol = 1.0e-6 rtol = 0.0
        for (component, field, tolerance) in state_fields
            @test restarted[component][field] ≈ reference[component][field] atol = tolerance rtol = 1.0e-6
        end
        if sei
            # Retain the original baseline when comparing cumulative SEI growth.
            baseline_state = sim_ref.initial_state
            initial_inventory = compute_lithium_inventory(sim_ref, baseline_state; baseline_state)
            ref_inventory = compute_lithium_inventory(sim_ref, reference; baseline_state)
            split_inventory = compute_lithium_inventory(sim_ref, restarted; baseline_state)
            @test ref_inventory.sei_loss_ah > 1.0e-6
            @test split_inventory.sei_added ≈ ref_inventory.sei_added rtol = 1.0e-6 atol = 1.0e-10 * initial_inventory.mobile
        end
    end
end

end

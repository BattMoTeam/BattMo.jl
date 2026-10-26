using BattMo
using Test

trapz(x, y) = sum((y[1:(end - 1)] .+ y[2:end]) .* diff(x)) / 2
rmse(x, y0, y1) = sqrt(trapz(x, (y1 .- y0) .^ 2) / (x[end] - x[1]))

@testset "Restart from saved state reproduces full discharge-charge simulation" begin
    # Parameters
    rate = 1.0
    initial_soc = 1.0
    upper_cutoff = 4.1
    lower_cutoff = 3.5

    HOUR = 3600.0
    discharge_duration = HOUR / rate
    charge_duration = HOUR / rate
    t_total = discharge_duration + charge_duration

    N = 11
    t_discharge = collect(range(0.0, discharge_duration; length = N))
    t_charge = collect(range(discharge_duration, t_total; length = N))
    t_ref = vcat(t_discharge, t_charge[2:end]) # drop duplicate join point

    # Setup cell model and parameters
    model = LithiumIonBattery()
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

    I_app = rate * cell_parameters["Cell"]["NominalCapacity"]
    I_tmp = vcat(fill(I_app, N), fill(-I_app, N - 1))

    ref_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => t_ref,
            "Currents" => I_tmp,
            "LowerVoltageLimit" => lower_cutoff,
            "UpperVoltageLimit" => upper_cutoff,
            "InitialStateOfCharge" => initial_soc,
        )
    )

    sim_ref = Simulation(model, cell_parameters, ref_protocol)

    @testset "include_initial_state" begin
        output_ref_with_initial =
            solve(sim_ref; info_level = 0, include_initial_state = true)
        output_ref_without_initial =
            solve(sim_ref; info_level = 0, include_initial_state = false)

        @test output_ref_with_initial.time_series["Time"] ≈ t_ref atol = 1.0e-14 rtol = 0.0
        @test length(output_ref_without_initial.time_series["Time"]) == length(t_ref) - 1
        @test output_ref_without_initial.time_series["Time"] ≈ t_ref[2:end] atol = 1.0e-14 rtol = 0.0

        # The no-initial-state output should match the full output with the first sample removed
        @test output_ref_without_initial.time_series["Current"] ≈
            output_ref_with_initial.time_series["Current"][2:end] atol = 1.0e-12 rtol = 0.0
        @test output_ref_without_initial.time_series["Voltage"] ≈
            output_ref_with_initial.time_series["Voltage"][2:end] atol = 1.0e-12 rtol = 0.0
    end

    # Reference output used for splitting
    output_ref = solve(sim_ref; info_level = 0, include_initial_state = true)

    # Step 1: discharge only using the current from the reference simulation
    I_discharge = output_ref.time_series["Current"][1:N]

    discharge_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => t_discharge,
            "Currents" => I_discharge,
            "LowerVoltageLimit" => lower_cutoff,
            "UpperVoltageLimit" => upper_cutoff,
            "InitialStateOfCharge" => initial_soc,
        )
    )

    sim_discharge = Simulation(
        model,
        cell_parameters,
        discharge_protocol;
        output_all_secondary_variables = true,
    )
    output_discharge = solve(sim_discharge; info_level = 0, include_initial_state = true)

    @test output_discharge.time_series["Time"] ≈ t_discharge atol = 1.0e-14 rtol = 0.0

    end_state = output_discharge.jutul_output.states[end]
    @test abs(end_state[:Control][:Controller].time - output_ref.time_series["Time"][N]) < 1.0e-14

    # Step 2: charge using the discharge end state as initial state
    I_charge = output_ref.time_series["Current"][N:end]

    charge_protocol = CyclingProtocol(
        Dict(
            "Protocol" => "InputCurrentSeries",
            "Times" => t_charge .- t_charge[1],
            "Currents" => I_charge,
            "LowerVoltageLimit" => 0.0,
            "UpperVoltageLimit" => upper_cutoff,
            "InitialStateOfCharge" => initial_soc,
        )
    )

    sim_charge = Simulation(
        model,
        cell_parameters,
        charge_protocol;
        initial_state = end_state,
    )
    output_charge = solve(sim_charge; info_level = 0, include_initial_state = true)

    @test output_charge.time_series["Time"] ≈ (t_charge .- t_charge[1]) atol = 1.0e-14 rtol = 0.0

    @testset "split discharge + charge matches full simulation" begin
        E_ref = output_ref.time_series["Voltage"]
        E_discharge = output_discharge.time_series["Voltage"]
        E_charge = output_charge.time_series["Voltage"]

        t_merge = vcat(
            output_discharge.time_series["Time"],
            output_charge.time_series["Time"][2:end] .+ t_discharge[end],
        )
        I_merge = vcat(
            output_discharge.time_series["Current"],
            output_charge.time_series["Current"][2:end],
        )
        E_merge = vcat(E_discharge, E_charge[2:end]) # drop duplicate join point

        @test t_merge ≈ t_ref atol = 1.0e-14 rtol = 0.0
        @test I_merge ≈ output_ref.time_series["Current"] atol = 1.0e-7 rtol = 0.0
        @test maximum(abs.(E_merge .- E_ref)) <= 1.0e-6
        @test rmse(t_ref, E_ref, E_merge) <= 1.0e-4
    end
end

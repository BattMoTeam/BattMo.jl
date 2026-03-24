using BattMo
using Test

@testset "Custom initial state" begin

    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    model_settings = load_model_settings(; from_default_set = "p2d")
    simulation_settings = load_simulation_settings(; from_default_set = "p2d")
    model_setup = LithiumIonBattery(; model_settings)

    # Discharge only, save end state
    cycling_disc = load_cycling_protocol(; from_default_set = "cc_discharge")
    cycling_disc["DRate"] = 1
    cycling_disc["InitialStateOfCharge"] = 0.99

    sim_disc = Simulation(model_setup, cell_parameters, cycling_disc; simulation_settings)
    output_disc = solve(sim_disc)
    V_disc = output_disc.time_series["Voltage"]

    # get_restart_state must return a compatible state dict
    state0 = get_restart_state(output_disc)
    @test state0 isa AbstractDict
    @test haskey(state0, :Control)
    @test haskey(state0, :NegativeElectrodeActiveMaterial)
    @test haskey(state0, :PositiveElectrodeActiveMaterial)
    @test haskey(state0, :Electrolyte)

    # The voltage in the restart state should match the last discharge voltage
    @test state0[:Control][:ElectricPotential][1] ≈ V_disc[end] atol = 1.0e-6

    # Charge from saved discharge end state
    cycling_charge = load_cycling_protocol(; from_default_set = "cc_charge")
    cycling_charge["CRate"] = 1

    sim_charge = Simulation(model_setup, cell_parameters, cycling_charge; simulation_settings, state0)
    output_charge = solve(sim_charge)
    V_charge = output_charge.time_series["Voltage"]

    # The Controller must be automatically adjusted to "charging"
    @test sim_charge.initial_state[:Control][:Controller].ctrlType == "charging"

    # The charge simulation must complete and the voltage must rise above the
    # end-of-discharge voltage and approach the upper cutoff limit
    @test length(V_charge) > 1
    @test V_charge[end] > V_disc[end]                            # voltage increased
    @test V_charge[end] ≈ cycling_charge["UpperVoltageLimit"] atol = 0.1  # near upper limit

end

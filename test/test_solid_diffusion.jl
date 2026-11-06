using BattMo
using Test

# The solid diffusion flux uses the diffusion coefficient of each cell at the current
# surface concentration and temperature, including the Arrhenius temperature dependence.

const GAS_CONSTANT_TEST = 8.31446261815324 # J mol⁻¹ K⁻¹

arrhenius_factor(activation_energy, T, reference_temperature) = exp(-activation_energy / GAS_CONSTANT_TEST * (1 / T - 1 / reference_temperature))

function solid_diffusion_discharge(cell_parameters; model_settings = load_model_settings(; from_default_set = "p2d"), initial_temperature = nothing)
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    isnothing(initial_temperature) || (cycling_protocol["InitialTemperature"] = initial_temperature)
    sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol)
    output = solve(sim; info_level = -1)
    return (time = output.time_series["Time"], voltage = output.time_series["Voltage"])
end

function interpolate_voltage(curve, t)
    k = clamp(searchsortedlast(curve.time, t), 1, length(curve.time) - 1)
    return curve.voltage[k] + (curve.voltage[k + 1] - curve.voltage[k]) * (t - curve.time[k]) / (curve.time[k + 1] - curve.time[k])
end

# Largest voltage difference of two discharges over the time span they share
function max_voltage_difference(a, b)
    t_end = min(a.time[end], b.time[end])
    return maximum(abs(interpolate_voltage(b, t) - v) for (t, v) in zip(a.time, a.voltage) if t <= t_end)
end

@testset "solid diffusion" begin

    @testset "the Arrhenius temperature dependence applies to the solid diffusion coefficient" begin
        T = 283.15
        model_settings = load_model_settings(; from_default_set = "p2d")
        model_settings["TemperatureDependence"] = "Arrhenius"

        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        reference_temperature = get(cell_parameters["Cell"], "ReferenceTemperature", BattMo.DEFAULT_REFERENCE_TEMPERATURE)

        # The same diffusion coefficients at T, written with ten times the activation
        # energies
        rescaled = deepcopy(cell_parameters)
        for electrode in ("NegativeElectrode", "PositiveElectrode")
            active_material = rescaled[electrode]["ActiveMaterial"]
            energy = active_material["ActivationEnergyOfDiffusion"]
            active_material["DiffusionCoefficient"] *= arrhenius_factor(energy, T, reference_temperature) / arrhenius_factor(10 * energy, T, reference_temperature)
            active_material["ActivationEnergyOfDiffusion"] = 10 * energy
        end

        a = solid_diffusion_discharge(cell_parameters; model_settings, initial_temperature = T)
        b = solid_diffusion_discharge(rescaled; model_settings, initial_temperature = T)
        @test max_voltage_difference(a, b) < 0.5e-3
        @test a.time[end] ≈ b.time[end] rtol = 1.0e-3
    end

    @testset "the solid diffusion coefficient follows the surface concentration" begin
        cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        active_material = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
        D0 = active_material["DiffusionCoefficient"]
        theta0 = active_material["StoichiometricCoefficientAtSOC0"]
        theta100 = active_material["StoichiometricCoefficientAtSOC100"]
        theta_initial = cycling_protocol["InitialStateOfCharge"] * (theta100 - theta0) + theta0

        constant = solid_diffusion_discharge(cell_parameters)

        # A function string with the same constant value gives the same result
        same = deepcopy(cell_parameters)
        same["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "$D0 + 0.0 * c"
        @test max_voltage_difference(constant, solid_diffusion_discharge(same)) < 1.0e-6

        # A diffusion coefficient that equals the constant at the initial state, and falls
        # as the negative electrode delithiates, slows the discharge down
        varying = deepcopy(cell_parameters)
        varying["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "$D0 * exp(5.0 * (c / cmax - $theta_initial))"
        @test max_voltage_difference(constant, solid_diffusion_discharge(varying)) > 5.0e-3
    end

end

using BattMo
using Test
using CSV


@testset "Equilibrium calibration" begin
    data_path = joinpath(dirname(pathof(BattMo)), "..", "examples", "example_data", "Chayambuka_voltage_005C.csv")
    data = CSV.read(data_path, DataFrame; header = false)
    capacity = Float64.(data[:, 1])
    voltage = Float64.(data[:, 2])
    order = sortperm(capacity)
    # Downsample the measured curve for a coarse-grid machinery test.
    capacity = capacity[order][1:16:end]
    voltage = voltage[order][1:16:end]

    cell_parameters = load_cell_parameters(; from_default_set = "chayambuka_2022")
    current = 0.05 * cell_parameters["Cell"]["NominalCapacity"]
    time = (capacity .- first(capacity)) .* 3.6 ./ current
    calibration = EquilibriumCalibration(time, voltage, current, cell_parameters)

    x0, = BattMo.equilibrium_calibration_vector(calibration)
    initial_voltage = [equilibrium_voltage(calibration, t, x0) for t in time]
    initial_rmse = BattMo.rmse(time, voltage, initial_voltage)
    calibrated_parameters = solve(calibration; max_it = 2, print = 0)
    x = equilibrium_calibration_vector(calibration, calibrated_parameters)
    calibrated_voltage = [equilibrium_voltage(calibration, t, x) for t in time]
    calibrated_rmse = BattMo.rmse(time, voltage, calibrated_voltage)

    @test !isempty(calibration.history)
    @test all(isfinite, x)
    @test calibrated_rmse <= initial_rmse
end

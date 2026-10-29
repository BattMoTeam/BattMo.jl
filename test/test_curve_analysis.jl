using BattMo
using Test

@testset "Calibration curve utilities" begin
    time = [0.0, 1.0, 3.0]
    values = [0.0, 2.0, 6.0]
    @test cumtrapz(time, values) ≈ [0.0, 1.0, 9.0] atol = 1.0e-12 rtol = 0.0
    @test trapz(time, values) ≈ 9.0 atol = 1.0e-12 rtol = 0.0
    @test rmse(time, values, time, values .+ 2.0) ≈ 2.0 atol = 1.0e-12 rtol = 0.0
    @test rmse(time, values, [0.0, 3.0], [0.0, 6.0]) ≈ 0.0 atol = 1.0e-12 rtol = 0.0
    @test_throws DimensionMismatch cumtrapz(time, values[1:2])
    @test_throws ArgumentError cumtrapz([0.0], [1.0])
    @test_throws ArgumentError rmse(reverse(time), values, time, values)

    voltage, differential_capacity = compute_dqdv([0.0, 1.0, 2.0], [1.0, 2.0, 3.0]; nbins = 2, smooth = false)
    @test voltage ≈ [1.5, 2.5] atol = 1.0e-12 rtol = 0.0
    @test differential_capacity ≈ [2 / 3, 4 / 3] atol = 1.0e-12 rtol = 0.0
end

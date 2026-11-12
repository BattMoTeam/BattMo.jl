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

    voltage, differential_capacity = dqdv([0.0, 1.0, 2.0], [1.0, 2.0, 3.0]; nbins = 2, smooth = false)
    @test voltage ≈ [1.5, 2.5] atol = 1.0e-12 rtol = 0.0
    @test differential_capacity ≈ [2 / 3, 4 / 3] atol = 1.0e-12 rtol = 0.0
end

@testset "dqdv capacity sampling" begin
    q_uniform = collect(range(0.0, 1.0; length = 1001))
    v = 3.0 .+ q_uniform

    # Uniform grids remain valid in either direction and at different precision/offsets.
    q_roundoff = copy(q_uniform)
    q_roundoff[501] += 1.0e-12
    for q in (q_uniform, reverse(q_uniform), q_roundoff, Float32.(q_uniform), 1.0e9 .+ q_uniform)
        voltage, differential_capacity = dqdv(q, v; nbins = 10, smooth = false)
        @test length(voltage) == 10
        @test sum(differential_capacity) * 0.1 ≈ maximum(q) - minimum(q)
    end

    # Same voltage samples, but a strongly skewed capacity grid as in the Python example.
    @test_throws ArgumentError dqdv(q_uniform .^ 8, v; nbins = 10)
    # One bad interval must be detected even in a densely sampled curve.
    q_uneven = copy(q_uniform)
    q_uneven[501] += 1.0e-5
    @test_throws ArgumentError dqdv(q_uneven, v; nbins = 10)

    for q in ([0.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.5])
        @test_throws ArgumentError dqdv(q, [3.0, 3.5, 4.0]; nbins = 2)
    end
end

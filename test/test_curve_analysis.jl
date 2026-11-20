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

@testset "dvdq" begin
    # On this grid the bins are [0, 25), [25, 50), [50, 75), and [75, 100] with the end point.
    q = collect(0.0:1.0:100.0)
    for smooth in (false, true)
        capacity, differential_voltage = dvdq(q, 3.0 .+ 2.0 .* q; nbins = 4, smooth)
        @test capacity ≈ [24.5, 49.5, 74.75] atol = 1.0e-12 rtol = 0.0
        @test differential_voltage ≈ fill(2.0, 3) atol = 1.0e-12 rtol = 0.0
    end

    # Bins of equal sample count and spacing make the slope of a quadratic exact midway between them.
    q = collect(0.0:1.0:99.0)
    capacity, differential_voltage = dvdq(q, q .^ 2; nbins = 4, smooth = false)
    @test capacity ≈ [24.5, 49.5, 74.5] atol = 1.0e-12 rtol = 0.0
    @test differential_voltage ≈ 2 .* capacity atol = 1.0e-9 rtol = 0.0

    # A linear discharge stays exact on an uneven grid, which dqdv rejects.
    q = collect(0:100) .^ 2 ./ 100
    capacity, differential_voltage = dvdq(q, 4.2 .- 0.01 .* q; nbins = 5, smooth = false)
    @test differential_voltage ≈ fill(-0.01, 4) atol = 1.0e-12 rtol = 0.0
    @test issorted(capacity)
    @test_throws ArgumentError dqdv(q, 4.2 .- 0.01 .* q; nbins = 5)

    # A decreasing grid returns its values in its own direction.
    q = collect(100.0:-1.0:0.0)
    capacity, differential_voltage = dvdq(q, 3.0 .+ 2.0 .* q; nbins = 4, smooth = false)
    @test capacity ≈ [75.5, 50.5, 25.25] atol = 1.0e-12 rtol = 0.0
    @test differential_voltage ≈ fill(2.0, 3) atol = 1.0e-12 rtol = 0.0

    # Capacity must be strictly monotonic, every bin must hold a sample, and at least two bins are needed.
    @test_throws ArgumentError dvdq([0.0, 1.0, 0.5, 2.0], [3.0, 3.1, 3.2, 3.3]; nbins = 2)
    @test_throws ArgumentError dvdq([0.0, 0.0, 1.0, 2.0], [3.0, 3.1, 3.2, 3.3]; nbins = 2)
    @test_throws ArgumentError dvdq([0.0, 0.1, 0.2, 5.0, 5.1], fill(3.0, 5); nbins = 5)
    @test_throws ArgumentError dvdq(q, q; nbins = 1)
    @test_throws ArgumentError dvdq(q, q[1:(end - 1)]; nbins = 4)
    @test_throws ArgumentError dvdq(q, q)
end

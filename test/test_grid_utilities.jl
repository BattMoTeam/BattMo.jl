using BattMo
using Test

@testset "run-length expansion" begin
    @test BattMo._expand_run_lengths([1.0, 2.0, 3.0], [2, 0, 3]) ==
        [1.0, 1.0, 3.0, 3.0, 3.0]
    @test_throws DimensionMismatch BattMo._expand_run_lengths([1.0], [1, 2])
    @test_throws ArgumentError BattMo._expand_run_lengths([1.0], [-1])
end

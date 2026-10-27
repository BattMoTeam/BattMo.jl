using Test

@testset "merge_dict" begin
    base = Dict{String, Any}(
        "nested" => Dict("keep" => 1, "empty" => 0),
        "unset" => nothing,
        "values" => [1, 2],
    )
    first_update = Dict{String, Any}(
        "nested" => Dict("keep" => 9, "empty" => 2),
        "unset" => 3,
        "added" => [4],
    )
    second_update = Dict("nested" => Dict("empty" => 5, "extra" => 6))
    originals = deepcopy((base, first_update, second_update))

    @testset "fill precedence" begin
        merged = merge_dict(base, first_update, second_update)
        @test merged["nested"] == Dict("keep" => 1, "empty" => 2, "extra" => 6)
        @test merged["unset"] == 3
        @test merged["added"] == [4]
        @test merged == merge_dict(merge_dict(base, first_update), second_update)
    end

    @testset "recursive overwrite and independent copies" begin
        merged = merge_dict(base, first_update, second_update; type = "overwrite")
        @test merged["nested"] == Dict("keep" => 9, "empty" => 5, "extra" => 6)
        @test merged == merge_dict(
            merge_dict(base, first_update; type = "overwrite"),
            second_update; type = "overwrite",
        )
        push!(merged["values"], 7)
        push!(merged["added"], 8)
        merged["nested"]["extra"] = 10
        @test (base, first_update, second_update) == originals
        @test merge_dict(Dict("x" => 1), Dict("x" => 2); type = "overwrite") == Dict("x" => 2)
    end

    @testset "replace precedence" begin
        merged = merge_dict(base, first_update, second_update; type = "replace", key_path = "nested")
        @test merged["nested"] == second_update["nested"]
        @test merged["nested"] !== second_update["nested"]
        @test merged["values"] == base["values"]
        @test !haskey(merged, "added")
        nested = merge_dict(base, Dict("keep" => 7); type = "replace", key_path = ["nested", "keep"])
        @test nested["nested"] == Dict("keep" => 7, "empty" => 0)
    end

    @testset "base-only copy and invalid options" begin
        copied = merge_dict(base)
        @test copied == base
        @test copied !== base
        @test copied["nested"] !== base["nested"]
        @test_throws ErrorException merge_dict(base, first_update; type = "invalid")
        @test_throws ErrorException merge_dict(base, first_update; type = "replace")
        @test_throws ErrorException merge_dict(base, first_update; type = "replace", key_path = "missing")
    end
    @test (base, first_update, second_update) == originals
end

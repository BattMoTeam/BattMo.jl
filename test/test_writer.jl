using BattMo
using JSON
using Test

@testset "write JSON dictionaries and input objects" begin
    parameters = Dict(
        "PositiveElectrode" => Dict("ActiveMaterial" => Dict("z" => 2.0, "a" => 1.0)),
        "NegativeElectrode" => Dict("ActiveMaterial" => Dict("z" => 4.0, "a" => 3.0)),
    )
    # JSON.Object preserves insertion order, so this also checks explicit sorting.
    nested = JSON.parse("""{"z": 0, "a": [{"z": 2, "a": 1}, [3, 2, 1]]}""")

    function check_sorted_keys(value)
        if value isa AbstractDict
            @test issorted(collect(keys(value)))
            foreach(check_sorted_keys, values(value))
        elseif value isa AbstractArray
            foreach(check_sorted_keys, value)
        end
    end

    mktempdir() do directory
        for (i, data) in enumerate((parameters, AdvancedDictInput(parameters), nested))
            if data isa BattMo.AbstractInput
                expected = data.all
            else
                expected = data
            end
            before = JSON.json(expected; sort_keys = false)
            path = joinpath(directory, "parameters-$i.json")
            @test write_to_json_file(path, data) === nothing
            parsed = JSON.parsefile(path)
            @test parsed == expected
            check_sorted_keys(parsed)
            @test JSON.json(expected; sort_keys = false) == before
        end
    end
end

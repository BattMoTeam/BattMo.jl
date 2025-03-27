using BattMo
using Test


@testset "sei layer" begin

	@test begin

		name = "bolay"

		fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
		inputparams = load_parameters(fn, BattMoInput)

		output = run_battery(inputparams)

		true

	end

end


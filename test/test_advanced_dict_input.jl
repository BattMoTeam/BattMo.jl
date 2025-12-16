using BattMo
using Test

names = [
	"p2d_40_jl_chen2020",
	"p2d_40_jl_ud_func",
	"p2d_40_jl_ud_tab",
	"p2d_40_no_cc",
	"p2d_40_cccv",
]

@testset "basic tests" begin
	for name in names
		@testset "$name" begin
			@test begin
				fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
				inputparams = load_advanced_dict_input(fn)


				inputparams["Control"]["rampupTime"] = 100
				inputparams["TimeStepping"]["timeStepDuration"] = 20

				output = run_simulation(inputparams; accept_invalid = true, error_on_incomplete = true)

				true
			end
		end
	end
end

function getinput(name)
	return load_advanced_dict_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

geometries = ["4680-geometry.json",
	"geometry-1d.json",
	"geometry-3d-demo.json"]

# @testset "iterative solvers" begin
# 	for geometry in geometries
# 		@testset "$geometry" begin
# 			@test begin

# 				inputparams_geometry = getinput(geometry)
# 				inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# 				inputparams_control  = getinput("cc_discharge_control.json")

# 				inputparams = merge_input_params([inputparams_geometry,
# 					inputparams_material,
# 					inputparams_control])


# 				cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_to_parameter_sets(inputparams)
# 				solver_settings = load_solver_settings(; from_default_set = "iterative")

# 				solver_settings["NonLinearSolver"]["MaxNonLinearIterations"] = 20
# 				solver_settings["NonLinearSolver"]["ErrorOnIncomplete"] = true

# 				model_setup = LithiumIonBattery(; model_settings)
# 				sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
# 				output = solve(sim;
# 					accept_invalid = true,
# 					solver_settings = solver_settings,
# 				)
# 				true
# 			end
# 		end
# 	end
# end


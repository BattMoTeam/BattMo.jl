using BattMo
using Test

names = [
	"p2d_40",
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
				inputparams = load_battmo_formatted_input(fn)
				function hook(simulator,
					model,
					state0,
					forces,
					timesteps,
					cfg)
					cfg[:error_on_incomplete] = true
				end
				output = run_battery(inputparams; hook)
				true
			end
		end
	end
end

function getinput(name)
    return load_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

geometries = ["4680-geometry.json",
              "geometry-1d.json", 
              "geometry-3d-demo.json"]

@testset "iterative solvers" begin
	for geometry in geometries
		@testset "$geometry" begin
			@test begin
                
                inputparams_geometry = getinput(geometry)
                inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
                inputparams_control  = getinput("cc_discharge_control.json")
                inputparams_solver   = getinput("solver_setup.json")

                inputparams = merge_input_params([inputparams_geometry,
                                                  inputparams_material,
                                                  inputparams_control,
                                                  inputparams_solver])

				function hook(simulator,
					model,
					state0,
					forces,
					timesteps,
					cfg)
					cfg[:error_on_incomplete] = true
				end
				output = run_battery(inputparams; hook)
				true
			end
		end
	end
end
    

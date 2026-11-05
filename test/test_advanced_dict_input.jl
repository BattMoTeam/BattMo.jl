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
                inputparams["TimeStepping"]["timeStepDuration"] = 200.0

                output = run_simulation(inputparams; accept_invalid = true)
                true
            end
        end
    end
end

function getinput(name)
    return load_advanced_dict_input(joinpath(pkgdir(BattMo), "test", "data", "jsonfiles", name))
end

geometries = [
    "4680-geometry.json",
    "geometry-1d.json",
    "geometry-3d-demo.json",
]

@testset "iterative solvers" begin
    for geometry in geometries
        @testset "$geometry" begin
            @test begin

                inputparams_geometry = getinput(geometry)
                inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
                inputparams_material["use_thermal"] = false
                inputparams_control = getinput("cc_discharge_control.json")

                inputparams = merge_input_params(
                    [
                        inputparams_geometry,
                        inputparams_material,
                        inputparams_control,
                    ]
                )


                cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_to_parameter_sets(inputparams)
                solver_settings = load_solver_settings(; from_default_set = "iterative")

                solver_settings["NonLinearSolver"]["MaxNonLinearIterations"] = 20
                solver_settings["NonLinearSolver"]["ErrorOnIncomplete"] = true

                model_setup = LithiumIonBattery(; model_settings)
                sim = Simulation(
                    model_setup,
                    cell_parameters,
                    cycling_protocol;
                    simulation_settings,
                    time_steps = [1.0],
                )
                output = solve(
                    sim;
                    accept_invalid = true,
                    solver_settings = solver_settings,
                )
                true
            end
        end
    end
end

@testset "conversion to the old input format" begin
    simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")
    inputparams = convert_parameter_sets_to_old_input_format(
        load_model_settings(; from_default_set = "p4d_pouch"),
        load_cell_parameters(; from_default_set = "xu_2015"),
        load_cycling_protocol(; from_default_set = "cc_discharge"),
        simulation_settings,
    )
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        coating = inputparams[electrode]["Coating"]
        current_collector = inputparams[electrode]["CurrentCollector"]
        @test coating["N"] == simulation_settings["$(electrode)CoatingGridPoints"]
        @test coating["ActiveMaterial"]["SolidDiffusion"]["N"] == simulation_settings["$(electrode)ParticleGridPoints"]
        @test current_collector["N"] == simulation_settings["$(electrode)CurrentCollectorGridPoints"]
        @test current_collector["tab"]["Nw"] == simulation_settings["TabWidthGridPoints"]
        @test current_collector["tab"]["Nh"] == simulation_settings["TabLengthGridPoints"]
    end
    @test inputparams["Separator"]["N"] == simulation_settings["SeparatorGridPoints"]
    @test inputparams["Geometry"]["Nw"] == simulation_settings["ElectrodeWidthGridPoints"]
    @test inputparams["Geometry"]["Nh"] == simulation_settings["ElectrodeLengthGridPoints"]
end

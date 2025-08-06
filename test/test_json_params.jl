using BattMo
using Test

function load_json(name::String)
    return load_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

function clean_up(fn::String)
    if isfile(fn)
        rm(fn)
    end
end


function get_inputparams(ocp_str::String = "")
    inputparams_geom = load_json("geometry-1d.json")
    inputparams_ctrl = load_json("cc_discharge_control.json")
    inputparms_solver = load_json("solver_setup.json")
    inputparams_mat = load_json("lithium_ion_battery_nmc_graphite.json")

    if ocp_str !== ""
        inputparams_mat["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["functionname"] = ocp_str
    end

    inputparams = merge_input_params([inputparams_geom, inputparams_mat, inputparams_ctrl, inputparms_solver])
    return inputparams
end


function get_input(ocp_str::String = "")
    inputparams = get_inputparams(ocp_str)
    input = get_simulation_input(inputparams)
    return input
end


function create_ocp(fn::String, fcn_name::String)

    clean_up(fn)

    str = """
    function $fcn_name(c, T, cmax)
    return 0.0
    end
    """
    open(fn, "w") do io
        println(io, str)
    end

end

function create_ocp_and_diffusion(fn::String, ocp_fcn_name::String, diffusion_fcn_name::String)

    clean_up(fn)

    str = """
    function $ocp_fcn_name(c, T, cmax)
        return 0.0
    end

    function $diffusion_fcn_name(c, T, cmax)
        return 1.0
    end
    """

    open(fn, "w") do io
        println(io, str)
    end

end



@testset "test_input" begin
    # Test the default input

    input = get_input()
    return true

end


@testset "test_ocp_from_included_function" begin
    # Test having the OCP be given by a file accessible in the BattMo
    # path. This file is added to julia's (global) scope. The file
    # name and function name are different.

    fn = joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", "dummy_filename.jl")
    fcn = "dummy_ocp"
    create_ocp(fn, fcn)

    #let
    include(fn)
    # eval(Meta.parse(read(fn, String)))
    input = get_input(fcn)
    #end

    clean_up(fn)

    return true

end


@testset "test_ocp_from_file_in_path" begin
    # Test having the OCP as a function in a file in the BattMo.jl
    # path. The file must have the same name as the function.

    fcn = "dummy_ocp2"
    fn = joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", fcn * ".jl")
    create_ocp(fn, fcn)
    input = get_input(fn) # full path inside BattMo.jl
    clean_up(fn)

    return true

end


@testset "test_ocp_from_file_outside_path" begin
    # Test having the OCP as a function in a file outside the
    # BattMo.jl path. The file must have the same name as the
    # function.

    fcn = "dummy_ocp3"
    fn = joinpath(tempdir(), fcn * ".jl")
    create_ocp(fn, fcn)
    input = get_input(fn) # full path outside BattMo.jl
    clean_up(fn)

    return true

end


@testset "test_ocp_from_file_without_extension" begin
    # To have json file compatability with julia and other programming
    # languages, we should be able to handle names without the .jl
    # extension in the json file

    fcn = "dummy_ocp4_without_extension"
    filename_in_json = joinpath(tempdir(), fcn)
    filename_of_file = filename_in_json * ".jl"
    create_ocp(filename_of_file, fcn)
    input = get_input(filename_in_json)
    clean_up(filename_of_file)

    return true

end

@testset "test_ocp_and_diffusion_in_same_file" begin
    # # The OCP and diffusion are given in a single file. This is
    # # not supported in all BattMo versions.

    # fcn = "dummy_ocp_and_diffusion"
    # fn = joinpath(tempdir(), fcn * ".jl")
    # create_ocp_and_diffusion(fn, "dummy_ocp", "dummy_diffusion")
    # input = get_input(fn)
    # clean_up(fn)

    return true

end

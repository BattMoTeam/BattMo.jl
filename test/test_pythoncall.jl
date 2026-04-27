using PythonCall
using BattMo
using Test
using Jutul


@testset "PythonCall extension is loaded" begin
    @test Base.get_extension(BattMo, :BattMoPythonCallExt) !== nothing
    @test hasmethod(BattMo.make_invokable, Tuple{PythonCall.Py})
end

@testset "extension is active for Python Py objects" begin
    pyfunc = pybuiltins.abs
    @test pyfunc isa PythonCall.Py
    wrapped = BattMo.make_invokable(pyfunc)
    @test wrapped isa Function
end


@testset "BattMo PythonCall extension with a builtin function" begin
    pyfunc = pybuiltins.abs
    wrapped = BattMo.make_invokable(pyfunc)
    @test wrapped(-3.0) == 3.0
end


@testset "make_invokable with Julia functions" begin
    f(x) = 2 * x
    wrapped = BattMo.make_invokable(f)
    @test wrapped(3.0) == 6.0
    @test wrapped(2) == 4
end


@testset "make_invokable with Python scalar function" begin
    math = pyimport("math")
    wrapped = BattMo.make_invokable(math.sqrt)
    @test wrapped(9.0) == 3.0
    @test wrapped(2.25) == 1.5
end


@testset "Injected Python callable is found in BattMo" begin
    pyimport("sys").path.append(joinpath(dirname(@__FILE__), "data", "python_files"))
    mod = pyimport("function_parameters_xu_2015")

    @eval BattMo electrolyte_conductivity_Xu_2015_py = $(mod.electrolyte_conductivity_Xu_2015_py)

    @test isdefined(BattMo, :electrolyte_conductivity_Xu_2015_py)
    @test getfield(BattMo, :electrolyte_conductivity_Xu_2015_py) isa PythonCall.Py
end


# We don't have this supported yet
@testset "Python array return is not supported by scalar wrapper" begin
    f = pyeval(PythonCall.Py, "lambda x: [x, x+1]", Main)
    wrapped = BattMo.make_invokable(f)
    @test_throws Exception wrapped(2.0)
end


@testset "pythoncall" begin

    @test begin

        # Add folder to Python path
        pyimport("sys").path.append(joinpath(dirname(@__FILE__), "data", "python_files"))

        # Import module with python input functions
        mod = pyimport("function_parameters_xu_2015")

        electrolyte_conductivity_Xu_2015_py = mod.electrolyte_conductivity_Xu_2015_py
        electrolyte_diffusivity_Xu_2015_py = mod.electrolyte_diffusivity_Xu_2015_py

        @eval BattMo electrolyte_conductivity_Xu_2015_py = $electrolyte_conductivity_Xu_2015_py
        @eval BattMo electrolyte_diffusivity_Xu_2015_py = $electrolyte_diffusivity_Xu_2015_py

        cell_parameters = load_cell_parameters(; from_default_set = "xu_2015")
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")

        cell_parameters["Electrolyte"]["IonicConductivity"] = Dict("FunctionName" => "electrolyte_conductivity_Xu_2015_py")
        cell_parameters["Electrolyte"]["DiffusionCoefficient"] = Dict("FunctionName" => "electrolyte_diffusivity_Xu_2015_py")

        model_setup = LithiumIonBattery()
        sim = Simulation(model_setup, cell_parameters, cycling_protocol)
        output = solve(sim)
        true

    end

end

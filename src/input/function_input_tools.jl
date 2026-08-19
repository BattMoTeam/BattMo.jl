export setup_function_from_function_name

function setup_function(base_path, parameter_value, component, parameter_name)

    if isa(parameter_value, Real)
        # This is a constant function, so we return a function that ignores its arguments and returns the constant value

        func = parameter_value
        func_type = :constant

    elseif isa(parameter_value, String)
        # This is a string expression, so we parse it and create a RuntimeGeneratedFunction
        exp = setup_evaluation_expression_from_string(parameter_value, component, parameter_name)
        func = @RuntimeGeneratedFunction(exp)
        func_type = :expression

    elseif isa(parameter_value, Dict)

        if haskey(parameter_value, "FunctionName")
            # This is a function defined by the user, so we check if it has a FunctionName key and set it up accordingly
            function_name = parameter_value["FunctionName"]

            if haskey(parameter_value, "FilePath")
                raw_path = parameter_value["FilePath"]
                function_path = joinpath(base_path, normalize_path(raw_path))
            else
                function_path = nothing
            end

            func = setup_function_from_function_name(function_name; file_path = function_path)
            func_type = :function

        elseif haskey(parameter_value, "x") && haskey(parameter_value, "y")
            # This is tabulated data, so we create an interpolating function
            data_x = parameter_value["x"]
            data_y = parameter_value["y"]

            func = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
            func_type = :interpolator
        else
            error("Dictionary input for parameter function must have either a 'FunctionName' key or 'x' and 'y' keys for tabulated data.")
        end
    else
        error("Unsupported type for parameter function. Must be either a Real, String, or Dict.")
    end

    return func, func_type

end

function setup_function_from_function_name(function_name::String; file_path::Union{String, Nothing} = nothing)
    symb = Symbol(function_name)

    if isdefined(BattMo, symb)
        func = getfield(BattMo, symb)
        return make_invokable(func)
    elseif isdefined(Main, symb)
        func = Base.invokelatest(() -> getfield(Main, symb))
        return make_invokable(func)
    elseif !isnothing(file_path)
        if isdefined(Main, symb)
            func = Base.invokelatest(() -> getfield(Main, symb))
            return make_invokable(func)
        elseif isfile(file_path)
            Base.include(Main, file_path)
            if isdefined(Main, symb)
                func = Base.invokelatest(() -> getfield(Main, symb))
                return make_invokable(func)
            else
                error("Function '$function_name' not defined in file '$file_path'.")
            end
        else
            error("Function '$function_name' not found and file '$file_path' does not exist.")
        end
    else
        error("Function $function_name is not found within BattMo and no path file is provided.")
    end
end

# --- Helper functions ---

function make_invokable(func::Function)
    return (args...) -> Base.invokelatest(func, args...)
end

function make_invokable(func)
    error("Unsupported callable type $(typeof(func)). Load the relevant extension or pass a Julia function. Only Python functions (via PythonCall) and Julia functions are currently supported.")
end

function setup_evaluation_expression_from_string(str, component, parameter_name)
    """ setup the Expr from a sting for the OCP function, with the proper signature."""

    if parameter_name == "OpenCircuitPotential"
        return setup_ocp_evaluation_expression_from_string(str)
    elseif parameter_name == "DiffusionCoefficient"
        if component == "Electrolyte"
            return setup_diffusivity_evaluation_expression_from_string(str)
        else
            return setup_electrode_diff_evaluation_expression_from_string(str)
        end
    elseif parameter_name == "IonicConductivity"
        return setup_conductivity_evaluation_expression_from_string(str)
    elseif parameter_name == "ReactionRateConstant"
        return setup_reaction_rate_constant_evaluation_expression_from_string(str)
    elseif parameter_name == "EntropyChange"
        return setup_entropy_change_evaluation_expression_from_string(str)
    else
        error(
            "ValueError: The parameter_name: '$parameter_name'is not recognized by the 'setup_evaluation_expression_from_string' function. Please enter 'OpenCircuitPotential', 'DiffusionCoefficient', 'IonicConductivity', 'ReactionRateConstant' or 'EntropyChange'.",
        )
    end

end

function setup_entropy_change_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the entropy change function, with the proper signature."""

    str = "function f(c, cmax) return $str end"
    return Meta.parse(str)

end


function setup_ocp_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the OCP function, with the proper signature."""

    str = "function f(c, T, refT, cmax) return $str end"
    return Meta.parse(str)

end

function setup_diffusivity_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the electrolyte diffusivity function, with the proper signature."""

    str = "function f(c, T) return $str end"
    return Meta.parse(str)

end

function setup_conductivity_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the electrolyte conductivity function, with the proper signature."""

    str = "function f(c, T) return $str end"
    return Meta.parse(str)

end

function setup_reaction_rate_constant_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the electrolyte conductivity function, with the proper signature."""

    str = "function f(c, T, refT, cmax) return $str end"
    return Meta.parse(str)

end

function setup_electrode_diff_evaluation_expression_from_string(str)
    """ setup the Expr from a sting for the OCP function, with the proper signature."""

    str = "function f(c, T, refT, cmax) return $str end"
    return Meta.parse(str)

end

export setup_function_from_function_name


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

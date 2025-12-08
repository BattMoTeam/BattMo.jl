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

function make_invokable(func)
	# if it's a Python function, wrap with pyconvert(Real, ...)
	if func isa Py
		return (args...) -> pyconvert(Real, func(args...))
	else
		return (args...) -> Base.invokelatest(func, args...)
	end
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

	str = "function f(c, T) return $str end"
	return Meta.parse(str)

end

function setup_electrode_diff_evaluation_expression_from_string(str)
	""" setup the Expr from a sting for the OCP function, with the proper signature."""

	str = "function f(c, T, refT, cmax) return $str end"
	return Meta.parse(str)

end

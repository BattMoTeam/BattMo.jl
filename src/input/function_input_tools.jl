export polyfit, update_json_input, compute_ocp_from_string

function polyfit(x,
	y;
	degree = 5)

	"""Compute the OCP fitted function for a material based on the given data"""

	# Check if x, and y are valid
	if ndims(x) > 1
		error("ValueError: x should be one-dimensional")
	elseif ndims(y) > 1
		error("ValueError: y should be one-dimensional")
	elseif size(x) != size(y)
		error("ValueError: size(y) should be equal to size(y)")

	end

	fit_ = fit(x, y, degree)


	return fit_
end

function update_json_input(; file_path::String = nothing,
	interpolation_object = nothing,
	component_name::String = nothing,
	x_name::String = nothing,
	y_name::String = nothing,
	new_file_path = nothing)

	"""Update json input file with a new function expression for the following quantities:
		- openCircuitPotential
		- Electrolyte conductivity
		- Electrolyte diffusion coefficient 
	"""

	if isa(interpolation_object, String)

		expression = interpolation_object
	else
		coeffs = coeffs(interpolation_object)
		expression = ""
		for i in collect(1:(size(coeffs)[1]-1))

			coeff = coeffs[i]
			j = i - 1
			if i == 1

				expression *= "$coeff "
			else
				expression *= "+ $coeff * $x_name^$j "
			end
		end
	end

	json_data = Dict{String, Any}()

	open(file_path, "r") do io
		json_data = JSON.parse(io)
	end


	if y_name == "openCircuitPotential"
		if !(x_name in ["SOC", "c", "T", "cmax"])
			error("ValueError: The x_name: '$x_name'is not recognized by the 'update_json_input' function. Please enter 'SOC', 'c', 'T' or 'cmax'.")
		end
		if haskey(json_data, component_name)
			if haskey(json_data[component_name], "Coating")
				if haskey(json_data[component_name]["Coating"], "ActiveMaterial")
					if haskey(json_data[component_name]["Coating"]["ActiveMaterial"], "Interface")
						if haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"], "openCircuitPotential")
							if haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"], "function")
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
							elseif haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"], "functionName")
								delete!(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"], "functionName")
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
							else
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
								json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
							end
						else
							json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["type"] = "function"
							json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
							json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]

						end
					else
						json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["type"] = "function"
						json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
						json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
					end
				else
					json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["type"] = "function"
					json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
					json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]

				end
			else
				json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["type"] = "function"
				json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
				json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]

			end
		else
			json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["type"] = "function"
			json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
			json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
		end
	elseif y_name == "ionicConductivity" || y_name == "diffusionCoefficient"
		if !(x_name in ["c", "T"])
			error("ValueError: The x_name: '$x_name'is not recognized by the 'update_json_input' function. Please enter 'c' or 'T'.")
		end
		if haskey(json_data, "Electrolyte")
			if haskey(json_data["Electrolyte"], y_name)
				if haskey(json_data["Electrolyte"][y_name], "function")
					json_data["Electrolyte"][y_name]["function"] = expression
					json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
				elseif haskey(json_data["Electrolyte"][y_name], "functionName")
					delete!(json_data["Electrolyte"][y_name], "functionName")
					json_data["Electrolyte"][y_name]["function"] = expression
					json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
				else
					json_data["Electrolyte"][y_name]["function"] = expression
					json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
				end
			else
				json_data["Electrolyte"][y_name]["type"] = "function"
				json_data["Electrolyte"][y_name]["function"] = expression
				json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
			end
		else
			json_data["Electrolyte"][y_name]["type"] = "function"
			json_data["Electrolyte"][y_name]["function"] = expression
			json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
		end

	else
		error("ValueError: The y_name: '$y_name'is not recognized by the 'update_json_input' function. Please enter 'openCircuitPotential', 'ionicConductivity' or 'diffusionCoefficient'.")
	end

	#json_data = JSON3.pretty(json_data);


	if new_file_path !== nothing
		open(new_file_path, "w") do io
			JSON.print(io, json_data, 4)
		end
	else

		open(file_path, "w") do io
			JSON.print(io, json_data, 4)
		end
	end


	return expression

end

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

function make_invokable(func)
	# if it's a Python function, wrap with pyconvert(Real, ...)
	if func isa Py
		return (args...) -> pyconvert(Real, func(args...))
	else
		return (args...) -> Base.invokelatest(func, args...)
	end
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

	str = "function f(c, T) return $str end"
	return Meta.parse(str)

end

function setup_electrode_diff_evaluation_expression_from_string(str)
	""" setup the Expr from a sting for the OCP function, with the proper signature."""

	str = "function f(c, T, refT, cmax) return $str end"
	return Meta.parse(str)

end

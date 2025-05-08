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
		for i in collect(1:size(coeffs)[1]-1)

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
							elseif haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"], "functionname")
								delete!(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"], "functionname")
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
				elseif haskey(json_data["Electrolyte"][y_name], "functionname")
					delete!(json_data["Electrolyte"][y_name], "functionname")
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

function setup_function_from_function_name(function_name::String)
    """
    Function to create a julia function given by the name of the function. In the case of user-defined functions, the file where the function is defined must have the same name as the function.
    """

    symb = Symbol(function_name)

    if isdefined(BattMo, symb)
        # Function in BattMo
        return getfield(BattMo, symb)
    else
        # User defined function
        filename = function_name * ".jl"
        code_str = read(filename, String)
        expr = Meta.parse(code_str)
        return @RuntimeGeneratedFunction(expr)
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


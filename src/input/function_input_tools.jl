export polyfit, update_json_input, compute_ocp_from_string

using JSON
using Polynomials

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

    fit = Polynomials.fit(x,y,degree)


    return fit
end

function update_json_input(;file_path::String = nothing,
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
    
    if isa(interpolation_object,String)

        expression = interpolation_object
    else
        coeffs = Polynomials.coeffs(interpolation_object)
        expression = ""
        for i in collect(1:size(coeffs)[1]-1)

            coeff = coeffs[i]
            j = i-1
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
        if  !(x_name in ["SOC", "c", "T", "cmax"])
            error("ValueError: The x_name: '$x_name'is not recognized by the 'update_json_input' function. Please enter 'SOC', 'c', 'T' or 'cmax'.")
        end
        if haskey(json_data, component_name)
            if haskey(json_data[component_name],"Coating")
                if haskey(json_data[component_name]["Coating"],"ActiveMaterial")
                    if haskey(json_data[component_name]["Coating"]["ActiveMaterial"],"Interface")
                        if haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"],"openCircuitPotential")
                            if haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"],"function")
                                json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["function"] = expression
                                json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]["argumentlist"] = [x_name]
                            elseif haskey(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"],"functionname")
                                delete!(json_data[component_name]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"],"functionname")
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
                if haskey(json_data["Electrolyte"][y_name],"function")
                    json_data["Electrolyte"][y_name]["function"] = expression
                    json_data["Electrolyte"][y_name]["argumentlist"] = [x_name]
                elseif haskey(json_data["Electrolyte"][y_name],"functionname")
                    delete!(json_data["Electrolyte"][y_name],"functionname")
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
        JSON.print(io, json_data,4)
        end
    end


    return expression

end

function setup_function(function_params)
    
    functionFormat = function_params["functionFormat"]
    
    if functionFormat == "string expression"

        found = false
        
        if haskey(function_params, "expression")
            
            if function_params["expression"]["language"] == "julia"
                
                found = true
                
                formula = function_params["expression"]["formula"]
                arguments = function_params["expression"]["variableNames"]
                exp = setup_evaluation_expression_from_string(formula, arguments)
                func = @RuntimeGeneratedFunction(exp)
                
            end
            
        elseif !found && haskey(function_params, "expressions")

            ind = findfirst(map(exp -> (exp["language"] == "julia"), function_params["expressions"]))

            if ind isa Nothing
                error("No julia expression found")
            else                # 
                formula = function_params["expressions"][ind]["formula"]
                arguments = function_params["expressions"][ind]["variableNames"]
                exp = setup_evaluation_expression_from_string(formula, arguments)
                func = @RuntimeGeneratedFunction(exp)
            end
        end
        
    elseif functionFormat == "named function"
        
        funcname = function_params["functionName"]
        func = getfield(BattMo, Symbol(funcname))
        
    elseif functionFormat == "tabulated"
        
        dataX = function_params["dataX"]
        dataY = function_params["dataY"]

        func = get_1d_interpolator(dataX, dataY, cap_endpoints =false)

    else
        
        error("functionFormat $functionFormat not recognized")
        
    end

    function_setup = (functionFormat = functionFormat, argumentList = function_params["argumentList"])
    
    return (func, function_setup)

end

function setup_evaluation_expression_from_string(formula, arguments)
    """ setup the Expr from a formula for the given list of arguments."""
    
    arg_str = join(arguments, ", ")
    
    str = "function f($arg_str) return $formula end"
    
    return Meta.parse(str);
    
end

function extend_signature(func)

    function newfunc(x, y)
        return func(x)
    end

    return newfunc
    
end



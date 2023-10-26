export polyfit, update_json_input

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
        - OCP
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


    if y_name == "OCP"
        if  !(x_name in ["SOC", "c", "T", "cmax"])
            error("ValueError: The x_name: '$x_name'is not recognized by the 'update_json_input' function. Please enter 'SOC', 'c', 'T' or 'cmax'.")
        end
        if haskey(json_data, component_name)
            if haskey(json_data[component_name],"ActiveMaterial")
                if haskey(json_data[component_name]["ActiveMaterial"],"Interface")
                    if haskey(json_data[component_name]["ActiveMaterial"]["Interface"],"OCP")
                        if haskey(json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"],"function")
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
                        elseif haskey(json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"],"functionname")
                            delete!(json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"],"functionname")
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
                        else
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
                        end
                    else
                        json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["type"] = "function"
                        json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                        json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
                        
                    end
                else
                    json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["type"] = "function"
                    json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                    json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
                end
            else
                json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["type"] = "function"
                json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
                json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]

            end
        else
            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["type"] = "function"
            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["function"] = expression
            json_data[component_name]["ActiveMaterial"]["Interface"]["OCP"]["argumentlist"] = [x_name]
        end
    elseif y_name == "Conductivity" || y_name == "Diffusitivity"
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
        error("ValueError: The y_name: '$y_name'is not recognized by the 'update_json_input' function. Please enter 'OCP', 'Conductivity' or 'Diffusitivity'.")
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


function compute_function_from_string(ocp_eq)

    eval(Meta.parse(ocp_eq))
end
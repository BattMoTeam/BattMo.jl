export polyfit, update_json_input

using JSON
using Polynomials

function polyfit(x,
    y;
    degree = 5)

"""Compute the OCP interpolated function for a material based on the given data"""

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

    coeffs = Polynomials.coeffs(interpolation_object)
    print("ex = ", coeffs)
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
    json_data = Dict{String, Any}()

    open(file_path, "r") do io
    json_data = JSON.parse(io)
    end



    if haskey(json_data, component_name)
        if y_name == "OCP"
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
                        end
                    end
                end
            else

            end
        end
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



function validate_parameter_set(inputparams::CellParameters,model::Type{<: SimulationModel})

    # Get required fields from the model struct
    required_fields = fieldnames(model)

    # Check if all required fields are present in inputparams
    missing_fields = [field for field in required_fields if !haskey(inputparams, field)]

    if isempty(missing_fields)
        println("Validation successful: All required parameters are present.")
        return true
    else
        println("Validation failed: Missing parameters - ", missing_fields)
        return false
    end

end
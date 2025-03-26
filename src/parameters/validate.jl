export validate_parameter_set


function validate_parameter_set(inputparams::CellParameters, model::Type{<:SimulationModel})

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


function validate_parameter_set(parameter_set::ModelSettings)


end


function validate_model_settings(parameter_set::ModelSettings)

end


function get_required_model_settings()

	model_settings = [
		"ModelGeometry",
		"UseThermalModel",
		"UseCurrentCollectors",
		"UseRampUp",
	]

	return model_settings

end

function get_required_protocol_parameters(protocol)

	if protocol == "GalvanostaticCycling"

		cycling_parameters = [
			"Protocol",
			"TotalNumberOfCycles",
			"CRate",
			"DRate",
			"LowerVoltageLimit",
			"UpperVoltageLimit",
			"StartWithCharge",
			"RestingTimeAfterCharge",
			"RestingTimeAfterDischarge",
			"AmbientCelsiusTemperature",
		]


	elseif protocol == "ConstantCurrentConstantVoltageCycling"

		cycling_parameters = [
			"Protocol",
			"TotalNumberOfCycles",
			"CRate",
			"DRate",
			"LowerVoltageLimit",
			"UpperVoltageLimit",
			"StartWithCharge",
			"RestingTimeAfterCharge",
			"RestingTimeAfterDischarge",
			"CurrentChangeLimit",
			"VoltageChangeLimit",
			"AmbientCelsiusTemperature",
		]

	elseif isnothing(protocol)

		error("The protocol is not defined.")

	else

		error("Protocol $protocol is not handled")

	end
end

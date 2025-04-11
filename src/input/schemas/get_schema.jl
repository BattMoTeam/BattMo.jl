export get_schema_cell_parameters, get_schema_cycling_protocol, get_schema_simulation_settings, get_schema_model_settings

function julia_to_json_schema_type!(dict, meta::Dict)
	if meta["type"] == Real
		dict["type"] = "number"  # JSON schema type for Real numbers (includes both integer and float)
		dict["minimum"] = get(meta, "min_value", nothing)  # Enforce min value if present
		dict["maximum"] = get(meta, "max_value", nothing)  # Enforce max value if present
		dict["description"] = get(meta, "description", "")  # Optional documentation
		dict["unit"] = get(meta, "unit", "")  # Optional unit annotation

	elseif meta["type"] == Int
		dict["type"] = "integer"  # JSON schema type for Int (integer numbers)
		dict["minimum"] = get(meta, "min_value", nothing)  # Enforce min value if present
		dict["maximum"] = get(meta, "max_value", nothing)  # Enforce max value if present
		dict["description"] = get(meta, "description", "")  # Optional documentation
		dict["unit"] = get(meta, "unit", "")  # Optional unit annotation

	elseif meta["type"] == Bool
		dict["type"] = "boolean"  # JSON schema type for String
		dict["description"] = get(meta, "description", "")  # Optional documentation

	elseif meta["type"] == String
		dict["type"] = "string"  # JSON schema type for Bool
		dict["enum"] = get(meta, "options", nothing)  # Enforce max value if present
		dict["description"] = get(meta, "description", "")  # Optional documentation

	elseif meta["type"] isa Vector{Type}

		oneof_list = []
		push!(oneof_list, Dict("type" => "number"))
		push!(
			oneof_list,
			Dict(
				"type" => "object",
				"properties" => Dict(
					"type" => Dict("type" => "string", "enum" => ["function"]),
					"functionname" => Dict("type" => "string"),
					"argumentlist" => Dict(
						"type" => "array",
						"items" => Dict("type" => "string"),
					),
				),
				"required" => ["type", "functionname", "argumentlist"],
				"additionalProperties" => false,
			),
		)
		push!(
			oneof_list,
			Dict(
				"type" => "object",
				"properties" => Dict(
					"type" => Dict("type" => "string", "enum" => ["function"]),
					"function" => Dict("type" => "string"),
					"argumentlist" => Dict(
						"type" => "array",
						"items" => Dict("type" => "string"),
					),
				),
				"required" => ["type", "function", "argumentlist"],
				"additionalProperties" => false,
			),
		)
		push!(
			oneof_list,
			Dict(
				"type" => "object",
				"properties" => Dict(
					"type" => Dict("type" => "string", "enum" => ["function"]),
					"data_x" => Dict(
						"type" => "array",
						"items" => Dict("type" => "number"),
					),
					"data_y" => Dict(
						"type" => "array",
						"items" => Dict("type" => "number"),
					),
					"argumentlist" => Dict(
						"type" => "array",
						"items" => Dict("type" => "string"),
					),
				),
				"required" => ["type", "data_x", "data_y", "argumentlist"],
				"additionalProperties" => false,
			),
		)

		dict["oneOf"] = oneof_list

		# Functions aren't directly representable in JSON, treating as string (function name or identifier)

	elseif meta["type"] == Vector
		dict["type"] = "array"  # JSON schema type for arrays (Vector in Julia)
	else
		type = meta["type"]
		throw(ArgumentError("Unknown Julia type: $type"))
	end
end

function create_property(parameter_meta, name)
	meta = get(parameter_meta, name, nothing)  # Get meta-data or empty Dict
	# Create the dictionary
	property = Dict()
	if isnothing(meta)
		error("KeyError: Key $name is not found")
	else
		julia_to_json_schema_type!(property, meta)  # Enforce correct type

	end

	# Filter out `nothing` values
	return filter(x -> x.second !== nothing, property)
end

function get_schema_cell_parameters(model_settings::ModelSettings)
	# Retrieve meta-data for validation
	parameter_meta = get_parameter_meta_data()

	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"Metadata" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Title" => Dict("type" => "string"),
					"Source" => Dict("type" => "string", "format" => "uri"),
					"Description" => Dict("type" => "string"),
				),
			),
			"Cell" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Case" => create_property(parameter_meta, "Case"),
					"DeviceSurfaceArea" => create_property(parameter_meta, "DeviceSurfaceArea"),
					"DubbelCoatedElectrodes" => create_property(parameter_meta, "DubbelCoatedElectrodes"),
					"NominalVoltage" => create_property(parameter_meta, "NominalVoltage"),
					"NominalCapacity" => create_property(parameter_meta, "NominalCapacity"),
					"HeatTransferCoefficient" => create_property(parameter_meta, "HeatTransferCoefficient"),
					"InnerCellRadius" => create_property(parameter_meta, "InnerCellRadius"),
					"ElectrodeWidth" => create_property(parameter_meta, "ElectrodeWidth"),
					"ElectrodeLength" => create_property(parameter_meta, "ElectrodeLength"),
					"ElectrodeGeometricSurfaceArea" => create_property(parameter_meta, "ElectrodeGeometricSurfaceArea"),
				),
				"required" => ["Case"],
			),
			"NegativeElectrode" => Dict(
				"type" => "object",
				"properties" => Dict(
					"ElectrodeCoating" => Dict(
						"type" => "object",
						"properties" => Dict(
							"BruggemanCoefficient" => create_property(parameter_meta, "BruggemanCoefficient"),
							"EffectiveDensity" => create_property(parameter_meta, "EffectiveDensity"),
							"Thickness" => create_property(parameter_meta, "Thickness"),
							"SurfaceCoefficientOfHeatTransfer" => create_property(parameter_meta, "SurfaceCoefficientOfHeatTransfer"),
						),
						"required" => ["BruggemanCoefficient", "EffectiveDensity", "Thickness"],
					),
					"ActiveMaterial" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"Density" => create_property(parameter_meta, "Density"),
							"VolumetricSurfaceArea" => create_property(parameter_meta, "VolumetricSurfaceArea"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
							"DiffusionCoefficient" => create_property(parameter_meta, "DiffusionCoefficient"),
							"ParticleRadius" => create_property(parameter_meta, "ParticleRadius"),
							"MaximumConcentration" => create_property(parameter_meta, "MaximumConcentration"),
							"StoichiometricCoefficientAtSOC0" => create_property(parameter_meta, "StoichiometricCoefficientAtSOC0"),
							"StoichiometricCoefficientAtSOC100" => create_property(parameter_meta, "StoichiometricCoefficientAtSOC100"),
							"OpenCircuitVoltage" => create_property(parameter_meta, "OpenCircuitVoltage"),
							"NumberOfElectronsTransfered" => create_property(parameter_meta, "NumberOfElectronsTransfered"),
							"ActivationEnergyOfReaction" => create_property(parameter_meta, "ActivationEnergyOfReaction"),
							"ReactionRateConstant" => create_property(parameter_meta, "ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property(parameter_meta, "ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitVoltage", "NumberOfElectronsTransfered", "ActivationEnergyOfReaction", "ReactionRateConstant", "ChargeTransferCoefficient"],
					),
					"Interphase" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MolarVolume" => create_property(parameter_meta, "MolarVolume"),
							"IonicConductivity" => create_property(parameter_meta, "IonicConductivity"),
							"ElectronicDiffusionCoefficient" => create_property(parameter_meta, "ElectronicDiffusionCoefficient"),
							"StoichiometricCoefficient" => create_property(parameter_meta, "StoichiometricCoefficient"),
							"IntersticialConcentration" => create_property(parameter_meta, "IntersticialConcentration"),
							"InitialThickness" => create_property(parameter_meta, "InitialThickness"),
						),
						"required" => ["MolarVolume", "IonicConductivity", "ElectronicDiffusionCoefficient", "StoichiometricCoefficient", "IntersticialConcentration", "InitialThickness"],
					),
					"ConductiveAdditive" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"Binder" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"CurrentCollector" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
						),
						"required" => ["Density", "Thickness", "ElectronicConductivity"],
					)),
				"required" => ["ElectrodeCoating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
			),
			"PositiveElectrode" => Dict(
				"type" => "object",
				"properties" => Dict(
					"ElectrodeCoating" => Dict(
						"type" => "object",
						"properties" => Dict(
							"BruggemanCoefficient" => create_property(parameter_meta, "BruggemanCoefficient"),
							"EffectiveDensity" => create_property(parameter_meta, "EffectiveDensity"),
							"Thickness" => create_property(parameter_meta, "Thickness"),
							"SurfaceCoefficientOfHeatTransfer" => create_property(parameter_meta, "SurfaceCoefficientOfHeatTransfer"),
						),
						"required" => ["BruggemanCoefficient", "EffectiveDensity", "Thickness"],
					),
					"ActiveMaterial" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"Density" => create_property(parameter_meta, "Density"),
							"VolumetricSurfaceArea" => create_property(parameter_meta, "VolumetricSurfaceArea"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
							"DiffusionCoefficient" => create_property(parameter_meta, "DiffusionCoefficient"),
							"ParticleRadius" => create_property(parameter_meta, "ParticleRadius"),
							"MaximumConcentration" => create_property(parameter_meta, "MaximumConcentration"),
							"StoichiometricCoefficientAtSOC0" => create_property(parameter_meta, "StoichiometricCoefficientAtSOC0"),
							"StoichiometricCoefficientAtSOC100" => create_property(parameter_meta, "StoichiometricCoefficientAtSOC100"),
							"OpenCircuitVoltage" => create_property(parameter_meta, "OpenCircuitVoltage"),
							"NumberOfElectronsTransfered" => create_property(parameter_meta, "NumberOfElectronsTransfered"),
							"ActivationEnergyOfReaction" => create_property(parameter_meta, "ActivationEnergyOfReaction"),
							"ReactionRateConstant" => create_property(parameter_meta, "ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property(parameter_meta, "ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitVoltage", "NumberOfElectronsTransfered", "ActivationEnergyOfReaction", "ReactionRateConstant", "ChargeTransferCoefficient"],
					),
					"Interphase" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MolarVolume" => create_property(parameter_meta, "MolarVolume"),
							"IonicConductivity" => create_property(parameter_meta, "IonicConductivity"),
							"ElectronicDiffusionCoefficient" => create_property(parameter_meta, "ElectronicDiffusionCoefficient"),
							"StoichiometricCoefficient" => create_property(parameter_meta, "StoichiometricCoefficient"),
							"IntersticialConcentration" => create_property(parameter_meta, "IntersticialConcentration"),
							"InitialThickness" => create_property(parameter_meta, "InitialThickness"),
						),
						"required" => ["MolarVolume", "IonicConductivity", "ElectronicDiffusionCoefficient", "StoichiometricCoefficient", "IntersticialConcentration", "InitialThickness"],
					),
					"ConductiveAdditive" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"Binder" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
							"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"CurrentCollector" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property(parameter_meta, "Density"),
							"MassFraction" => create_property(parameter_meta, "MassFraction"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
						),
						"required" => ["Density", "Thickness", "ElectronicConductivity"],
					)),
				"required" => ["ElectrodeCoating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
			),
			"Separator" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Porosity" => create_property(parameter_meta, "Porosity"),
					"Density" => create_property(parameter_meta, "Density"),
					"BruggemanCoefficient" => create_property(parameter_meta, "BruggemanCoefficient"),
					"Thickness" => create_property(parameter_meta, "Thickness"),
					"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
					"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
				),
				"required" => ["Porosity", "Density", "BruggemanCoefficient", "Thickness"],
			),
			"Electrolyte" => Dict(
				"type" => "object",
				"properties" => Dict(
					"SpecificHeatCapacity" => create_property(parameter_meta, "SpecificHeatCapacity"),
					"ThermalConductivity" => create_property(parameter_meta, "ThermalConductivity"),
					"Density" => create_property(parameter_meta, "Density"),
					"Concentration" => create_property(parameter_meta, "Concentration"),
					"IonicConductivity" => create_property(parameter_meta, "IonicConductivity"),
					"DiffusionCoefficient" => create_property(parameter_meta, "DiffusionCoefficient"),
					"ChargeNumber" => create_property(parameter_meta, "ChargeNumber"),
					"TransferenceNumber" => create_property(parameter_meta, "TransferenceNumber"),
				),
				"required" => ["Concentration", "Density", "DiffusionCoefficient", "IonicConductivity", "ChargeNumber", "TransferenceNumber"],
			),
		),
		"required" => ["Cell", "NegativeElectrode", "PositiveElectrode", "Separator", "Electrolyte"],
	)

	cell_required = schema["properties"]["Cell"]["required"]
	ne_required = schema["properties"]["NegativeElectrode"]["required"]
	ne_coating_required = schema["properties"]["NegativeElectrode"]["properties"]["ElectrodeCoating"]["required"]
	pe_coating_required = schema["properties"]["PositiveElectrode"]["properties"]["ElectrodeCoating"]["required"]

	ne_am_required = schema["properties"]["NegativeElectrode"]["properties"]["ActiveMaterial"]["required"]
	pe_am_required = schema["properties"]["PositiveElectrode"]["properties"]["ActiveMaterial"]["required"]

	ne_ca_required = schema["properties"]["NegativeElectrode"]["properties"]["ConductiveAdditive"]["required"]
	pe_ca_required = schema["properties"]["PositiveElectrode"]["properties"]["ConductiveAdditive"]["required"]

	ne_b_required = schema["properties"]["NegativeElectrode"]["properties"]["Binder"]["required"]
	pe_b_required = schema["properties"]["PositiveElectrode"]["properties"]["Binder"]["required"]

	sep_required = schema["properties"]["Separator"]["required"]
	elyte_required = schema["properties"]["Electrolyte"]["required"]

	model_settings_dict = model_settings.all

	if model_settings_dict["ModelGeometry"] == "1D"
		push!(cell_required, "ElectrodeGeometricSurfaceArea")
		if haskey(model_settings_dict, "UseThermalModel")
			push!(cell_required, "DeviceSurfaceArea")
			push!(cell_required, "HeatTransferCoefficient")
			push!(ne_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(pe_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(ne_am_required, "SpecificHeatCapacity")
			push!(ne_am_required, "ThermalConductivity")
			push!(pe_am_required, "SpecificHeatCapacity")
			push!(pe_am_required, "ThermalConductivity")
			push!(ne_ca_required, "SpecificHeatCapacity")
			push!(ne_ca_required, "ThermalConductivity")
			push!(pe_ca_required, "SpecificHeatCapacity")
			push!(pe_ca_required, "ThermalConductivity")
			push!(ne_b_required, "SpecificHeatCapacity")
			push!(ne_b_required, "ThermalConductivity")
			push!(pe_b_required, "SpecificHeatCapacity")
			push!(pe_b_required, "ThermalConductivity")
			push!(sep_required, "SpecificHeatCapacity")
			push!(sep_required, "ThermalConductivity")
			push!(elyte_required, "SpecificHeatCapacity")
			push!(elyte_required, "ThermalConductivity")

		end

	elseif model_settings_dict["ModelGeometry"] == "3D Pouch"
		push!(cell_required, "ElectrodeWidth")
		push!(cell_required, "ElectrodeLength")
		if model_settings_dict["UseThermalModel"]
			push!(cell_required, "DeviceSurfaceArea")
			push!(cell_required, "HeatTransferCoefficient")
			push!(ne_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(pe_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(ne_am_required, "SpecificHeatCapacity")
			push!(ne_am_required, "ThermalConductivity")
			push!(pe_am_required, "SpecificHeatCapacity")
			push!(pe_am_required, "ThermalConductivity")
			push!(ne_ca_required, "SpecificHeatCapacity")
			push!(ne_ca_required, "ThermalConductivity")
			push!(pe_ca_required, "SpecificHeatCapacity")
			push!(pe_ca_required, "ThermalConductivity")
			push!(ne_b_required, "SpecificHeatCapacity")
			push!(ne_b_required, "ThermalConductivity")
			push!(pe_b_required, "SpecificHeatCapacity")
			push!(pe_b_required, "ThermalConductivity")
			push!(sep_required, "SpecificHeatCapacity")
			push!(sep_required, "ThermalConductivity")
			push!(elyte_required, "SpecificHeatCapacity")
			push!(elyte_required, "ThermalConductivity")
		end

	elseif model_settings_dict["ModelGeometry"] == "3D Cyclindrical"

		push!(cell_required, "DubbelCoatedElectrodes")
		push!(cell_required, "InnerCellRadius")

		push!(ne_coating_required, "Width")
		push!(ne_coating_required, "Length")
		push!(pe_coating_required, "Width")
		push!(pe_coating_required, "Length")

		if haskey(model_settings_dict, "UseThermalModel")
			push!(cell_required, "DeviceSurfaceArea")
			push!(cell_required, "HeatTransferCoefficient")
			push!(ne_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(pe_coating_required, "SurfaceCoefficientOfHeatTransfer")
			push!(ne_am_required, "SpecificHeatCapacity")
			push!(ne_am_required, "ThermalConductivity")
			push!(pe_am_required, "SpecificHeatCapacity")
			push!(pe_am_required, "ThermalConductivity")
			push!(ne_ca_required, "SpecificHeatCapacity")
			push!(ne_ca_required, "ThermalConductivity")
			push!(pe_ca_required, "SpecificHeatCapacity")
			push!(pe_ca_required, "ThermalConductivity")
			push!(ne_b_required, "SpecificHeatCapacity")
			push!(ne_b_required, "ThermalConductivity")
			push!(pe_b_required, "SpecificHeatCapacity")
			push!(pe_b_required, "ThermalConductivity")
			push!(sep_required, "SpecificHeatCapacity")
			push!(sep_required, "ThermalConductivity")
			push!(elyte_required, "SpecificHeatCapacity")
			push!(elyte_required, "ThermalConductivity")

		end

	end

	if haskey(model_settings_dict, "UseSEIModel") && model_settings_dict["UseSEIModel"] == "Bolay"
		push!(ne_required, "Interphase")
	end

	return schema
end


function get_schema_cycling_protocol()
	# Retrieve meta-data for validation
	parameter_meta = get_parameter_meta_data()
	return Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"Protocol" => create_property(parameter_meta, "Protocol"),
			"InitialStateOfCharge" => create_property(parameter_meta, "InitialStateOfCharge"),
			"TotalNumberOfCycles" => create_property(parameter_meta, "TotalNumberOfCycles"),
			"CRate" => create_property(parameter_meta, "CRate"),
			"DRate" => create_property(parameter_meta, "DRate"),
			"LowerVoltageLimit" => create_property(parameter_meta, "LowerVoltageLimit"),
			"UpperVoltageLimit" => create_property(parameter_meta, "UpperVoltageLimit"),
			"InitialControl" => create_property(parameter_meta, "InitialControl"),
			"CurrentChangeLimit" => create_property(parameter_meta, "CurrentChangeLimit"),
			"VoltageChangeLimit" => create_property(parameter_meta, "VoltageChangeLimit"),
			"AmbientKelvinTemperature" => create_property(parameter_meta, "AmbientKelvinTemperature"),
			"InitialKelvinTemperature" => create_property(parameter_meta, "InitialKelvinTemperature"),
		),
		"required" => ["Protocol"],
		"allOf" => [
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CCCV"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"TotalNumberOfCycles",
						"CRate",
						"DRate",
						"LowerVoltageLimit",
						"UpperVoltageLimit",
						"InitialControl",
						"CurrentChangeLimit",
						"VoltageChangeLimit",
						"AmbientKelvinTemperature",
						"InitialKelvinTemperature",
					],
				),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CCDischarge"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"DRate",
						"LowerVoltageLimit",
						"UpperVoltageLimit",
						"InitialControl",
						"AmbientKelvinTemperature",
						"InitialKelvinTemperature",
					],
				),
			),
		],
	)
end


function get_schema_simulation_settings(model_settings)
	parameter_meta = get_parameter_meta_data()
	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"GridPoints" => Dict(
				"type" => "object",
				"properties" => Dict(
					"ElectrodeWidth" => create_property(parameter_meta, "GridPointsElectrodeWidth"),
					"ElectrodeLength" => create_property(parameter_meta, "GridPointsElectrodeLength"),
					"PositiveElectrodeCoating" => create_property(parameter_meta, "GridPointsPositiveElectrodeCoating"),
					"PositiveElectrodeActiveMaterial" => create_property(parameter_meta, "GridPointsPositiveElectrodeActiveMaterial"),
					"PositiveElectrodeCurrentCollector" => create_property(parameter_meta, "GridPointsPositiveElectrodeCurrentCollector"),
					"PositiveElectrodeCurrentCollectorTabWidth" => create_property(parameter_meta, "GridPointsPositiveElectrodeCurrentCollectorTabWidth"),
					"PositiveElectrodeCurrentCollectorTabLength" => create_property(parameter_meta, "GridPointsPositiveElectrodeCurrentCollectorTabLength"),
					"NegativeElectrodeCoating" => create_property(parameter_meta, "GridPointsNegativeElectrodeCoating"),
					"NegativeElectrodeActiveMaterial" => create_property(parameter_meta, "GridPointsNegativeElectrodeActiveMaterial"),
					"NegativeElectrodeCurrentCollector" => create_property(parameter_meta, "GridPointsNegativeElectrodeCurrentCollector"),
					"NegativeElectrodeCurrentCollectorTabWidth" => create_property(parameter_meta, "GridPointsNegativeElectrodeCurrentCollectorTabWidth"),
					"NegativeElectrodeCurrentCollectorTabLength" => create_property(parameter_meta, "GridPointsNegativeElectrodeCurrentCollectorTabLength"),
					"Separator" => create_property(parameter_meta, "GridPointsSeparator"),
				),
				"required" => [
					"PositiveElectrodeCoating",
					"PositiveElectrodeActiveMaterial",
					"NegativeElectrodeCoating",
					"NegativeElectrodeActiveMaterial",
					"Separator",
				],
			),
			"Grid" => Dict(
				"type" => "array",
			),
			"TimeStepDuration" => Dict("type" => "integer"),
			"RampUpTime" => Dict("type" => "integer"),
			"RampUpSteps" => Dict("type" => "integer"),
		),
		"required" => ["GridPoints", "Grid", "TimeStepDuration", "RampUpTime", "RampUpSteps"],
	)

	required_grid_points = schema["properties"]["GridPoints"]["required"]

	if model_settings["ModelGeometry"] == "3D-demo"
		push!(required_grid_points, "ElectrodeWidth")
		push!(required_grid_points, "ElectrodeLength")

		if haskey(model_settings, "UseCurrentCollectors")
			push!(required_grid_points, "PositiveElectrodeCurrentCollector")
			push!(required_grid_points, "PositiveElectrodeCurrentCollectorTabWidth")
			push!(required_grid_points, "PositiveElectrodeCurrentCollectorTabLength")
			push!(required_grid_points, "NegativeElectrodeCurrentCollector")
			push!(required_grid_points, "NegativeElectrodeCurrentCollectorTabWidth")
			push!(required_grid_points, "NegativeElectrodeCurrentCollectorTabLength")
		end
	end

	return schema
end


function get_schema_model_settings()
	parameter_meta = get_parameter_meta_data()
	return Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"ModelGeometry" => create_property(parameter_meta, "ModelGeometry"),
			"UseThermalModel" => create_property(parameter_meta, "UseThermalModel"),
			"UseCurrentCollectors" => create_property(parameter_meta, "UseCurrentCollectors"),
			"UseRampUp" => create_property(parameter_meta, "UseRampUp"),
			"UseSEIModel" => create_property(parameter_meta, "UseSEIModel"),
			"UseDiffusionModel" => create_property(parameter_meta, "UseDiffusionModel"),
		),
		"required" => [
			"ModelGeometry",
		],
		"allOf" => [
			# 🚫 Disallow UseCurrentCollectors if ModelGeometry is "1D"
			Dict(
				"if" => Dict(
					"properties" => Dict("ModelGeometry" => Dict("const" => "1D")),
					"required" => ["ModelGeometry"],
				),
				"then" => Dict(
					"not" => Dict(
						"required" => ["UseCurrentCollectors"],
					),
				),
			),

			# 🚫 Disallow UseThermalModel if ModelGeometry is "3D-demo"
			Dict(
				"if" => Dict(
					"properties" => Dict("ModelGeometry" => Dict("const" => "3D-demo")),
					"required" => ["ModelGeometry"],
				),
				"then" => Dict(
					"not" => Dict(
						"required" => ["UseThermalModel"],
					),
				),
			),
		],
	)

end


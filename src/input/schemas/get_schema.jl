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

	elseif isa(meta["type"], Vector) && all(isa.(meta["type"], DataType))


		oneof_list = []
		push!(oneof_list, Dict("type" => "number"))
		push!(
			oneof_list,
			Dict(
				"type" => "object",
				"properties" => Dict(
					"x" => Dict("type" => "array"),
					"y" => Dict("type" => "array"),
				),
				"required" => ["x", "y"],
				"additionalProperties" => true,
			),
		)
		push!(
			oneof_list,
			Dict(
				"type" => "string",
			),
		)
		push!(
			oneof_list,
			Dict(
				"type" => "object",
				"properties" => Dict(
					"FunctionName" => Dict("type" => "string"),
					"FilePath" => Dict("type" => "string"),
				),
				"required" => ["FunctionName"],
				"additionalProperties" => true,
			),
		)

		dict["oneOf"] = oneof_list

		# Functions aren't directly representable in JSON, treating as string (function name or identifier)

	elseif meta["type"] == Vector
		dict["type"] = "array"  # JSON schema type for arrays (Vector in Julia)
	elseif meta["type"] == Nothing
		dict["type"] = "null"
	elseif meta["type"] == Dict
		dict["type"] = "object"
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
	parameter_meta = get_cell_parameters_meta_data()

	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"Metadata" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Title" => Dict("type" => "string"),
					"Source" => Dict(
						"anyOf" => [
							Dict("type" => "string", "format" => "uri"),
							Dict(
								"type" => "array",
								"items" => Dict("type" => "string", "format" => "uri"),
							),
						],
					),
					"Description" => Dict("type" => "string"),
				),
			),
			"Cell" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Case" => create_property(parameter_meta, "Case"),
					"DeviceSurfaceArea" => create_property(parameter_meta, "DeviceSurfaceArea"),
					"InnerRadius" => create_property(parameter_meta, "InnerRadius"),
					"OuterRadius" => create_property(parameter_meta, "OuterRadius"),
					"NominalVoltage" => create_property(parameter_meta, "NominalVoltage"),
					"NominalCapacity" => create_property(parameter_meta, "NominalCapacity"),
					"HeatTransferCoefficient" => create_property(parameter_meta, "HeatTransferCoefficient"),
					"ElectrodeWidth" => create_property(parameter_meta, "ElectrodeWidth"),
					"ElectrodeLength" => create_property(parameter_meta, "ElectrodeLength"),
					"NumberOfLayersInParallel" => create_property(parameter_meta, "NumberOfLayersInParallel"),
					"DoubleCoatedElectrodes" => create_property(parameter_meta, "DoubleCoatedElectrodes"),
					"TabsOnSameSide" => create_property(parameter_meta, "TabsOnSameSide"),
					"TabLength" => create_property(parameter_meta, "TabLength"),
					"TabWidth" => create_property(parameter_meta, "TabWidth"),
					"Height" => create_property(parameter_meta, "Height"),
					"ElectrodeGeometricSurfaceArea" => create_property(parameter_meta, "ElectrodeGeometricSurfaceArea"),
				),
				"required" => [],
			),
			"NegativeElectrode" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Coating" => Dict(
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
							"OpenCircuitPotential" => create_property(parameter_meta, "OpenCircuitPotential"),
							"NumberOfElectronsTransfered" => create_property(parameter_meta, "NumberOfElectronsTransfered"),
							"ActivationEnergyOfReaction" => create_property(parameter_meta, "ActivationEnergyOfReaction"),
							"ActivationEnergyOfDiffusion" => create_property(parameter_meta, "ActivationEnergyOfDiffusion"),
							"ReactionRateConstant" => create_property(parameter_meta, "ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property(parameter_meta, "ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitPotential", "NumberOfElectronsTransfered", "ReactionRateConstant", "ChargeTransferCoefficient"],
					),
					"Interphase" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MolarVolume" => create_property(parameter_meta, "MolarVolume"),
							"IonicConductivity" => create_property(parameter_meta, "IonicConductivity"),
							"ElectronicDiffusionCoefficient" => create_property(parameter_meta, "ElectronicDiffusionCoefficient"),
							"StoichiometricCoefficient" => create_property(parameter_meta, "StoichiometricCoefficient"),
							"InterstitialConcentration" => create_property(parameter_meta, "InterstitialConcentration"),
							"InitialThickness" => create_property(parameter_meta, "InitialThickness"),
							"InitialPotentialDrop" => create_property(parameter_meta, "InitialPotentialDrop"),
						),
						"required" => ["MolarVolume", "IonicConductivity", "ElectronicDiffusionCoefficient", "StoichiometricCoefficient", "InterstitialConcentration", "InitialThickness", "InitialPotentialDrop"],
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
							"Thickness" => create_property(parameter_meta, "Thickness"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"TabWidth" => create_property(parameter_meta, "TabWidth"),
							"TabLength" => create_property(parameter_meta, "TabLength"),
							"TabFractions" => create_property(parameter_meta, "TabFractions"),
							"TabPositionFraction" => create_property(parameter_meta, "TabPositionFraction"),
						),
						"required" => ["Density", "Thickness", "ElectronicConductivity"],
					)),
				"required" => ["Coating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
			),
			"PositiveElectrode" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Coating" => Dict(
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
							"OpenCircuitPotential" => create_property(parameter_meta, "OpenCircuitPotential"),
							"NumberOfElectronsTransfered" => create_property(parameter_meta, "NumberOfElectronsTransfered"),
							"ActivationEnergyOfReaction" => create_property(parameter_meta, "ActivationEnergyOfReaction"),
							"ActivationEnergyOfDiffusion" => create_property(parameter_meta, "ActivationEnergyOfDiffusion"),
							"ReactionRateConstant" => create_property(parameter_meta, "ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property(parameter_meta, "ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitPotential", "NumberOfElectronsTransfered", "ReactionRateConstant", "ChargeTransferCoefficient"],
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
							"Thickness" => create_property(parameter_meta, "Thickness"),
							"ElectronicConductivity" => create_property(parameter_meta, "ElectronicConductivity"),
							"TabWidth" => create_property(parameter_meta, "TabWidth"),
							"TabLength" => create_property(parameter_meta, "TabLength"),
							"TabFractions" => create_property(parameter_meta, "TabFractions"),
							"TabPositionFraction" => create_property(parameter_meta, "TabPositionFraction")),
						"required" => ["Density", "Thickness", "ElectronicConductivity"],
					)),
				"required" => ["Coating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
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
		"allOf" => [],
	)


	cell_required = schema["properties"]["Cell"]["required"]
	ne_required = schema["properties"]["NegativeElectrode"]["required"]
	pe_required = schema["properties"]["PositiveElectrode"]["required"]
	ne_coating_required = schema["properties"]["NegativeElectrode"]["properties"]["Coating"]["required"]
	pe_coating_required = schema["properties"]["PositiveElectrode"]["properties"]["Coating"]["required"]

	ne_am_required = schema["properties"]["NegativeElectrode"]["properties"]["ActiveMaterial"]["required"]
	pe_am_required = schema["properties"]["PositiveElectrode"]["properties"]["ActiveMaterial"]["required"]

	ne_ca_required = schema["properties"]["NegativeElectrode"]["properties"]["ConductiveAdditive"]["required"]
	pe_ca_required = schema["properties"]["PositiveElectrode"]["properties"]["ConductiveAdditive"]["required"]

	ne_b_required = schema["properties"]["NegativeElectrode"]["properties"]["Binder"]["required"]
	pe_b_required = schema["properties"]["PositiveElectrode"]["properties"]["Binder"]["required"]

	ne_cc_required = schema["properties"]["NegativeElectrode"]["properties"]["CurrentCollector"]["required"]
	pe_cc_required = schema["properties"]["PositiveElectrode"]["properties"]["CurrentCollector"]["required"]

	sep_required = schema["properties"]["Separator"]["required"]
	elyte_required = schema["properties"]["Electrolyte"]["required"]

	if model_settings["ModelFramework"] == "P2D"
		push!(cell_required, "ElectrodeGeometricSurfaceArea")

	elseif model_settings["ModelFramework"] == "P4D Pouch"

		push!(cell_required, "ElectrodeWidth")
		push!(cell_required, "ElectrodeLength")
		if haskey(model_settings, "CurrentCollectors")
			push!(cell_required, "NumberOfLayersInParallel")
			push!(cell_required, "DoubleCoatedElectrodes")
			push!(cell_required, "TabsOnSameSide")
			push!(cell_required, "TabWidth")
			push!(cell_required, "TabLength")

			push!(ne_required, "CurrentCollector")
			push!(pe_required, "CurrentCollector")
			push!(ne_cc_required, "TabPositionFraction")
			push!(pe_cc_required, "TabPositionFraction")


		end

	elseif model_settings["ModelFramework"] == "P4D Cylindrical"

		push!(cell_required, "InnerRadius")
		push!(cell_required, "OuterRadius")
		push!(cell_required, "Height")

		if haskey(model_settings, "CurrentCollectors")
			push!(ne_required, "CurrentCollector")
			push!(pe_required, "CurrentCollector")

			push!(ne_cc_required, "TabWidth")
			push!(pe_cc_required, "TabWidth")
			push!(ne_cc_required, "TabFractions")
			push!(pe_cc_required, "TabFractions")
		end


	end

	if haskey(model_settings, "SEIModel") && model_settings["SEIModel"] == "Bolay"
		push!(ne_required, "Interphase")
	end

	temperature_dependence = get(model_settings, "TemperatureDependence", nothing)

	if temperature_dependence == "Arrhenius"
		push!(ne_am_required, "ActivationEnergyOfReaction")
		push!(pe_am_required, "ActivationEnergyOfReaction")
		push!(ne_am_required, "ActivationEnergyOfDiffusion")
		push!(pe_am_required, "ActivationEnergyOfDiffusion")
	end

	return schema
end


function get_schema_cycling_protocol(model_settings::ModelSettings)
	# Retrieve meta-data for validation
	parameter_meta = get_cycling_protocol_meta_data()
	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"Protocol" => create_property(parameter_meta, "Protocol"),
			"InitialStateOfCharge" => create_property(parameter_meta, "InitialStateOfCharge"),
			"FunctionName" => create_property(parameter_meta, "FunctionName"),
			"TotalTime" => create_property(parameter_meta, "TotalTime"),
			"TotalNumberOfCycles" => create_property(parameter_meta, "TotalNumberOfCycles"),
			"CRate" => create_property(parameter_meta, "CRate"),
			"DRate" => create_property(parameter_meta, "DRate"),
			"LowerVoltageLimit" => create_property(parameter_meta, "LowerVoltageLimit"),
			"UpperVoltageLimit" => create_property(parameter_meta, "UpperVoltageLimit"),
			"InitialControl" => create_property(parameter_meta, "InitialControl"),
			"CurrentChangeLimit" => create_property(parameter_meta, "CurrentChangeLimit"),
			"VoltageChangeLimit" => create_property(parameter_meta, "VoltageChangeLimit"),
			"AmbientTemperature" => create_property(parameter_meta, "AmbientTemperature"),
			"InitialTemperature" => create_property(parameter_meta, "InitialTemperature"),
		),
		"required" => ["Protocol"],
		"allOf" => [
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CCCV"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"InitialControl",
						"TotalNumberOfCycles",
						"CRate",
						"DRate",
						"LowerVoltageLimit",
						"UpperVoltageLimit",
						"CurrentChangeLimit",
						"VoltageChangeLimit",
					]),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CC"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"InitialControl",
						"TotalNumberOfCycles",
					],
				),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "Function"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"FunctionName",
						"TotalTime",
					],
				),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CC"),
					"TotalNumberOfCycles" => Dict("const" => 0),
					"InitialControl" => Dict("const" => "discharging"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"DRate",
						"LowerVoltageLimit",
					]),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CC"),
					"TotalNumberOfCycles" => Dict("const" => 0),
					"InitialControl" => Dict("const" => "charging"))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"InitialControl",
						"TotalNumberOfCycles",
						"CRate",
						"UpperVoltageLimit",
					]),
			),
			Dict(
				"if" => Dict("properties" => Dict("Protocol" => Dict("const" => "CC"),
					"TotalNumberOfCycles" => Dict("not" => Dict("const" => 0)))),
				"then" => Dict(
					"required" => [
						"InitialStateOfCharge",
						"CRate",
						"DRate",
						"UpperVoltageLimit",
						"LowerVoltageLimit",
					]),
			),
		],
	)
	required = schema["required"]
	temperature_dependence = get(model_settings, "TemperatureDependence", nothing)

	if temperature_dependence == "Arrhenius"
		push!(required, "InitialTemperature")
	end

	return schema
end


function get_schema_simulation_settings(model_settings)
	meta_data_mod = get_model_settings_meta_data()
	meta_data_sim = get_simulation_settings_meta_data()
	meta_data_solv = get_solver_settings_meta_data()
	meta_data_1 = merge_dict(meta_data_mod, meta_data_sim)
	parameter_meta = merge_dict(meta_data_1, meta_data_solv)
	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"HeightGridPoints" => create_property(parameter_meta, "HeightGridPoints"),
			"AngularGridPoints" => create_property(parameter_meta, "AngularGridPoints"),
			"ElectrodeWidthGridPoints" => create_property(parameter_meta, "ElectrodeWidthGridPoints"),
			"ElectrodeLengthGridPoints" => create_property(parameter_meta, "ElectrodeLengthGridPoints"),
			"TabWidthGridPoints" => create_property(parameter_meta, "TabWidthGridPoints"),
			"TabLengthGridPoints" => create_property(parameter_meta, "TabLengthGridPoints"),
			"PositiveElectrodeCoatingGridPoints" => create_property(parameter_meta, "PositiveElectrodeCoatingGridPoints"),
			"PositiveElectrodeParticleGridPoints" => create_property(parameter_meta, "PositiveElectrodeParticleGridPoints"),
			"PositiveElectrodeCurrentCollectorGridPoints" => create_property(parameter_meta, "PositiveElectrodeCurrentCollectorGridPoints"),
			"PositiveElectrodeCurrentCollectorTabWidthGridPoints" => create_property(parameter_meta, "PositiveElectrodeCurrentCollectorTabWidthGridPoints"),
			"PositiveElectrodeCurrentCollectorTabLengthGridPoints" => create_property(parameter_meta, "PositiveElectrodeCurrentCollectorTabLengthGridPoints"),
			"NegativeElectrodeCoatingGridPoints" => create_property(parameter_meta, "NegativeElectrodeCoatingGridPoints"),
			"NegativeElectrodeParticleGridPoints" => create_property(parameter_meta, "NegativeElectrodeParticleGridPoints"),
			"NegativeElectrodeCurrentCollectorGridPoints" => create_property(parameter_meta, "NegativeElectrodeCurrentCollectorGridPoints"),
			"NegativeElectrodeCurrentCollectorTabWidth" => create_property(parameter_meta, "NegativeElectrodeCurrentCollectorTabWidthGridPoints"),
			"NegativeElectrodeCurrentCollectorTabLengthGridPoints" => create_property(parameter_meta, "NegativeElectrodeCurrentCollectorTabLengthGridPoints"),
			"SeparatorGridPoints" => create_property(parameter_meta, "SeparatorGridPoints"), "Grid" => Dict(
				"type" => "array",
			),
			"TimeStepDuration" => create_property(parameter_meta, "TimeStepDuration"),
			"RampUpTime" => create_property(parameter_meta, "RampUpTime"),
			"RampUpSteps" => create_property(parameter_meta, "RampUpSteps"),
		),
		"required" => [
			"PositiveElectrodeCoatingGridPoints",
			"PositiveElectrodeParticleGridPoints",
			"NegativeElectrodeCoatingGridPoints",
			"NegativeElectrodeParticleGridPoints",
			"SeparatorGridPoints",
			"TimeStepDuration"],
	)

	required = schema["required"]

	if model_settings["ModelFramework"] == "P4D Pouch"
		push!(required, "ElectrodeWidthGridPoints")
		push!(required, "ElectrodeLengthGridPoints")
		push!(required, "TabWidthGridPoints")
		push!(required, "TabLengthGridPoints")

		if haskey(model_settings, "CurrentCollectors")
			push!(required, "PositiveElectrodeCurrentCollectorGridPoints")
			push!(required, "PositiveElectrodeCurrentCollectorTabWidthGridPoints")
			push!(required, "PositiveElectrodeCurrentCollectorTabLengthGridPoints")
			push!(required, "NegativeElectrodeCurrentCollectorGridPoints")
			push!(required, "NegativeElectrodeCurrentCollectorTabWidthGridPoints")
			push!(required, "NegativeElectrodeCurrentCollectorTabLengthGridPoints")
		end
	end
	if haskey(model_settings, "RampUp") && model_settings["RampUp"] == "Sinusoidal"
		push!(required, "RampUpTime")
		push!(required, "RampUpSteps")
	end

	if model_settings["ModelFramework"] == "P4D Cylindrical"
		push!(required, "HeightGridPoints")
		push!(required, "AngularGridPoints")
		if haskey(model_settings, "CurrentCollectors")
			push!(required, "PositiveElectrodeCurrentCollectorGridPoints")
			push!(required, "NegativeElectrodeCurrentCollectorGridPoints")
		end

	end

	return schema
end


function get_schema_solver_settings()
	parameter_meta = get_solver_settings_meta_data()
	schema = Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"NonLinearSolver" => Dict(
				"type" => "object",
				"properties" => Dict(
					"MaxTimestepCuts" => create_property(parameter_meta, "MaxTimestepCuts"),
					"MaxTimestep" => create_property(parameter_meta, "MaxTimestep"),
					"MinTimestep" => create_property(parameter_meta, "MinTimestep"),
					"TimestepMaxIncrease" => create_property(parameter_meta, "TimestepMaxIncrease"),
					"TimestepMaxDecrease" => create_property(parameter_meta, "TimestepMaxDecrease"),
					"MaxNonLinearIterations" => create_property(parameter_meta, "MaxNonLinearIterations"),
					"MinNonLinearIterations" => create_property(parameter_meta, "MinNonLinearIterations"),
					"FailureCutsTimesteps" => create_property(parameter_meta, "FailureCutsTimesteps"),
					"CheckBeforeSolve" => create_property(parameter_meta, "CheckBeforeSolve"),
					"AlwaysUpdateSecondary" => create_property(parameter_meta, "AlwaysUpdateSecondary"),
					"ErrorOnIncomplete" => create_property(parameter_meta, "ErrorOnIncomplete"),
					"CuttingCriterion" => create_property(parameter_meta, "CuttingCriterion"),
					"Tolerances" => create_property(parameter_meta, "Tolerances"),
					"TolFactorFinalIteration" => create_property(parameter_meta, "TolFactorFinalIteration"),
					"SafeMode" => create_property(parameter_meta, "SafeMode"),
					"ExtraTiming" => create_property(parameter_meta, "ExtraTiming"),
					"TimeStepSelectors" => create_property(parameter_meta, "TimeStepSelectors"),
					"Relaxation" => create_property(parameter_meta, "Relaxation"),
				)),
			"LinearSolver" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Method" => create_property(parameter_meta, "Method"),
					"MaxSize" => create_property(parameter_meta, "MaxSize"),
					"LinearTolerance" => create_property(parameter_meta, "LinearTolerance"),
					"MaxLinearIterations" => create_property(parameter_meta, "MaxLinearIterations"),
					"Verbosity" => create_property(parameter_meta, "Verbosity"),
				),
				"required" => [],
			),
			"Verbose" => Dict(
				"type" => "object",
				"properties" => Dict(
					"InfoLevel" => create_property(parameter_meta, "InfoLevel"),
					"DebugLevel" => create_property(parameter_meta, "DebugLevel"),
					"EndReport" => create_property(parameter_meta, "EndReport"),
					"ASCIITerminal" => create_property(parameter_meta, "ASCIITerminal"),
					"ID" => create_property(parameter_meta, "ID"),
					"ProgressColor" => create_property(parameter_meta, "ProgressColor"),
					"progress_glyphs" => create_property(parameter_meta, "progress_glyphs")),
			),
			"Output" => Dict(
				"type" => "object",
				"properties" => Dict(
					"OutputStates" => create_property(parameter_meta, "OutputStates"),
					"OutputReports" => create_property(parameter_meta, "OutputReports"),
					"OutputPath" => create_property(parameter_meta, "OutputPath"),
					"InMemoryReports" => create_property(parameter_meta, "InMemoryReports"),
					"ReportLevel" => create_property(parameter_meta, "ReportLevel"),
					"OutputSubstrates" => create_property(parameter_meta, "OutputSubstrates")),
			)),
		"allOf" => [
			Dict(
				"if" => Dict(
					"properties" => Dict("LinearSolver" => Dict("properties" => Dict("Method" => Dict("const" => "Direct")))),
				),
				"then" => Dict("properties" => Dict("LinearSolver" => Dict("required" => ["MaxSize"]))
				)),
			Dict(
				"if" => Dict(
					"properties" => Dict("LinearSolver" => Dict("properties" => Dict("Method" => Dict("const" => "Iterative")))),
				),
				"then" => Dict("properties" => Dict("LinearSolver" => Dict("required" => ["Verbosity", "MaxLinearIterations", "LinearTolerance"]))
				),
			),
			Dict(
				"if" => Dict(
					"properties" => Dict("LinearSolver" => Dict("properties" => Dict("Method" => Dict("const" => "UserDefined")))),
				),
				"then" => Dict(
					"required" => Dict("LinearSolver" => Dict("required" => String[])),
				),
			),
		],
	)

	return schema
end

function get_schema_model_settings()
	parameter_meta = get_model_settings_meta_data()
	return Dict(
		"\$schema" => "http://json-schema.org/draft-07/schema#",
		"type" => "object",
		"properties" => Dict(
			"ModelFramework" => create_property(parameter_meta, "ModelFramework"),
			"CurrentCollectors" => create_property(parameter_meta, "CurrentCollectors"),
			"RampUp" => create_property(parameter_meta, "RampUp"),
			"SEIModel" => create_property(parameter_meta, "SEIModel"),
			"TransportInSolid" => create_property(parameter_meta, "TransportInSolid"),
			"ButlerVolmer" => create_property(parameter_meta, "ButlerVolmer"),
			"PotentialFlowDiscretization" => create_property(parameter_meta, "PotentialFlowDiscretization"),
			"TemperatureDependence" => create_property(parameter_meta, "TemperatureDependence"),
		),
		"required" => [
			"ModelFramework", "TransportInSolid", "PotentialFlowDiscretization", "ButlerVolmer",
		],
		"allOf" => [
			# 🚫 Disallow CurrentCollectors if ModelFramework is "1D"
			Dict(
				"if" => Dict(
					"properties" => Dict("ModelFramework" => Dict("const" => "P2D")),
					"required" => ["ModelFramework"],
				),
				"then" => Dict(
					"not" => Dict(
						"required" => ["CurrentCollectors"],
					),
				),
			),
			Dict(
				"if" => Dict(
					"properties" => Dict("ModelFramework" => Dict("const" => "P4D Cylindrical")),
					"required" => ["ModelFramework"],
				),
				"then" => Dict(
					"required" => ["CurrentCollectors"],
				),
			),
		],
	)

end


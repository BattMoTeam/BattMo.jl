export get_schema_cell_parameters

function julia_to_json_schema_type(julia_type::Type)
	if julia_type == Real
		return "number"  # JSON schema type for Real numbers (includes both integer and float)
	elseif julia_type == Int
		return "integer"  # JSON schema type for Int (integer numbers)
	elseif julia_type == Bool
		return "bool"  # JSON schema type for String
	elseif julia_type == String
		return "string"  # JSON schema type for Bool
	elseif julia_type == Function
		return "string"  # Functions aren't directly representable in JSON, treating as string (function name or identifier)
	elseif julia_type == Vector
		return "array"  # JSON schema type for arrays (Vector in Julia)
	else
		throw(ArgumentError("Unknown Julia type: $julia_type"))
	end
end

function create_property(parameter_meta, name)
	meta = get(parameter_meta, name, Dict())  # Get meta-data or empty Dict
	@info name
	# Create the dictionary
	property = Dict(
		"type" => julia_to_json_schema_type(meta["type"]),  # Enforce correct type
		"minimum" => get(meta, "min_value", nothing),  # Enforce min value if present
		"maximum" => get(meta, "max_value", nothing),  # Enforce max value if present
		"enum" => get(meta, "options", nothing),  # Enforce max value if present
		"description" => get(meta, "description", ""),  # Optional documentation
		"unit" => get(meta, "unit", ""),  # Optional unit annotation
	)

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
					"InitialStateOfCharge" => create_property(parameter_meta, "InitialStateOfCharge"),
					"InnerCellRadius" => create_property(parameter_meta, "InnerCellRadius"),
				),
				"required" => ["Case", "InitialStateOfCharge"],
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
							"Width" => create_property(parameter_meta, "Width"),
							"Length" => create_property(parameter_meta, "Length"),
							"Area" => create_property(parameter_meta, "Area"),
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
					),
					"required" => ["ElectrodeCoating", "ActiveMaterial", "Interphase", "Binder", "ConductiveAdditive"],
				),
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
							"Width" => create_property(parameter_meta, "Width"),
							"Length" => create_property(parameter_meta, "Length"),
							"Area" => create_property(parameter_meta, "Area"),
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
					),
					"required" => ["ElectrodeCoating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
				),
			),
			"Separator" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Porosity" => create_property(parameter_meta, "MaximumConcentration"),
					"Density" => create_property(parameter_meta, "MaximumConcentration"),
					"BruggemanCoefficient" => create_property(parameter_meta, "MaximumConcentration"),
					"Thickness" => create_property(parameter_meta, "MaximumConcentration"),
					"SpecificHeatCapacity" => create_property(parameter_meta, "MaximumConcentration"),
					"ThermalConductivity" => create_property(parameter_meta, "MaximumConcentration"),
				),
				"required" => ["Porosity", "Density", "BruggemanCoefficient", "Thickness"],
			),
			"Electrolyte" => Dict(
				"type" => "object",
				"properties" => Dict(
					"SpecificHeatCapacity" => create_property(parameter_meta, "MaximumConcentration"),
					"ThermalConductivity" => create_property(parameter_meta, "MaximumConcentration"),
					"Density" => create_property(parameter_meta, "MaximumConcentration"),
					"Concentration" => create_property(parameter_meta, "MaximumConcentration"),
					"IonicConductivity" => create_property(parameter_meta, "MaximumConcentration"),
					"DiffusionCoefficient" => create_property(parameter_meta, "MaximumConcentration"),
					"ChargeNumber" => Dict("type" => "integer"),
					"TransferenceNumber" => create_property(parameter_meta, "MaximumConcentration"),
				),
				"required" => ["Concentration", "Density", "DiffusionCoefficient", "IonicConductivity", "ChargeNumber", "TransferenceNumber"],
			),
		),
		"required" => ["Cell", "NegativeElectrode", "PositiveElectrode", "Separator", "Electrolyte"],
	)

	cell_required = schema["properties"]["Cell"]["required"]
	ne_coating_required = schema["properties"]["NegativeElectrode"]["properties"]["ElectrodeCoating"]["required"]
	pe_coating_required = schema["properties"]["PositiveElectrode"]["properties"]["ElectrodeCoating"]["required"]

	ne_am_required = schema["properties"]["PositiveElectrode"]["properties"]["ActiveMaterial"]["required"]
	pe_am_required = schema["properties"]["PositiveElectrode"]["properties"]["ActiveMaterial"]["required"]

	ne_ca_required = schema["properties"]["PositiveElectrode"]["properties"]["ConductiveAdditive"]["required"]
	pe_ca_required = schema["properties"]["PositiveElectrode"]["properties"]["ConductiveAdditive"]["required"]

	ne_b_required = schema["properties"]["PositiveElectrode"]["properties"]["Binder"]["required"]
	pe_b_required = schema["properties"]["PositiveElectrode"]["properties"]["Binder"]["required"]

	sep_required = schema["properties"]["Separator"]["required"]
	elyte_required = schema["properties"]["Electrolyte"]["required"]

	model_settings_dict = model_settings.dict

	if model_settings_dict["ModelGeometry"] == "1D"
		push!(ne_coating_required, "Area")
		push!(pe_coating_required, "Area")
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

	elseif model_settings_dict["ModelGeometry"] == "3D Pouch"
		push!(ne_coating_required, "Width")
		push!(ne_coating_required, "Length")
		push!(pe_coating_required, "Width")
		push!(pe_coating_required, "Length")
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

	end

	return schema
end

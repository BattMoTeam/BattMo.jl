export get_schema_cell_parameters

function create_property(name)
	meta = get(parameter_meta, name, Dict())  # Get meta-data or empty Dict
	return Dict(
		"type" => string(meta["type"]),  # Enforce correct type
		"minimum" => get(meta, "min_value", nothing),  # Enforce min value if present
		"maximum" => get(meta, "max_value", nothing),  # Enforce max value if present
		"description" => get(meta, "description", ""),  # Optional documentation
		"unit" => get(meta, "unit", ""),  # Optional unit annotation
	) |> filter!(x -> x.second !== nothing)  # Remove missing values
end

function get_schema_cell_parameters(model_settings)
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
					"Case" => create_property("Case"),
					"DeviceSurfaceArea" => create_property("DeviceSurfaceArea"),
					"DubbelCoatedElectrodes" => create_property("DubbelCoatedElectrodes"),
					"NominalVoltage" => create_property("NominalVoltage"),
					"NominalCapacity" => create_property("NominalCapacity"),
					"HeatTransferCoefficient" => create_property("HeatTransferCoefficient"),
					"InitialStateOfCharge" => create_property("InitialStateOfCharge"),
					"InnerCellRadius" => create_property("InnerCellRadius"),
				),
				"required" => ["Case", "InitialStateOfCharge"],
			),
			"NegativeElectrode" => Dict(
				"type" => "object",
				"properties" => Dict(
					"ElectrodeCoating" => Dict(
						"type" => "object",
						"properties" => Dict(
							"BruggemanCoefficient" => create_property("BruggemanCoefficient"),
							"EffectiveDensity" => create_property("EffectiveDensity"),
							"Thickness" => create_property("Thickness"),
							"Width" => create_property("Width"),
							"Length" => create_property("Length"),
							"Area" => create_property("Area"),
							"SurfaceCoefficientOfHeatTransfer" => create_property("SurfaceCoefficientOfHeatTransfer"),
						),
						"required" => ["BruggemanCoefficient", "EffectiveDensity", "Thickness"],
					),
					"ActiveMaterial" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MassFraction" => create_property("MassFraction"),
							"Density" => create_property("Density"),
							"VolumetricSurfaceArea" => create_property("VolumetricSurfaceArea"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
							"DiffusionCoefficient" => create_property("DiffusionCoefficient"),
							"ParticleRadius" => create_property("ParticleRadius"),
							"MaximumConcentration" => create_property("MaximumConcentration"),
							"StoichiometricCoefficientAtSOC0" => create_property("StoichiometricCoefficientAtSOC0"),
							"StoichiometricCoefficientAtSOC100" => create_property("StoichiometricCoefficientAtSOC100"),
							"OpenCircuitVoltage" => create_property("OpenCircuitVoltage"),
							"NumberOfElectronsTransferred" => create_property("NumberOfElectronsTransferred"),
							"ActivationEnergyOfReaction" => create_property("ActivationEnergyOfReaction"),
							"ReactionRateConstant" => create_property("ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property("ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitVoltage", "NumberOfElectronsTransferred", "ActivationEnergyOfReaction", "ReactionRateConstant", "ChargeTransferCoefficient"],
					),
					"Interphase" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MolarVolume" => create_property("MolarVolume"),
							"IonicConductivity" => create_property("IonicConductivity"),
							"ElectronicDiffusionCoefficient" => create_property("ElectronicDiffusionCoefficient"),
							"StoichiometricCoefficient" => create_property("StoichiometricCoefficient"),
							"IntersticialConcentration" => create_property("IntersticialConcentration"),
							"InitialThickness" => create_property("InitialThickness"),
						),
						"required" => ["MolarVolume", "IonicConductivity", "ElectronicDiffusionCoefficient", "StoichiometricCoefficient", "IntersticialConcentration", "InitialThickness"],
					),
					"ConductiveAdditive" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"Binder" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"CurrentCollector" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
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
							"BruggemanCoefficient" => create_property("BruggemanCoefficient"),
							"EffectiveDensity" => create_property("EffectiveDensity"),
							"Thickness" => create_property("Thickness"),
							"Width" => create_property("Width"),
							"Length" => create_property("Length"),
							"Area" => create_property("Area"),
							"SurfaceCoefficientOfHeatTransfer" => create_property("SurfaceCoefficientOfHeatTransfer"),
						),
						"required" => ["BruggemanCoefficient", "EffectiveDensity", "Thickness"],
					),
					"ActiveMaterial" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MassFraction" => create_property("MassFraction"),
							"Density" => create_property("Density"),
							"VolumetricSurfaceArea" => create_property("VolumetricSurfaceArea"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
							"DiffusionCoefficient" => create_property("DiffusionCoefficient"),
							"ParticleRadius" => create_property("ParticleRadius"),
							"MaximumConcentration" => create_property("MaximumConcentration"),
							"StoichiometricCoefficientAtSOC0" => create_property("StoichiometricCoefficientAtSOC0"),
							"StoichiometricCoefficientAtSOC100" => create_property("StoichiometricCoefficientAtSOC100"),
							"OpenCircuitVoltage" => create_property("OpenCircuitVoltage"),
							"NumberOfElectronsTransferred" => create_property("NumberOfElectronsTransferred"),
							"ActivationEnergyOfReaction" => create_property("ActivationEnergyOfReaction"),
							"ReactionRateConstant" => create_property("ReactionRateConstant"),
							"ChargeTransferCoefficient" => create_property("ChargeTransferCoefficient"),
						),
						"required" => ["MassFraction", "Density", "VolumetricSurfaceArea", "ElectronicConductivity", "DiffusionCoefficient",
							"ParticleRadius", "MaximumConcentration", "StoichiometricCoefficientAtSOC0", "StoichiometricCoefficientAtSOC100",
							"OpenCircuitVoltage", "NumberOfElectronsTransferred", "ActivationEnergyOfReaction", "ReactionRateConstant", "ChargeTransferCoefficient"],
					),
					"Interphase" => Dict(
						"type" => "object",
						"properties" => Dict(
							"MolarVolume" => create_property("MolarVolume"),
							"IonicConductivity" => create_property("IonicConductivity"),
							"ElectronicDiffusionCoefficient" => create_property("ElectronicDiffusionCoefficient"),
							"StoichiometricCoefficient" => create_property("StoichiometricCoefficient"),
							"IntersticialConcentration" => create_property("IntersticialConcentration"),
							"InitialThickness" => create_property("InitialThickness"),
						),
						"required" => ["MolarVolume", "IonicConductivity", "ElectronicDiffusionCoefficient", "StoichiometricCoefficient", "IntersticialConcentration", "InitialThickness"],
					),
					"ConductiveAdditive" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"Binder" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
							"SpecificHeatCapacity" => create_property("SpecificHeatCapacity"),
							"ThermalConductivity" => create_property("ThermalConductivity"),
						),
						"required" => ["Density", "MassFraction", "ElectronicConductivity"],
					),
					"CurrentCollector" => Dict(
						"type" => "object",
						"properties" => Dict(
							"Density" => create_property("Density"),
							"MassFraction" => create_property("MassFraction"),
							"ElectronicConductivity" => create_property("ElectronicConductivity"),
						),
						"required" => ["Density", "Thickness", "ElectronicConductivity"],
					),
					"required" => ["ElectrodeCoating", "ActiveMaterial", "Binder", "ConductiveAdditive"],
				),
			),
			"Separator" => Dict(
				"type" => "object",
				"properties" => Dict(
					"Porosity" => create_property("MaximumConcentration"),
					"Density" => create_property("MaximumConcentration"),
					"BruggemanCoefficient" => create_property("MaximumConcentration"),
					"Thickness" => create_property("MaximumConcentration"),
					"SpecificHeatCapacity" => create_property("MaximumConcentration"),
					"ThermalConductivity" => create_property("MaximumConcentration"),
				),
				"required" => ["Porosity", "Density", "BruggemanCoefficient", "Thickness"],
			),
			"Electrolyte" => Dict(
				"type" => "object",
				"properties" => Dict(
					"SpecificHeatCapacity" => create_property("MaximumConcentration"),
					"ThermalConductivity" => create_property("MaximumConcentration"),
					"Density" => create_property("MaximumConcentration"),
					"Concentration" => create_property("MaximumConcentration"),
					"IonicConductivity" => create_property("MaximumConcentration"),
					"DiffusionCoefficient" => create_property("MaximumConcentration"),
					"ChargeNumber" => Dict("type" => "integer"),
					"TransferenceNumber" => create_property("MaximumConcentration"),
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

	if model_settings["ModelGeometry"] == "1D"
		push!(ne_coating_required, "Area")
		push!(pe_coating_required, "Area")
		if model_settings["UseThermalModel"]
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

	elseif model_settings["ModelGeometry"] == "3D Pouch"
		push!(ne_coating_required, "Width")
		push!(ne_coating_required, "Length")
		push!(pe_coating_required, "Width")
		push!(pe_coating_required, "Length")
		if model_settings["UseThermalModel"]
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

	elseif model_settings["ModelGeometry"] == "3D Cyclindrical"

		push!(cell_required, "DubbelCoatedElectrodes")
		push!(cell_required, "InnerCellRadius")

		push!(ne_coating_required, "Width")
		push!(ne_coating_required, "Length")
		push!(pe_coating_required, "Width")
		push!(pe_coating_required, "Length")

		if model_settings["UseThermalModel"]
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

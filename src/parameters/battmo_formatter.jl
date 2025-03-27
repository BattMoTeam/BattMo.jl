
export format_battmo_input
export BattMoInput

abstract type BattMoParameters end

struct BattMoInput <: BattMoParameters
	Dict::Dict{String, Any}

end

function setup_battmo_input(model::LithiumIon, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings)


	model_settings_dict = model.model_settings.dict
	cell_parameters_dict = cell_parameters.dict
	cycling_protocol_dict = cycling_protocol.dict

	battmo_dict = format_battmo_dict(model_settings_dict, cell_parameters_dict, cycling_protocol_dict, simulation_settings_dict)

	return battmo_dict

end

function get_key_value(dict::Dict, key)
	return get(dict, key, nothing)
end

function format_battmo_dict(model_settings_dict, cell_parameters_dict, cycling_protocol, simulation_settings)

	cell = cell_parameters_dict["Cell"]
	ne = cell_parameters_dict["NegativeElectrode"]
	ne_coating = ne["ElectrodeCoating"]
	ne_am = ne["ActiveMaterial"]
	ne_interphase = ne["Interphase"]
	ne_b = ne["Binder"]
	ne_cc = ne["CurrentCollector"]
	ne_ca = ne["ConductingAdditive"]

	elyte = cell_parameters_dict["Electrolyte"]
	sep = cell_parameters_dict["Separator"]

	grid_points = simulation_settings["GridPoints"]

	cell_width = minimum([
		cell_parameters_dict["NegativeElectrode"]["ElectrodeCoating"]["Width"],
		cell_parameters_dict["PositiveElectrode"]["ElectrodeCoating"]["Width"],
	])

	cell_length = minimum([
		cell_parameters_dict["NegativeElectrode"]["ElectrodeCoating"]["Length"],
		cell_parameters_dict["PositiveElectrode"]["ElectrodeCoating"]["Length"],
	])


	battmo_input = Dict(
		"G" => [],
		"SOC" => get_key_value(cell, "InitialStateOfCharge"),
		"initT" => 298.15,
		"use_thermal" => get_key_value(model_settings_dict, "UseThermalModel"),
		"include_current_collectors" => get_key_value(model_settings_dict, "UseCurrentCollectors"),
		"Control" => Dict(
			"controlPolicy" => get_key_value(cycling_protocol, "Protocol"),
			"rampupsteps" => get_key_value(simulation_settings, "RampUpSteps"),
			"CRate" => get_key_value(cycling_protocol, "CRate"),
			"DRate" => get_key_value(cycling_protocol, "DRate"),
			"lowerCutoffVoltage" => get_key_value(cycling_protocol, "LowerVoltageLimit"),
			"upperCutoffVoltage" => get_key_value(cycling_protocol, "UpperVoltageLimit"),
			"dIdtLimit" => get_key_value(cycling_protocol, "CurrentChangeLimit"),
			"dEdtLimit" => get_key_value(cycling_protocol, "VoltageChangeLimit"),
		),
		"NegativeElectrode" => Dict(
			"use_normed_current_collector" => false,
			"Coating" => Dict(
				"effectiveDensity" => get_key_value(ne_coating, "EffectiveDensity"),
				"bruggemanCoefficient" => get_key_value(ne_coating, "BruggemanCoefficient"),
				"ActiveMaterial" => Dict(
					"massFraction" => get_key_value(ne_am, "MassFraction"),
					"density" => get_key_value(ne_am, "Density"),
					"specificHeatCapacity" => get_key_value(ne_am, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_am, "ThermalConductivity"),
					"electronicConductivity" => get_key_value(ne_am, "ElectrodeConductivity"),
					"Interface" => Dict(
						"saturationConcentration" => get_key_value(ne_am, "MaximumConcentration"),
						"volumetricSurfaceArea" => get_key_value(ne_am, "VolumetricSurfaceArea"),
						"numberOfElectronsTransferred" => get_key_value(ne_am, "NumberOfElectronsTransferred"),
						"activationEnergyOfReaction" => get_key_value(ne_am, "ActivationEnergyOfReaction"),
						"reactionRateConstant" => get_key_value(ne_am, "ReactionRateConstant"),
						"guestStoichiometry100" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC100"),
						"guestStoichiometry0" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC0"),
						"chargeTransferCoefficient" => get_key_value(ne_am, "ChargeTransferCoefficient"),
						"openCircuitPotential" => get_key_value(ne_am, "OpenCircuitVoltage"),
					),
					"diffusionModelType" => "full",
					"SolidDiffusion" => Dict(
						"activationEnergyOfDiffusion" => get_key_value(ne_am, "ActivationEnergyOfDiffusion"),
						"referenceDiffusionCoefficient" => get_key_value(ne_interphase, "ElectronicDiffusionCoefficient"),
						"particleRadius" => get_key_value(ne_am, "ParticleRadius"),
						"N" => get_key_value(grid_points, "NegativeElectrodeActiveMaterial"),
					),
				),
				"Binder" => Dict(
					"density" => get_key_value(ne_b, "Density"),
					"massFraction" => get_key_value(ne_b, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_b, "ElectricConductivity"),
					"specificHeatCapacity" => get_key_value(ne_b, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_b, "ThermalConductivity"),
				),
				"ConductingAdditive" => Dict(
					"density" => get_key_value(ne_ca, "Density"),
					"massFraction" => get_key_value(ne_ca, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_ca, "ElectricConductivity"),
					"specificHeatCapacity" => get_key_value(ne_ca, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_ca, "ThermalConductivity"),
				),
				"thickness" => get_key_value(ne_coating, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrode"),
			),
			"CurrentCollector" => Dict(
				"electronicConductivity" => get_key_value(ne_cc, "ElectricConductivity"),
				"thermalConductivity" => get_key_value(ne_cc, "ThermalConductivity"),
				"specificHeatCapacity" => get_key_value(ne_cc, "SpecificHeatCapacity"),
				"density" => get_key_value(ne_cc, "Density"),
				"thickness" => get_key_value(ne_cc, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrodeCurrentCollector"),
				"tab" => Dict(
					"width" => get_key_value(ne_cc_tab, "Width"),
					"height" => get_key_value(ne_cc_tab, "Length"),
					"Nw" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabWidth"),
					"Nh" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabLength"),
				),
			),
		),
		"PositiveElectrode" => Dict(
			"use_normed_current_collector" => false,
			"Coating" => Dict(
				"effectiveDensity" => get_key_value(ne_coating, "EffectiveDensity"),
				"bruggemanCoefficient" => get_key_value(ne_coating, "BruggemanCoefficient"),
				"ActiveMaterial" => Dict(
					"massFraction" => get_key_value(ne_am, "MassFraction"),
					"density" => get_key_value(ne_am, "Density"),
					"specificHeatCapacity" => get_key_value(ne_am, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_am, "ThermalConductivity"),
					"electronicConductivity" => get_key_value(ne_am, "ElectrodeConductivity"),
					"Interface" => Dict(
						"saturationConcentration" => get_key_value(ne_am, "MaximumConcentration"),
						"volumetricSurfaceArea" => get_key_value(ne_am, "VolumetricSurfaceArea"),
						"numberOfElectronsTransferred" => get_key_value(ne_am, "NumberOfElectronsTransferred"),
						"activationEnergyOfReaction" => get_key_value(ne_am, "ActivationEnergyOfReaction"),
						"reactionRateConstant" => get_key_value(ne_am, "ReactionRateConstant"),
						"guestStoichiometry100" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC100"),
						"guestStoichiometry0" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC0"),
						"chargeTransferCoefficient" => get_key_value(ne_am, "ChargeTransferCoefficient"),
						"openCircuitPotential" => get_key_value(ne_am, "OpenCircuitVoltage"),
					), "diffusionModelType" => "full",
					"SolidDiffusion" => Dict(
						"activationEnergyOfDiffusion" => get_key_value(ne_am, "ActivationEnergyOfDiffusion"),
						"referenceDiffusionCoefficient" => get_key_value(ne_interphase, "ElectronicDiffusionCoefficient"),
						"particleRadius" => get_key_value(ne_am, "ParticleRadius"),
						"N" => get_key_value(grid_points, "NegativeElectrodeActiveMaterial"),
					),
				),
				"Binder" => Dict(
					"density" => get_key_value(ne_b, "Density"),
					"massFraction" => get_key_value(ne_b, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_b, "ElectricConductivity"),
					"specificHeatCapacity" => get_key_value(ne_b, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_b, "ThermalConductivity"),
				),
				"ConductingAdditive" => Dict(
					"density" => get_key_value(ne_ca, "Density"),
					"massFraction" => get_key_value(ne_ca, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_ca, "ElectricConductivity"),
					"specificHeatCapacity" => get_key_value(ne_ca, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_ca, "ThermalConductivity"),
				),
				"thickness" => get_key_value(ne_coating, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrode"),
			),
			"CurrentCollector" => Dict(
				"electronicConductivity" => get_key_value(ne_cc, "ElectricConductivity"),
				"thermalConductivity" => get_key_value(ne_cc, "ThermalConductivity"),
				"specificHeatCapacity" => get_key_value(ne_cc, "SpecificHeatCapacity"),
				"density" => get_key_value(ne_cc, "Density"),
				"thickness" => get_key_value(ne_cc, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrodeCurrentCollector"),
				"tab" => Dict(
					"width" => get_key_value(ne_cc_tab, "Width"),
					"height" => get_key_value(ne_cc_tab, "Length"),
					"Nw" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabWidth"),
					"Nh" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabLength"),
				),
			),
		),
		"Electrolyte" => Dict(
			"specificHeatCapacity" => get_key_value(elyte, "SpecificHeatCapacity"),
			"thermalConductivity" => get_key_value(elyte, "ThermalConductivity"),
			"density" => get_key_value(elyte, "Density"),
			"initialConcentration" => get_key_value(elyte, "Concentration"),
			# "nominalEthyleneCarbonateConcentration" => 999.99999999999977,
			"ionicConductivity" => get_key_value(elyte, "IonicConductivity"),
			"diffusionCoefficient" => get_key_value(elyte, "DiffusionCoefficient"),
			"species" => Dict(
				"chargeNumber" => get_key_value(elyte, "ChargeNumber"),
				"transferenceNumber" => get_key_value(elyte, "TransferenceNumber"),
				"nominalConcentration" => get_key_value(elyte, "Concentration"),
			),
			"bruggemanCoefficient" => get_key_value(sep, "BruggemanCoefficient"),
		),
		"Separator" => Dict(
			"porosity" => get_key_value(sep, "Porosity"),
			"specificHeatCapacity" => get_key_value(sep, "SpecificHeatCapacity"),
			"thermalConductivity" => get_key_value(sep, "ThermalConductivity"),
			"density" => get_key_value(sep, "Density"),
			"bruggemanCoefficient" => get_key_value(sep, "BruggemanCoefficient"),
			"thickness" => get_key_value(sep, "Thickness"),
			"N" => get_key_value(grid_points, "Separator"),
		),
		"ThermalModel" => Dict(
			"externalHeatTransferCoefficient" => get_key_value(cell, "HeatTransferCoefficient"),
			"externalTemperature" => get_key_value(cycling_protocol, "AmbientKelvinTemperature"),
			"externalHeatTransferCoefficientTab" => get_key_value(cell, "HeatTransferCoefficient"),
		),
		"Geometry" => Dict(
			"case" => get_key_value(model_settings_dict, "ModelGeometry"),
			"width" => cell_width,
			"height" => cell_length,
			"Nw" => get_key_value(grid_points, "ElectrodeWidth"),
			"Nh" => get_key_value(grid_points, "ElectrodeLength"),
		),
	)
	return battmo_input

end


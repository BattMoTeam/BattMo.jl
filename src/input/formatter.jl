export convert_parameter_sets_to_battmo_input


function get_key_value(dict::Union{AbstractInput, Dict, Nothing}, key)
	if isnothing(dict)
		value = nothing
	else
		value = get(dict, key, nothing)
	end
	return value
end

function convert_parameter_sets_to_battmo_input(model_settings::ModelSettings, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings)

	cell = get_key_value(cell_parameters, "Cell")
	ne = get_key_value(cell_parameters, "NegativeElectrode")
	ne_coating = get_key_value(ne, "ElectrodeCoating")
	ne_am = get_key_value(ne, "ActiveMaterial")
	ne_interphase = get_key_value(ne, "Interphase")
	ne_b = get_key_value(ne, "Binder")
	ne_cc = get_key_value(ne, "CurrentCollector")
	ne_cc_tab = get_key_value(ne, "CurrentCollectorTab")
	ne_ca = get_key_value(ne, "ConductiveAdditive")

	pe = get_key_value(cell_parameters, "PositiveElectrode")
	pe_coating = get_key_value(pe, "ElectrodeCoating")
	pe_am = get_key_value(pe, "ActiveMaterial")
	pe_b = get_key_value(pe, "Binder")
	pe_cc = get_key_value(pe, "CurrentCollector")
	pe_cc_tab = get_key_value(pe, "CurrentCollectorTab")
	pe_ca = get_key_value(pe, "ConductiveAdditive")

	elyte = get_key_value(cell_parameters, "Electrolyte")
	sep = get_key_value(cell_parameters, "Separator")

	grid_points = get_key_value(simulation_settings, "GridPoints")


	##################
	# Model settings

	if isnothing(get_key_value(model_settings, "UseThermalModel"))
		use_thermal = false
	else
		use_thermal = true
	end

	if isnothing(get_key_value(model_settings, "UseCurrentCollectors"))
		use_cc = false
	else
		use_cc = true
	end

	if isnothing(get_key_value(model_settings, "UseRampUp"))
		use_ramp_up = false
	else
		use_ramp_up = true
	end


	battmo_input = Dict(
		"G" => get_key_value(simulation_settings, "Grid"),
		"SOC" => get_key_value(cycling_protocol, "InitialStateOfCharge"),
		"initT" => get_key_value(cycling_protocol, "InitialKelvinTemperature"),
		"use_thermal" => use_thermal,
		"include_current_collectors" => use_cc,
		"Control" => Dict(
			"controlPolicy" => get_key_value(cycling_protocol, "Protocol"),
			"numberOfCycles" => get_key_value(cycling_protocol, "TotalNumberOfCycles"),
			"rampupTime" => get_key_value(simulation_settings, "RampUpTime"),
			"CRate" => get_key_value(cycling_protocol, "CRate"),
			"DRate" => get_key_value(cycling_protocol, "DRate"),
			"initialControl" => get_key_value(cycling_protocol, "InitialControl"),
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
					"electronicConductivity" => get_key_value(ne_am, "ElectronicConductivity"),
					"SEImodel" => get_key_value(model_settings, "UseSEIModel"),
					"Interface" => Dict(
						"saturationConcentration" => get_key_value(ne_am, "MaximumConcentration"),
						"volumetricSurfaceArea" => get_key_value(ne_am, "VolumetricSurfaceArea"),
						"numberOfElectronsTransferred" => get_key_value(ne_am, "NumberOfElectronsTransfered"),
						"activationEnergyOfReaction" => get_key_value(ne_am, "ActivationEnergyOfReaction"),
						"reactionRateConstant" => get_key_value(ne_am, "ReactionRateConstant"),
						"guestStoichiometry100" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC100"),
						"guestStoichiometry0" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC0"),
						"chargeTransferCoefficient" => get_key_value(ne_am, "ChargeTransferCoefficient"),
						"openCircuitPotential" => get_key_value(ne_am, "OpenCircuitVoltage"),
						"SEImolarVolume" => get_key_value(ne_interphase, "MolarVolume"),
						"SEIionicConductivity" => get_key_value(ne_interphase, "IonicConductivity"),
						"SEIelectronicDiffusionCoefficient" => get_key_value(ne_interphase, "ElectronicDiffusionCoefficient"),
						"SEIstoichiometricCoefficient" => get_key_value(ne_interphase, "StoichiometricCoefficient"),
						"SEIintersticialConcentration" => get_key_value(ne_interphase, "IntersticialConcentration"),
						"SEIlengthInitial" => get_key_value(ne_interphase, "InitialThickness"),
						"SEIvoltageDropRef" => get_key_value(ne_interphase, "InitialPotentialDrop"),
						"SEIlengthRef" => get_key_value(ne_interphase, "InitialThickness"),
						"density" => get_key_value(ne_am, "Density"),
					),
					"diffusionModelType" => get_key_value(model_settings, "UseDiffusionModel"),
					"SolidDiffusion" => Dict(
						"activationEnergyOfDiffusion" => get_key_value(ne_am, "ActivationEnergyOfDiffusion"),
						"referenceDiffusionCoefficient" => get_key_value(ne_am, "DiffusionCoefficient"),
						"particleRadius" => get_key_value(ne_am, "ParticleRadius"),
						"N" => get_key_value(grid_points, "NegativeElectrodeActiveMaterial"),
					),
				),
				"Binder" => Dict(
					"density" => get_key_value(ne_b, "Density"),
					"massFraction" => get_key_value(ne_b, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_b, "ElectronicConductivity"),
					"specificHeatCapacity" => get_key_value(ne_b, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_b, "ThermalConductivity"),
				),
				"ConductingAdditive" => Dict(
					"density" => get_key_value(ne_ca, "Density"),
					"massFraction" => get_key_value(ne_ca, "MassFraction"),
					"electronicConductivity" => get_key_value(ne_ca, "ElectronicConductivity"),
					"specificHeatCapacity" => get_key_value(ne_ca, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(ne_ca, "ThermalConductivity"),
				),
				"thickness" => get_key_value(ne_coating, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrodeCoating"),
			),
			"CurrentCollector" => Dict(
				"electronicConductivity" => get_key_value(ne_cc, "ElectronicConductivity"),
				"thermalConductivity" => get_key_value(ne_cc, "ThermalConductivity"),
				"specificHeatCapacity" => get_key_value(ne_cc, "SpecificHeatCapacity"),
				"density" => get_key_value(ne_cc, "Density"),
				"thickness" => get_key_value(ne_cc, "Thickness"),
				"N" => get_key_value(grid_points, "NegativeElectrodeCurrentCollector"),
				"tab" => Dict(
					"width" => get_key_value(ne_cc, "TabWidth"),
					"height" => get_key_value(ne_cc, "TabLength"),
					"Nw" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabWidth"),
					"Nh" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabLength"),
				),
			),
		),
		"PositiveElectrode" => Dict(
			"use_normed_current_collector" => false,
			"Coating" => Dict(
				"effectiveDensity" => get_key_value(pe_coating, "EffectiveDensity"),
				"bruggemanCoefficient" => get_key_value(pe_coating, "BruggemanCoefficient"),
				"ActiveMaterial" => Dict(
					"massFraction" => get_key_value(pe_am, "MassFraction"),
					"density" => get_key_value(pe_am, "Density"),
					"specificHeatCapacity" => get_key_value(pe_am, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(pe_am, "ThermalConductivity"),
					"electronicConductivity" => get_key_value(pe_am, "ElectronicConductivity"),
					"Interface" => Dict(
						"saturationConcentration" => get_key_value(pe_am, "MaximumConcentration"),
						"volumetricSurfaceArea" => get_key_value(pe_am, "VolumetricSurfaceArea"),
						"numberOfElectronsTransferred" => get_key_value(pe_am, "NumberOfElectronsTransfered"),
						"activationEnergyOfReaction" => get_key_value(pe_am, "ActivationEnergyOfReaction"),
						"reactionRateConstant" => get_key_value(pe_am, "ReactionRateConstant"),
						"guestStoichiometry100" => get_key_value(pe_am, "StoichiometricCoefficientAtSOC100"),
						"guestStoichiometry0" => get_key_value(pe_am, "StoichiometricCoefficientAtSOC0"),
						"chargeTransferCoefficient" => get_key_value(pe_am, "ChargeTransferCoefficient"),
						"openCircuitPotential" => get_key_value(pe_am, "OpenCircuitVoltage"),
					), "diffusionModelType" => "full",
					"SolidDiffusion" => Dict(
						"activationEnergyOfDiffusion" => get_key_value(pe_am, "ActivationEnergyOfDiffusion"),
						"referenceDiffusionCoefficient" => get_key_value(pe_am, "DiffusionCoefficient"),
						"particleRadius" => get_key_value(pe_am, "ParticleRadius"),
						"N" => get_key_value(grid_points, "PositiveElectrodeActiveMaterial"),
					),
				),
				"Binder" => Dict(
					"density" => get_key_value(pe_b, "Density"),
					"massFraction" => get_key_value(pe_b, "MassFraction"),
					"electronicConductivity" => get_key_value(pe_b, "ElectronicConductivity"),
					"specificHeatCapacity" => get_key_value(pe_b, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(pe_b, "ThermalConductivity"),
				),
				"ConductingAdditive" => Dict(
					"density" => get_key_value(pe_ca, "Density"),
					"massFraction" => get_key_value(pe_ca, "MassFraction"),
					"electronicConductivity" => get_key_value(pe_ca, "ElectronicConductivity"),
					"specificHeatCapacity" => get_key_value(pe_ca, "SpecificHeatCapacity"),
					"thermalConductivity" => get_key_value(pe_ca, "ThermalConductivity"),
				),
				"thickness" => get_key_value(pe_coating, "Thickness"),
				"N" => get_key_value(grid_points, "PositiveElectrodeCoating"),
			),
			"CurrentCollector" => Dict(
				"electronicConductivity" => get_key_value(pe_cc, "ElectronicConductivity"),
				"thermalConductivity" => get_key_value(pe_cc, "ThermalConductivity"),
				"specificHeatCapacity" => get_key_value(pe_cc, "SpecificHeatCapacity"),
				"density" => get_key_value(pe_cc, "Density"),
				"thickness" => get_key_value(pe_cc, "Thickness"),
				"N" => get_key_value(grid_points, "PositiveElectrodeCurrentCollector"),
				"tab" => Dict(
					"width" => get_key_value(pe_cc, "TabWidth"),
					"height" => get_key_value(pe_cc, "TabLength"),
					"Nw" => get_key_value(grid_points, "PositiveElectrodeCurrentCollectorTabWidth"),
					"Nh" => get_key_value(grid_points, "PositiveElectrodeCurrentCollectorTabLength"),
				),
			),
		),
		"Electrolyte" => Dict(
			"specificHeatCapacity" => get_key_value(elyte, "SpecificHeatCapacity"),
			"thermalConductivity" => get_key_value(elyte, "ThermalConductivity"),
			"density" => get_key_value(elyte, "Density"),
			"initialConcentration" => get_key_value(elyte, "Concentration"),
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
			"case" => get_key_value(model_settings, "ModelGeometry"),
			"faceArea" => get_key_value(cell, "ElectrodeGeometricSurfaceArea"),
			"width" => get_key_value(cell, "ElectrodeWidth"),
			"height" => get_key_value(cell, "ElectrodeLength"),
			"Nw" => get_key_value(grid_points, "ElectrodeWidth"),
			"Nh" => get_key_value(grid_points, "ElectrodeLength"),
		),
		"TimeStepping" => Dict(
			"useRampup" => use_ramp_up,
			"numberOfRampupSteps" => get_key_value(simulation_settings, "RampUpSteps"),
			"timeStepDuration" => get_key_value(simulation_settings, "TimeStepDuration"),
		),
	)
	return InputParams(battmo_input)

end

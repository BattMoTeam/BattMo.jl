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

	grid_points = get_key_value(simulation_settings, "GridResolution")


	##################
	# Model settings

	diff_type = "full"

	if isnothing(get_key_value(model_settings, "ModelFramework"))
		geom_case = nothing
	else
		geom = get_key_value(model_settings, "ModelFramework")
		if geom == "P2D"
			geom_case = "1D"

		elseif geom == "P4D Pouch"
			geom_case = "3D-demo"

		end
	end

	if isnothing(get_key_value(model_settings, "ThermalModel"))
		use_thermal = false
	else
		use_thermal = true
	end

	if isnothing(get_key_value(model_settings, "CurrentCollectors"))
		use_cc = false
	else
		use_cc = true
	end

	if isnothing(get_key_value(model_settings, "RampUp"))
		use_ramp_up = false
	else
		use_ramp_up = true
	end

	ne_ocp_value = get_key_value(ne_am, "OpenCircuitPotential")
	if isa(ne_ocp_value, AbstractDict)
		if haskey(ne_ocp_value, "FunctionName")
			ne_ocp = Dict(
				"type" => "function",
				"functionname" => ne_ocp_value["FunctionName"],
				"functionpath" => isnothing(get_key_value(ne_ocp_value, "FilePath")) ? nothing : normpath(joinpath(dirname(cell_parameters.source_path), get_key_value(ne_ocp_value, "FilePath"))),
			)
		else
			ne_ocp = Dict(
				"type" => "function",
				"data_x" => ne_ocp_value["x"],
				"data_y" => ne_ocp_value["y"],
				"argumentlist" => [
					"theta",
				],
			)
		end
	elseif isa(ne_ocp_value, String)
		ne_ocp = Dict(
			"type" => "function",
			"function" => ne_ocp_value,
		)
	else
		error("Function type not recognized")
	end

	pe_ocp_value = get_key_value(pe_am, "OpenCircuitPotential")
	if isa(pe_ocp_value, AbstractDict)
		if haskey(pe_ocp_value, "FunctionName")
			pe_ocp = Dict(
				"type" => "function",
				"functionname" => pe_ocp_value["FunctionName"],
				"functionpath" => isnothing(get_key_value(pe_ocp_value, "FilePath")) ? nothing : normpath(joinpath(dirname(cell_parameters.source_path), get_key_value(pe_ocp_value, "FilePath"))),
			)
		else
			pe_ocp = Dict(
				"type" => "function",
				"data_x" => pe_ocp_value["x"],
				"data_y" => pe_ocp_value["y"],
				"argumentlist" => [
					"theta",
				],
			)
		end
	elseif isa(pe_ocp_value, String)
		pe_ocp = Dict(
			"type" => "function",
			"function" => pe_ocp_value,
		)
	else
		error("Function type not recognized")
	end

	diff_value = get_key_value(elyte, "DiffusionCoefficient")
	if isa(diff_value, AbstractDict)
		if haskey(diff_value, "FunctionName")
			diff = Dict(
				"type" => "function",
				"functionname" => diff_value["FunctionName"],
				"functionpath" => isnothing(get_key_value(diff_value, "FilePath")) ? nothing : normpath(joinpath(dirname(cell_parameters.source_path), get_key_value(diff_value, "FilePath"))),
			)
		else
			diff = Dict(
				"type" => "function",
				"data_x" => diff_value["x"],
				"data_y" => diff_value["y"],
				"argumentlist" => [
					"theta",
				],
			)
		end
	elseif isa(diff_value, String)
		diff = Dict(
			"type" => "function",
			"function" => diff_value,
		)
	else
		error("Function type not recognized")
	end

	cond_value = get_key_value(elyte, "IonicConductivity")
	if isa(cond_value, AbstractDict)
		if haskey(cond_value, "FunctionName")
			cond = Dict(
				"type" => "function",
				"functionname" => cond_value["FunctionName"],
				"functionpath" => isnothing(get_key_value(cond_value, "FilePath")) ? nothing : normpath(joinpath(dirname(cell_parameters.source_path), get_key_value(cond_value, "FilePath"))),
			)
		else
			cond = Dict(
				"type" => "function",
				"data_x" => cond_value["x"],
				"data_y" => cond_value["y"],
				"argumentlist" => [
					"theta",
				],
			)
		end
	elseif isa(cond_value, String)
		cond = Dict(
			"type" => "function",
			"function" => cond_value,
		)
	else
		error("Function type not recognized")
	end

	###################
	# Control policy
	###################

	if cycling_protocol["Protocol"] == "CC"
		if haskey(cycling_protocol, "UseCVSwitch")
			use_cv_switch = cycling_protocol["UseCVSwitch"]
		else
			use_cv_switch = false

		end
		if cycling_protocol["TotalNumberOfCycles"] == 0
			if cycling_protocol["InitialControl"] == "discharging"
				control = "CCDischarge"
			else
				control = "CCCharge"

			end
		else
			control = "CCCycling"

		end
	elseif cycling_protocol["Protocol"] == "CCCV"
		use_cv_switch = true
		control = "CCCV"

	elseif cycling_protocol["Protocol"] == "Function"
		use_cv_switch = nothing
		control = "Function"

	else
		error("Cycling policy not recognized.")
	end

	battmo_input = Dict(
		"G" => isnothing(get_key_value(simulation_settings, "Grid")) ? [] : get_key_value(simulation_settings, "Grid"),
		"SOC" => get_key_value(cycling_protocol, "InitialStateOfCharge"),
		"initT" => get_key_value(cycling_protocol, "InitialTemperature"),
		"use_thermal" => use_thermal,
		"include_current_collectors" => use_cc,
		"Control" => Dict(
			"controlPolicy" => control,
			"functionName" => get_key_value(cycling_protocol, "FunctionName"),
			"filePath" => isnothing(get_key_value(cycling_protocol, "FilePath")) ? nothing : normpath(joinpath(dirname(cycling_protocol.source_path), get_key_value(cycling_protocol, "FilePath"))),
			"useCVswitch" => use_cv_switch,
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
					"SEImodel" => get_key_value(model_settings, "SEIModel"),
					"Interface" => Dict(
						"saturationConcentration" => get_key_value(ne_am, "MaximumConcentration"),
						"volumetricSurfaceArea" => get_key_value(ne_am, "VolumetricSurfaceArea"),
						"numberOfElectronsTransferred" => get_key_value(ne_am, "NumberOfElectronsTransfered"),
						"activationEnergyOfReaction" => get_key_value(ne_am, "ActivationEnergyOfReaction"),
						"reactionRateConstant" => get_key_value(ne_am, "ReactionRateConstant"),
						"guestStoichiometry100" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC100"),
						"guestStoichiometry0" => get_key_value(ne_am, "StoichiometricCoefficientAtSOC0"),
						"chargeTransferCoefficient" => get_key_value(ne_am, "ChargeTransferCoefficient"),
						"openCircuitPotential" => ne_ocp,
						"SEImolarVolume" => get_key_value(ne_interphase, "MolarVolume"),
						"SEIionicConductivity" => get_key_value(ne_interphase, "IonicConductivity"),
						"SEIelectronicDiffusionCoefficient" => get_key_value(ne_interphase, "ElectronicDiffusionCoefficient"),
						"SEIstoichiometricCoefficient" => get_key_value(ne_interphase, "StoichiometricCoefficient"),
						"SEIinterstitialConcentration" => get_key_value(ne_interphase, "InterstitialConcentration"),
						"SEIlengthInitial" => get_key_value(ne_interphase, "InitialThickness"),
						"SEIvoltageDropRef" => get_key_value(ne_interphase, "InitialPotentialDrop"),
						"SEIlengthRef" => get_key_value(ne_interphase, "InitialThickness"),
						"density" => get_key_value(ne_am, "Density"),
					),
					"diffusionModelType" => diff_type,
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
						"openCircuitPotential" => pe_ocp,
					), "diffusionModelType" => diff_type,
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
			"ionicConductivity" => cond,
			"diffusionCoefficient" => diff,
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
			"externalTemperature" => get_key_value(cycling_protocol, "AmbientTemperature"),
			"externalHeatTransferCoefficientTab" => get_key_value(cell, "HeatTransferCoefficient"),
		),
		"Geometry" => Dict(
			"case" => geom_case,
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
			"totalTime" => get_key_value(cycling_protocol, "TotalTime"),
		),
	)

	return InputParams(battmo_input)

end

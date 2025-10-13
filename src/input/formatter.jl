export convert_parameter_sets_to_old_input_format, convert_to_parameter_sets


function get_key_value(dict::Union{AbstractInput, Dict, Nothing}, key)
	if isnothing(dict)
		value = nothing
	else
		value = get(dict, key, nothing)
	end
	return value
end

function extract_input_sets(simulation_input::FullSimulationInput)

	base_model = get(simulation_input, "BaseModel", nothing)
	model_settings = get(simulation_input, "ModelSettings", nothing)
	cell_parameters = get(simulation_input, "CellParameters", nothing)
	cycling_protocol = get(simulation_input, "CyclingProtocol", nothing)
	simulation_settings = get(simulation_input, "SimulationSettings", nothing)
	solver_settings = get(simulation_input, "SolverSettings", nothing)

	if !isnothing(model_settings)
		model_settings = ModelSettings(model_settings)
	end

	if !isnothing(cell_parameters)
		cell_parameters = CellParameters(cell_parameters)
	end

	if !isnothing(cycling_protocol)
		cycling_protocol = CyclingProtocol(cycling_protocol)
	end
	if !isnothing(simulation_settings)
		simulation_settings = SimulationSettings(simulation_settings)
	end
	if !isnothing(solver_settings)
		solver_settings = SolverSettings(solver_settings)
	end

	return (base_model = base_model,
		model_settings = model_settings,
		cell_parameters = cell_parameters,
		cycling_protocol = cycling_protocol,
		simulation_settings = simulation_settings,
		solver_settings = solver_settings)

end

function convert_to_parameter_sets(params::AdvancedDictInput)

	##################################
	# ModelSettings

	if params["Geometry"]["case"] == "1D"
		geom = "P2D"

	elseif params["Geometry"]["case"] == "3D-demo"
		geom = "P4D Pouch"

	elseif params["Geometry"]["case"] == "jellyRoll"
		geom = "P4D Cylindrical"
	else
		error("ModelFramework not recognized. Please use '1D', '3D-demo' or 'jellyRoll'.")
	end


	model_settings = Dict(
		"ModelFramework" => geom,
		"TransportInSolid" => "FullDiffusion",
		"PotentialFlowDiscretization" => "GeneralAD",
		"ButlerVolmer" => "Standard",
	)

	if haskey(params["NegativeElectrode"]["Coating"]["ActiveMaterial"], "SEImodel")
		model_settings["SEIModel"] = "Bolay"
	end

	if haskey(params, "include_current_collectors") && params["include_current_collectors"] == true
		if model_settings["ModelFramework"] != "P2D"
			model_settings["CurrentCollectors"] = "Standard"
		end
	end

	if haskey(params["TimeStepping"], "use_ramp_up") && params["TimeStepping"]["use_ramp_up"] == true
		model_settings["RampUp"] = "Sinusoidal"
	end


	####################################
	# SimulationSettings

	simulation_settings = Dict(
		"PositiveElectrodeCoatingGridPoints" => params["PositiveElectrode"]["Coating"]["N"],
		"PositiveElectrodeParticleGridPoints" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["N"],
		"NegativeElectrodeCoatingGridPoints" => params["NegativeElectrode"]["Coating"]["N"],
		"NegativeElectrodeParticleGridPoints" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["N"],
		"SeparatorGridPoints" => params["Separator"]["N"], "TimeStepDuration" => params["TimeStepping"]["timeStepDuration"],
	)

	if haskey(model_settings, "RampUp")
		simulation_settings["RampUpTime"] = params["Control"]["rampupTime"]
		simulation_settings["RampUpSteps"] = params["TimeStepping"]["numberOfRampupSteps"]
	end

	if model_settings["ModelFramework"] == "P4D Cylindrical"
		simulation_settings["HeightGridPoints"] = params["Geometry"]["numberOfDiscretizationCellsVertical"]
		simulation_settings["AngularGridPoints"] = params["Geometry"]["numberOfDiscretizationCellsAngular"]

		if haskey(model_settings, "CurrentCollectors")
			simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"] = params["PositiveElectrode"]["CurrentCollector"]["N"]
			simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"] = params["NegativeElectrode"]["CurrentCollector"]["N"]
		end
	end

	if model_settings["ModelFramework"] == "P4D Pouch"
		simulation_settings["ElectrodeWidthGridPoints"] = params["Geometry"]["Nw"]
		simulation_settings["ElectrodeLengthGridPoints"] = params["Geometry"]["Nh"]

		if haskey(model_settings, "CurrentCollectors")
			simulation_settings["PositiveElectrodeCurrentCollectorGridPoints"] = params["PositiveElectrode"]["CurrentCollector"]["N"]
			simulation_settings["PositiveElectrodeCurrentCollectorTabWidthGridPoints"] = params["PositiveElectrode"]["CurrentCollector"]["tab"]["Nw"]
			simulation_settings["PositiveElectrodeCurrentCollectorTabLengthGridPoints"] = params["PositiveElectrode"]["CurrentCollector"]["tab"]["Nh"]
			simulation_settings["NegativeElectrodeCurrentCollectorGridPoints"] = params["NegativeElectrode"]["CurrentCollector"]["N"]
			simulation_settings["NegativeElectrodeCurrentCollectorTabWidthGridPoints"] = params["NegativeElectrode"]["CurrentCollector"]["tab"]["Nw"]
			simulation_settings["NegativeElectrodeCurrentCollectorTabLengthGridPoints"] = params["NegativeElectrode"]["CurrentCollector"]["tab"]["Nh"]
		end
	end

	###########################################
	# CellParameters

	ne_ocp_ = params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]

	if haskey(ne_ocp_, "function")
		ne_ocp = ne_ocp_["function"]
	elseif haskey(ne_ocp_, "functionname")
		ne_ocp = Dict(
			"FunctionName" => ne_ocp_["functionname"],
		)
	elseif haskey(ne_ocp_, "data_x")
		ne_ocp = Dict(
			"x" => ne_ocp_["data_x"],
			"y" => ne_ocp_["data_y"],
		)
	else
		ne_ocp = ne_ocp_

	end

	pe_ocp_ = params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]

	if haskey(pe_ocp_, "function")
		pe_ocp = pe_ocp_["function"]
	elseif haskey(ne_ocp_, "functionname")
		pe_ocp = Dict(
			"FunctionName" => pe_ocp_["functionname"],
		)
	elseif haskey(pe_ocp_, "data_x")
		pe_ocp = Dict(
			"x" => pe_ocp_["data_x"],
			"y" => pe_ocp_["data_y"],
		)
	else
		pe_ocp = pe_ocp_

	end

	cond_ = params["Electrolyte"]["ionicConductivity"]

	if haskey(cond_, "function")
		cond = cond_["function"]
	elseif haskey(cond_, "functionname")
		cond = Dict(
			"FunctionName" => cond_["functionname"],
		)
	elseif haskey(cond_, "data_x")
		cond = Dict(
			"x" => cond_["data_x"],
			"y" => cond_["data_y"],
		)
	else
		cond = cond_

	end

	diff_ = params["Electrolyte"]["diffusionCoefficient"]

	if haskey(diff_, "function")
		diff = diff_["function"]
	elseif haskey(diff_, "functionname")
		diff = Dict(
			"FunctionName" => diff_["functionname"],
		)
	elseif haskey(diff_, "data_x")
		diff = Dict(
			"x" => diff_["data_x"],
			"y" => diff_["data_y"],
		)
	else
		diff = diff_

	end

	cell_parameters = Dict(
		"Cell" => Dict(),
		"NegativeElectrode" => Dict(
			"Coating" => Dict(
				"BruggemanCoefficient" => params["NegativeElectrode"]["Coating"]["bruggemanCoefficient"],
				"EffectiveDensity" => params["NegativeElectrode"]["Coating"]["effectiveDensity"],
				"Thickness" => params["NegativeElectrode"]["Coating"]["thickness"],
			),
			"ActiveMaterial" => Dict(
				"MassFraction" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["massFraction"],
				"Density" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["density"],
				"VolumetricSurfaceArea" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["volumetricSurfaceArea"],
				"ElectronicConductivity" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["electronicConductivity"],
				"DiffusionCoefficient" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["referenceDiffusionCoefficient"],
				"ActivationEnergyOfDiffusion" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["activationEnergyOfDiffusion"],
				"ParticleRadius" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["particleRadius"],
				"MaximumConcentration" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["saturationConcentration"],
				"StoichiometricCoefficientAtSOC0" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["guestStoichiometry0"],
				"StoichiometricCoefficientAtSOC100" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["guestStoichiometry100"],
				"OpenCircuitPotential" => ne_ocp,
				"NumberOfElectronsTransfered" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["numberOfElectronsTransferred"],
				"ActivationEnergyOfReaction" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["activationEnergyOfReaction"],
				"ReactionRateConstant" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["reactionRateConstant"],
				"ChargeTransferCoefficient" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["chargeTransferCoefficient"],
			),
			"ConductiveAdditive" => Dict(
				"Density" => params["NegativeElectrode"]["Coating"]["ConductingAdditive"]["density"],
				"MassFraction" => params["NegativeElectrode"]["Coating"]["ConductingAdditive"]["massFraction"],
				"ElectronicConductivity" => params["NegativeElectrode"]["Coating"]["ConductingAdditive"]["electronicConductivity"],
			),
			"Binder" => Dict(
				"Density" => params["NegativeElectrode"]["Coating"]["Binder"]["density"],
				"MassFraction" => params["NegativeElectrode"]["Coating"]["Binder"]["massFraction"],
				"ElectronicConductivity" => params["NegativeElectrode"]["Coating"]["Binder"]["electronicConductivity"],
			)),
		"PositiveElectrode" => Dict(
			"Coating" => Dict(
				"BruggemanCoefficient" => params["PositiveElectrode"]["Coating"]["bruggemanCoefficient"],
				"EffectiveDensity" => params["PositiveElectrode"]["Coating"]["effectiveDensity"],
				"Thickness" => params["PositiveElectrode"]["Coating"]["thickness"],
			),
			"ActiveMaterial" => Dict(
				"MassFraction" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["massFraction"],
				"Density" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["density"],
				"VolumetricSurfaceArea" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["volumetricSurfaceArea"],
				"ElectronicConductivity" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["electronicConductivity"],
				"DiffusionCoefficient" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["referenceDiffusionCoefficient"],
				"ActivationEnergyOfDiffusion" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["activationEnergyOfDiffusion"],
				"ParticleRadius" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["SolidDiffusion"]["particleRadius"],
				"MaximumConcentration" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["saturationConcentration"],
				"StoichiometricCoefficientAtSOC0" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["guestStoichiometry0"],
				"StoichiometricCoefficientAtSOC100" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["guestStoichiometry100"],
				"OpenCircuitPotential" => pe_ocp,
				"NumberOfElectronsTransfered" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["numberOfElectronsTransferred"],
				"ActivationEnergyOfReaction" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["activationEnergyOfReaction"],
				"ReactionRateConstant" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["reactionRateConstant"],
				"ChargeTransferCoefficient" => params["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["chargeTransferCoefficient"],
			),
			"ConductiveAdditive" => Dict(
				"Density" => params["PositiveElectrode"]["Coating"]["ConductingAdditive"]["density"],
				"MassFraction" => params["PositiveElectrode"]["Coating"]["ConductingAdditive"]["massFraction"],
				"ElectronicConductivity" => params["PositiveElectrode"]["Coating"]["ConductingAdditive"]["electronicConductivity"],
			),
			"Binder" => Dict(
				"Density" => params["PositiveElectrode"]["Coating"]["Binder"]["density"],
				"MassFraction" => params["PositiveElectrode"]["Coating"]["Binder"]["massFraction"],
				"ElectronicConductivity" => params["PositiveElectrode"]["Coating"]["Binder"]["electronicConductivity"],
			)),
		"Separator" => Dict(
			"Porosity" => params["Separator"]["porosity"],
			"Density" => params["Separator"]["density"],
			"BruggemanCoefficient" => params["Separator"]["bruggemanCoefficient"],
			"Thickness" => params["Separator"]["thickness"],
		),
		"Electrolyte" => Dict(
			"Density" => params["Electrolyte"]["density"],
			"Concentration" => params["Electrolyte"]["initialConcentration"],
			"ChargeNumber" => params["Electrolyte"]["species"]["chargeNumber"],
			"TransferenceNumber" => params["Electrolyte"]["species"]["transferenceNumber"],
			"IonicConductivity" => cond,
			"DiffusionCoefficient" => diff,
		),
	)

	if haskey(model_settings, "SEIModel")
		inter = Dict(
			"Interphase" => Dict(
				"MolarVolume" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEImolarVolume"],
				"IonicConductivity" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIionicConductivity"],
				"ElectronicDiffusionCoefficient" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIelectronicDiffusionCoefficient"],
				"StoichiometricCoefficient" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIstoichiometricCoefficient"],
				"InterstitialConcentration" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIinterstitialConcentration"],
				"InitialThickness" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIlengthInitial"],
				"InitialPotentialDrop" => params["NegativeElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["SEIvoltageDropRef"],
			))

		cell_parameters["NegativeElectrode"]["Interphase"] = inter["Interphase"]
	end

	if model_settings["ModelFramework"] == "P2D"
		cell_parameters["Cell"]["ElectrodeGeometricSurfaceArea"] = params["Geometry"]["faceArea"]


	elseif model_settings["ModelFramework"] == "P4D Pouch"
		cell_parameters["Cell"]["ElectrodeWidth"] = params["Geometry"]["width"]
		cell_parameters["Cell"]["ElectrodeLength"] = params["Geometry"]["height"]

		if haskey(model_settings, "CurrentCollectors")
			pos_cc = Dict(
				"CurrentCollector" => Dict(
					"Thickness" => params["PositiveElectrode"]["CurrentCollector"]["thickness"],
					"TabWidth" => params["PositiveElectrode"]["CurrentCollector"]["tab"]["width"],
					"TabLength" => params["PositiveElectrode"]["CurrentCollector"]["tab"]["height"],
					"Density" => params["PositiveElectrode"]["CurrentCollector"]["density"],
					"ElectronicConductivity" => params["PositiveElectrode"]["CurrentCollector"]["electronicConductivity"],
				))

			neg_cc = Dict(
				"CurrentCollector" => Dict(
					"Thickness" => params["NegativeElectrode"]["CurrentCollector"]["thickness"],
					"TabWidth" => params["NegativeElectrode"]["CurrentCollector"]["tab"]["width"],
					"TabLength" => params["NegativeElectrode"]["CurrentCollector"]["tab"]["height"],
					"Density" => params["NegativeElectrode"]["CurrentCollector"]["density"],
					"ElectronicConductivity" => params["NegativeElectrode"]["CurrentCollector"]["electronicConductivity"],
				),
			)

			cell_parameters["NegativeElectrode"]["CurrentCollector"] = neg_cc["CurrentCollector"]
			cell_parameters["PositiveElectrode"]["CurrentCollector"] = pos_cc["CurrentCollector"]
		end

	elseif model_settings["ModelFramework"] == "P4D Cylindrical"
		cell_parameters["Cell"]["Height"] = params["Geometry"]["height"]
		cell_parameters["Cell"]["InnerRadius"] = params["Geometry"]["innerRadius"]
		cell_parameters["Cell"]["OuterRadius"] = params["Geometry"]["outerRadius"]


		if haskey(model_settings, "CurrentCollectors")
			pos_cc = Dict(
				"CurrentCollector" => Dict(
					"Thickness" => params["PositiveElectrode"]["CurrentCollector"]["thickness"],
					"TabWidth" => params["PositiveElectrode"]["CurrentCollector"]["tabparams"]["width"],
					"TabFractions" => params["PositiveElectrode"]["CurrentCollector"]["tabparams"]["fractions"],
					"Density" => params["PositiveElectrode"]["CurrentCollector"]["density"],
					"ElectronicConductivity" => params["PositiveElectrode"]["CurrentCollector"]["electronicConductivity"],
				))

			neg_cc = Dict(
				"CurrentCollector" => Dict(
					"Thickness" => params["NegativeElectrode"]["CurrentCollector"]["thickness"],
					"TabWidth" => params["NegativeElectrode"]["CurrentCollector"]["tabparams"]["width"],
					"TabFractions" => params["NegativeElectrode"]["CurrentCollector"]["tabparams"]["fractions"],
					"Density" => params["NegativeElectrode"]["CurrentCollector"]["density"],
					"ElectronicConductivity" => params["NegativeElectrode"]["CurrentCollector"]["electronicConductivity"],
				),
			)

			cell_parameters["NegativeElectrode"]["CurrentCollector"] = neg_cc["CurrentCollector"]
			cell_parameters["PositiveElectrode"]["CurrentCollector"] = pos_cc["CurrentCollector"]
		end


	end
	#########################################
	# CyclingProtocol

	if params["Control"]["controlPolicy"] == "CCDischarge"
		protocol = "CC"
		init_prot = "discharging"
		n = 0
	else
		protocol = params["Control"]["controlPolicy"]
		init_prot = params["Control"]["initialControl"]
		n = params["Control"]["numberOfCycles"]

	end

	cycling_protocol = Dict(
		"Protocol" => protocol,
		"TotalNumberOfCycles" => n,
		"InitialStateOfCharge" => params["SOC"],
		"DRate" => params["Control"]["DRate"],
		"LowerVoltageLimit" => params["Control"]["lowerCutoffVoltage"],
		"UpperVoltageLimit" => params["Control"]["upperCutoffVoltage"],
		"InitialTemperature" => params["initT"],
		"InitialControl" => init_prot,
	)

	if cycling_protocol["Protocol"] == "CCCV"
		cycling_protocol["CRate"] = params["Control"]["CRate"]
		cycling_protocol["CurrentChangeLimit"] = params["Control"]["dIdtLimit"]
		cycling_protocol["VoltageChangeLimit"] = params["Control"]["dEdtLimit"]
	end

	return (CellParameters(cell_parameters),
		CyclingProtocol(cycling_protocol),
		ModelSettings(model_settings),
		SimulationSettings(simulation_settings))
end

function convert_to_full_simulation_input(input::AdvancedDictInput, base_model = "LithiumIonBattery"; solver_settings = missing)

	cell_parameters, cycling_protocol, model_settings, simulation_settings = convert_to_parameter_sets(input)

	if ismissing(solver_settings)
		solver_settings = get_default_solver_settings(get_model(base_model, model_settings))
	end

	full_simulation_input = Dict(
		"BaseModel" => base_model,
		"ModelSettings" => model_settings.all,
		"CellParameters" => cell_parameters.all,
		"CyclingProtocol" => cycling_protocol.all,
		"SimulationSettings" => simulation_settings.all,
		"SolverSettings" => solver_settings.all,
	)
	return FullSimulationInput(full_simulation_input)

end

function convert_parameter_sets_to_old_input_format(model_settings::ModelSettings, cell_parameters::CellParameters, cycling_protocol::CyclingProtocol, simulation_settings::SimulationSettings)

	cell = get_key_value(cell_parameters, "Cell")
	ne = get_key_value(cell_parameters, "NegativeElectrode")
	ne_coating = get_key_value(ne, "Coating")
	ne_am = get_key_value(ne, "ActiveMaterial")
	ne_interphase = get_key_value(ne, "Interphase")
	ne_b = get_key_value(ne, "Binder")
	ne_cc = get_key_value(ne, "CurrentCollector")
	ne_cc_tab = get_key_value(ne, "CurrentCollectorTab")
	ne_ca = get_key_value(ne, "ConductiveAdditive")

	pe = get_key_value(cell_parameters, "PositiveElectrode")
	pe_coating = get_key_value(pe, "Coating")
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

		elseif geom == "P4D Cylindrical"
			geom_case = "jellyRoll"
		else
			error("ModelFramework $geom not recognized. Please use 'P2D', 'P4D Pouch' or 'P4D Cylindrical'.")
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

	elseif isa(ne_ocp_value, Real)
		ne_ocp = ne_ocp_value

	else
		error("Negative electrode open circuit potential function type $(typeof(ne_ocp_value)) not recognized")
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
	elseif isa(pe_ocp_value, Real)
		pe_ocp = pe_ocp_value
	else
		error("Positive electrode open circuit potential function type $(typeof(pe_ocp_value)) not recognized")
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
	elseif isa(diff_value, Real)
		diff = diff_value
	else
		error("Electrolyte diffusion coefficient function type $(typeof(diff_value)) not recognized")
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
	elseif isa(cond_value, Real)
		cond = cond_value
	else
		error("Electrolyte ionic conductivity function type $(typeof(cond_value)) not recognized")
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
	elseif cycling_protocol["Protocol"] == "Experiment"
		use_cv_switch = nothing
		control = "Generic"

	elseif cycling_protocol["Protocol"] == "Function"
		use_cv_switch = nothing
		control = "Function"

	else
		error("Cycling policy $(cycling_protocol["Protocol"]) not recognized.")
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
					"Nh" => get_key_value(grid_points, "NegativeElectrodeCurrentCollectorTabLength")),
				"tabparams" => Dict(
					"usetab" => true,
					"width" => get_key_value(ne_cc, "TabWidth"),
					"fractions" => get_key_value(ne_cc, "TabFractions"),
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
				"tabparams" => Dict(
					"usetab" => true,
					"width" => get_key_value(pe_cc, "TabWidth"),
					"fractions" => get_key_value(pe_cc, "TabFractions"),
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
			"height" => isnothing(get_key_value(cell, "ElectrodeLength")) ? get_key_value(cell, "Height") : get_key_value(cell, "ElectrodeLength"),
			"innerRadius" => get_key_value(cell, "InnerRadius"),
			"outerRadius" => get_key_value(cell, "OuterRadius"),
			"Nw" => get_key_value(grid_points, "ElectrodeWidth"),
			"Nh" => get_key_value(grid_points, "ElectrodeLength"),
			"numberOfDiscretizationCellsVertical" => get_key_value(grid_points, "Height"),
			"numberOfDiscretizationCellsAngular" => get_key_value(grid_points, "Angular"),
		),
		"TimeStepping" => Dict(
			"useRampup" => use_ramp_up,
			"numberOfRampupSteps" => get_key_value(simulation_settings, "RampUpSteps"),
			"timeStepDuration" => get_key_value(simulation_settings, "TimeStepDuration"),
			"totalTime" => get_key_value(cycling_protocol, "TotalTime"),
		),
	)


	if cycling_protocol["Protocol"] == "Experiment"
		control = convert_experiment_to_battmo_control_input(Experiment(cycling_protocol["Experiment"]))

		battmo_input["Control"] = control["Control"]

		battmo_input["SOC"] = cycling_protocol["InitialStateOfCharge"]
		battmo_input["initT"] = cycling_protocol["InitialKelvinTemperature"]

	end

	battmo_input = AdvancedDictInput(battmo_input)

	if battmo_input["Geometry"]["case"] == "jellyRoll"

		set_input_params!(battmo_input, ["NonLinearSolver", "LinearSolver", "method"], "Iterative")

	end

	return battmo_input

end



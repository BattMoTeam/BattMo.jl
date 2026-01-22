
abstract type IntercalationBattery <: Battery end


function setup_multimodel(model::IntercalationBattery, submodels, input; use_groups = false)

	if !haskey(model.settings, "CurrentCollectors")
		groups = nothing

		multimodel = MultiModel(
			(
				NegativeElectrodeActiveMaterial = submodels.model_neam,
				Electrolyte = submodels.model_elyte,
				PositiveElectrodeActiveMaterial = submodels.model_peam,
				Control = submodels.model_control,
			),
			Val(:IntercalationBattery);
			groups = groups)
	else
		models = (
			NegativeElectrodeCurrentCollector = submodels.model_necc,
			NegativeElectrodeActiveMaterial = submodels.model_neam,
			Electrolyte = submodels.model_elyte,
			PositiveElectrodeActiveMaterial = submodels.model_peam,
			PositiveElectrodeCurrentCollector = submodels.model_pecc,
			Control = submodels.model_control,
		)
		if use_groups
			groups = ones(Int64, length(models))
			# Should be Control
			groups[end] = 2
			reduction = :schur_apply
		else
			groups    = nothing
			reduction = :reduction
		end

		multimodel = MultiModel(models,
			Val(:IntercalationBattery);
			groups = groups, reduction = reduction)

	end

	model.multimodel = multimodel

	return model

end

function setup_submodels(model::IntercalationBattery, input, grids, couplings; kwargs...)

	if haskey(model.settings, "CurrentCollectors")
		include_cc = true
		model_necc = setup_ne_current_collector(input, grids, couplings)
		model_pecc = setup_pe_current_collector(input, grids, couplings)
	else
		include_cc = false
		model_necc = nothing
		model_pecc = nothing
	end

	model_neam = setup_active_material(model, :NegativeElectrodeActiveMaterial, input, grids, couplings)
	model_peam = setup_active_material(model, :PositiveElectrodeActiveMaterial, input, grids, couplings)

	model_elyte = setup_electrolyte(model, input, grids)



	model_control = setup_control_model(input, model_neam, model_peam; kwargs...)



	submodels = (model_neam = model_neam,
		model_peam = model_peam,
		model_necc = model_necc,
		model_pecc = model_pecc,
		model_elyte = model_elyte,
		model_control = model_control)

	return submodels

end

function setup_control_model(input, model_neam, model_peam; T = Float64)

	cycling_protocol = input.cycling_protocol
	model_settings = input.model_settings
	simulation_settings = input.simulation_settings

	use_ramp_up = haskey(model_settings, "RampUp")

	protocol = cycling_protocol["Protocol"]


	if protocol == "CC"

		policy = ConstantCurrent(cycling_protocol.all)
		protocol = GenericProtocol(policy, input; T = T)


	elseif protocol == "CCCV"

		policy = ConstantCurrentConstantVoltage(cycling_protocol.all)
		protocol = GenericProtocol(policy, input; T = T)

	elseif protocol == "Function"

		function_name = cycling_protocol["FunctionName"]
		file_path = get(cycling_protocol, "FilePath", nothing)

		protocol = FunctionProtocol(function_name; file_path)

	elseif protocol == "Experiment"

		policy = Experiment(cycling_protocol.all)

		protocol = GenericProtocol(policy, input; T = T)


	else

		error("controlPolicy not recognized.")

	end

	sys_control    = ExternalCircuitSystem(protocol)
	domain_control = ExternalCircuitDomain()
	model_control  = SimulationModel(domain_control, sys_control)

	return model_control

end

function setup_volume_fractions!(model::IntercalationBattery, grids, coupling)
	multimodel = model.multimodel
	Nelyte = number_of_cells(grids["Electrolyte"])

	names = [:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial]
	stringNames = Dict(:NegativeElectrodeActiveMaterial => "NegativeElectrode",
		:PositiveElectrodeActiveMaterial => "PositiveElectrode")

	vfracs = map(name -> multimodel[name].system[:volume_fraction], names)
	separator_porosity = multimodel[:Electrolyte].system[:separator_porosity]

	T = Base.promote_type(map(typeof, vfracs)..., typeof(separator_porosity))

	vfelyte     = zeros(T, Nelyte)
	vfseparator = zeros(T, Nelyte)

	for (i, name) in enumerate(names)
		stringName = stringNames[name]
		ncell = number_of_cells(grids[stringName])
		ammodel = multimodel[name]
		vf = vfracs[i]
		ammodel.domain.representation[:volumeFraction] = vf * ones(ncell)
		elytecells = coupling[stringName]["cells"]
		vfelyte[elytecells] .= 1 - vf
	end

	elytecells = coupling["Separator"]["cells"]

	vfelyte[elytecells]     .= separator_porosity * ones()
	vfseparator[elytecells] .= (1 - separator_porosity)

	multimodel[:Electrolyte].domain.representation[:volumeFraction] = vfelyte
	multimodel[:Electrolyte].domain.representation[:separator_volume_fraction] = vfseparator

end

function normalize_path(path::AbstractString)
	normpath(replace(path, '\\' => '/'))
end

function setup_electrolyte(model::IntercalationBattery, input, grids)
	params = JutulStorage()

	cell_parameters = input.cell_parameters
	inputparams_elyte = cell_parameters["Electrolyte"]
	base_path = isnothing(cell_parameters.source_path) ? "" : dirname(cell_parameters.source_path)

	params[:transference]        = inputparams_elyte["TransferenceNumber"]
	params[:charge]              = inputparams_elyte["ChargeNumber"]
	params[:separator_porosity]  = cell_parameters["Separator"]["Porosity"]
	params[:bruggeman]           = cell_parameters["Separator"]["BruggemanCoefficient"]
	params[:electrolyte_density] = inputparams_elyte["Density"]
	params[:separator_density]   = cell_parameters["Separator"]["Density"]

	# setup diffusion coefficient function
	if isa(inputparams_elyte["DiffusionCoefficient"], Real)

		params[:diffusivity_constant] = inputparams_elyte["DiffusionCoefficient"]
	elseif isa(inputparams_elyte["DiffusionCoefficient"], String)

		exp = setup_diffusivity_evaluation_expression_from_string(inputparams_elyte["DiffusionCoefficient"])
		params[:diffusivity_func] = @RuntimeGeneratedFunction(exp)

	elseif haskey(inputparams_elyte["DiffusionCoefficient"], "FunctionName")

		funcname = inputparams_elyte["DiffusionCoefficient"]["FunctionName"]
		if haskey(inputparams_elyte["DiffusionCoefficient"], "FilePath")
			rawpath = inputparams_elyte["DiffusionCoefficient"]["FilePath"]
			funcpath = joinpath(base_path, normalize_path(rawpath))
		else
			funcpath = nothing
		end

		fcn = setup_function_from_function_name(funcname; file_path = funcpath)
		params[:diffusivity_func] = fcn

	else
		data_x = inputparams_elyte["DiffusionCoefficient"]["x"]
		data_y = inputparams_elyte["DiffusionCoefficient"]["y"]

		interpolation = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		params[:diffusivity_data] = true
		params[:diffusivity_func] = interpolation

	end

	# setup conductivity function
	if isa(inputparams_elyte["IonicConductivity"], Real)

		params[:conductivity_constant] = inputparams_elyte["IonicConductivity"]
	elseif isa(inputparams_elyte["IonicConductivity"], String)

		exp = setup_conductivity_evaluation_expression_from_string(inputparams_elyte["IonicConductivity"])
		params[:conductivity_func] = @RuntimeGeneratedFunction(exp)

	elseif haskey(inputparams_elyte["IonicConductivity"], "FunctionName")

		funcname = inputparams_elyte["IonicConductivity"]["FunctionName"]

		if haskey(inputparams_elyte["IonicConductivity"], "FilePath")
			rawpath = inputparams_elyte["IonicConductivity"]["FilePath"]
			funcpath = joinpath(base_path, normalize_path(rawpath))
		else
			funcpath = nothing
		end

		fcn = setup_function_from_function_name(funcname; file_path = funcpath)
		params[:conductivity_func] = fcn

	else
		data_x = inputparams_elyte["IonicConductivity"]["x"]
		data_y = inputparams_elyte["IonicConductivity"]["y"]

		interpolation = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		params[:conductivity_data] = true
		params[:conductivity_func] = interpolation

	end

	elyte = Electrolyte(params)

	model_elyte = setup_component(grids["Electrolyte"], elyte, general_ad = true)

	return model_elyte
end

function setup_ne_current_collector(input, grids, couplings)
	grid = grids["NegativeCurrentCollector"]
	coupling = couplings["NegativeCurrentCollector"]

	boundary = coupling["External"]
	necc_params = JutulStorage()
	necc_params[:density] = input.cell_parameters["NegativeElectrode"]["CurrentCollector"]["Density"]

	sys_necc = CurrentCollector(necc_params)
	model_necc = setup_component(grid,
		sys_necc,
		dirichletBoundary = boundary,
		flow_discretization = input.model_settings["PotentialFlowDiscretization"])

	return model_necc
end

function setup_pe_current_collector(input, grids, couplings)
	grid = grids["PositiveCurrentCollector"]
	pecc_params = JutulStorage()
	pecc_params[:density] = input.cell_parameters["PositiveElectrode"]["CurrentCollector"]["Density"]

	sys_pecc = CurrentCollector(pecc_params)

	model_pecc = setup_component(grid, sys_pecc,
		flow_discretization = input.model_settings["PotentialFlowDiscretization"])

	return model_pecc
end

function compute_volume_fraction(codict)
	# We compute the volume fraction form the coating data

	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductiveAdditive"

	compnames = [am, bd, ad]

	# Do it this way since values could be AD.
	get_specific_volume(compname) = codict[compname]["MassFraction"] / codict[compname]["Density"]
	specificVolumes = map(get_specific_volume, compnames)

	sumSpecificVolumes = sum(specificVolumes)
	volumeFractions = [sv / sumSpecificVolumes for sv in specificVolumes]

	effectiveDensity = codict["Coating"]["EffectiveDensity"]
	volumeFraction = sumSpecificVolumes * effectiveDensity

	return volumeFraction, volumeFractions, effectiveDensity

end

"""
	Helper function to setup the active materials
	"""
function setup_active_material(model::IntercalationBattery, name::Symbol, input, grids, couplings)

	stringNames = Dict(
		:NegativeElectrodeActiveMaterial => "NegativeElectrode",
		:PositiveElectrodeActiveMaterial => "PositiveElectrode",
	)

	stringName = stringNames[name]

	cell_parameters = input.cell_parameters

	base_path = isnothing(cell_parameters.source_path) ? "" : dirname(cell_parameters.source_path)

	inputparams_electrode = cell_parameters[stringName]
	inputparams_active_material = cell_parameters[stringName]["ActiveMaterial"]

	am_params = JutulStorage()
	vf, vfs, eff_dens = compute_volume_fraction(inputparams_electrode)
	am_params[:volume_fraction] = vf
	am_params[:volume_fractions] = vfs
	am_params[:effective_density] = eff_dens

	am_params[:n_charge_carriers] = inputparams_active_material["NumberOfElectronsTransfered"]
	am_params[:maximum_concentration] = inputparams_active_material["MaximumConcentration"]
	am_params[:volumetric_surface_area] = inputparams_active_material["VolumetricSurfaceArea"]
	am_params[:theta0] = inputparams_active_material["StoichiometricCoefficientAtSOC0"]
	am_params[:theta100] = inputparams_active_material["StoichiometricCoefficientAtSOC100"]

	am_params[:setting_temperature_dependence] = get(model.settings, "TemperatureDependence", nothing)
	am_params[:setting_butler_volmer] = get(model.settings, "ButlerVolmer", nothing)

	if am_params[:setting_temperature_dependence] == "Arrhenius"
		am_params[:activation_energy_of_diffusion] = inputparams_active_material["ActivationEnergyOfDiffusion"]
		am_params[:activation_energy_of_reaction] = inputparams_active_material["ActivationEnergyOfReaction"]
	end

	if isa(inputparams_active_material["ReactionRateConstant"], Real)
		am_params[:ecd_funcconstant] = true
		am_params[:reaction_rate_constant_func] = inputparams_active_material["ReactionRateConstant"]

	elseif isa(inputparams_active_material["ReactionRateConstant"], String)

		am_params[:ecd_funcexp] = true
		ocp_exp = inputparams_active_material["ReactionRateConstant"]
		exp = setup_reaction_rate_constant_evaluation_expression_from_string(ocp_exp)
		f_generated = @RuntimeGeneratedFunction(exp)
		am_params[:reaction_rate_constant_func] = f_generated

	elseif haskey(inputparams_active_material["ReactionRateConstant"], "FunctionName")

		funcname = inputparams_active_material["ReactionRateConstant"]["FunctionName"]

		if haskey(inputparams_active_material["ReactionRateConstant"], "FilePath")
			rawpath = inputparams_active_material["ReactionRateConstant"]["FilePath"]
			funcpath = joinpath(base_path, normalize_path(rawpath))
		else
			funcpath = nothing
		end

		fcn = setup_function_from_function_name(funcname; file_path = funcpath)
		am_params[:reaction_rate_constant_func] = fcn

	else
		am_params[:ecd_funcdata] = true
		data_x = inputparams_active_material["ReactionRateConstant"]["x"]
		data_y = inputparams_active_material["ReactionRateConstant"]["y"]

		interpolation_object = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		am_params[:reaction_rate_constant_func] = interpolation_object
	end

	if isa(inputparams_active_material["OpenCircuitPotential"], Real)
		am_params[:ocp_funcconstant] = true
		am_params[:ocp_func] = inputparams_active_material["OpenCircuitPotential"]

	elseif isa(inputparams_active_material["OpenCircuitPotential"], String)

		am_params[:ocp_funcexp] = true
		ocp_exp = inputparams_active_material["OpenCircuitPotential"]
		exp = setup_ocp_evaluation_expression_from_string(ocp_exp)
		f_generated = @RuntimeGeneratedFunction(exp)
		am_params[:ocp_func] = f_generated

	elseif haskey(inputparams_active_material["OpenCircuitPotential"], "FunctionName")

		funcname = inputparams_active_material["OpenCircuitPotential"]["FunctionName"]

		if haskey(inputparams_active_material["OpenCircuitPotential"], "FilePath")
			rawpath = inputparams_active_material["OpenCircuitPotential"]["FilePath"]
			funcpath = joinpath(base_path, normalize_path(rawpath))
		else
			funcpath = nothing
		end

		fcn = setup_function_from_function_name(funcname; file_path = funcpath)
		am_params[:ocp_func] = fcn

	else
		am_params[:ocp_funcdata] = true
		data_x = inputparams_active_material["OpenCircuitPotential"]["x"]
		data_y = inputparams_active_material["OpenCircuitPotential"]["y"]

		interpolation_object = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
		am_params[:ocp_func] = interpolation_object
	end

	refT     = 298.15
	T        = get(input.cycling_protocol, "InitialTemperature", refT)
	SOC_init = input.cycling_protocol["InitialStateOfCharge"]

	theta0   = inputparams_active_material["StoichiometricCoefficientAtSOC0"]
	theta100 = inputparams_active_material["StoichiometricCoefficientAtSOC100"]
	cmax     = inputparams_active_material["MaximumConcentration"]


	theta = SOC_init * (theta100 - theta0) + theta0
	c     = theta * cmax

	if haskey(model.settings, "TransportInSolid") && model.settings["TransportInSolid"] == "FullDiffusion"
		rp = inputparams_active_material["ParticleRadius"]
		N  = Int64(input.simulation_settings[stringName*"ParticleGridPoints"])

		if isa(inputparams_active_material["DiffusionCoefficient"], Real)
			am_params[:diff_funcconstant] = true
			am_params[:diff_func] = inputparams_active_material["DiffusionCoefficient"]
			D = am_params[:diff_func]

		elseif isa(inputparams_active_material["DiffusionCoefficient"], String)

			am_params[:diff_funcexp] = true
			diff_exp = inputparams_active_material["DiffusionCoefficient"]
			exp = setup_electrode_diff_evaluation_expression_from_string(diff_exp)
			f_generated = @RuntimeGeneratedFunction(exp)
			am_params[:diff_func] = f_generated
			D = am_params[:diff_func](c, T, refT, cmax)
		elseif haskey(inputparams_active_material["DiffusionCoefficient"], "FunctionName")

			funcname = inputparams_active_material["DiffusionCoefficient"]["FunctionName"]

			if haskey(inputparams_active_material["DiffusionCoefficient"], "FilePath")
				rawpath = inputparams_active_material["DiffusionCoefficient"]["FilePath"]
				funcpath = joinpath(base_path, normalize_path(rawpath))
			else
				funcpath = nothing
			end

			fcn = setup_function_from_function_name(funcname; file_path = funcpath)

			am_params[:diff_func] = fcn
			D = am_params[:diff_func](c, T, refT, cmax)

		else
			am_params[:diff_funcdata] = true
			data_x = inputparams_active_material["DiffusionCoefficient"]["x"]
			data_y = inputparams_active_material["DiffusionCoefficient"]["y"]

			interpolation_object = get_1d_interpolator(data_x, data_y, cap_endpoints = false)
			am_params[:diff_func] = interpolation_object
			D = am_params[:diff_func](c / cmax)
		end

		if haskey(model.settings, "SEIModel") && model.settings["SEIModel"] == "Bolay" && haskey(inputparams_electrode, "Interphase")
			label = :sei
			fds = ["InitialThickness",
				"InitialPotentialDrop",
				"StoichiometricCoefficient",
				"MolarVolume",
				"ElectronicDiffusionCoefficient",
				"InterstitialConcentration",
				"IonicConductivity"]
			for fd in fds
				am_params[Symbol(fd)] = inputparams_electrode["Interphase"][fd]

			end
		else
			label = nothing
		end

		sys_am = ActiveMaterialP2D(am_params, rp, N, D; label = label)
	else
		sys_am = ActiveMaterialNoParticleDiffusion(am_params)
	end

	grid     = grids[stringName]
	coupling = couplings[stringName]

	boundary = nothing
	if !haskey(model.settings, "CurrentCollectors") && name == :NegativeElectrodeActiveMaterial
		addDirichlet = true
		boundary = coupling["External"]
	else
		addDirichlet = false
		boundary = nothing
	end

	model_am = setup_component(grid,
		sys_am;
		general_ad = true,
		dirichletBoundary = boundary)

	return model_am

end

function compute_effective_conductivity(comodel, coinputparams)

	# Compute effective conductivity for the coating

	# First we compute the intrinsic conductivity as volume weight average of the subcomponents
	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductiveAdditive"

	compnames = [am, bd, ad]

	vfs = comodel.system.params[:volume_fractions]
	kappa = 0
	for icomp in eachindex(compnames)
		compname = compnames[icomp]
		vf = vfs[icomp]
		kappa += vf * coinputparams[compname]["ElectronicConductivity"]
	end

	vf = comodel.system.params[:volume_fraction]
	bg = coinputparams["Coating"]["BruggemanCoefficient"]

	kappaeff = (vf^bg) * kappa

	return kappaeff

end

function set_parameters(model::IntercalationBattery, input
)
	multimodel = model.multimodel
	cycling_protocol = input.cycling_protocol
	cell_parameters = input.cell_parameters

	parameters = Dict{Symbol, Any}()

	refT = 298.15
	T = get(cycling_protocol, "InitialTemperature", refT)

	if haskey(model.settings, "CurrentCollectors")

		#######################################
		# Negative current collector (if any) #
		#######################################

		prm_necc = Dict{Symbol, Any}()
		inputparams_necc = cell_parameters["NegativeElectrode"]["CurrentCollector"]
		prm_necc[:Conductivity] = inputparams_necc["ElectronicConductivity"]
		parameters[:NegativeElectrodeCurrentCollector] = setup_parameters(multimodel[:NegativeElectrodeCurrentCollector], prm_necc)

	end

	############################
	# Negative active material #
	############################

	prm_neam = Dict{Symbol, Any}()
	inputparams_neam = cell_parameters["NegativeElectrode"]["ActiveMaterial"]

	prm_neam[:Conductivity] = compute_effective_conductivity(multimodel[:NegativeElectrodeActiveMaterial], cell_parameters["NegativeElectrode"])
	prm_neam[:Temperature] = T

	if discretisation_type(multimodel[:NegativeElectrodeActiveMaterial]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(multimodel[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion
		prm_neam[:Diffusivity] = inputparams_neam["DiffusionCoefficient"]
	end

	parameters[:NegativeElectrodeActiveMaterial] = setup_parameters(multimodel[:NegativeElectrodeActiveMaterial], prm_neam)

	###############
	# Electrolyte #
	###############

	prm_elyte = Dict{Symbol, Any}()
	prm_elyte[:Temperature] = T
	prm_elyte[:BruggemanCoefficient] = cell_parameters["Separator"]["BruggemanCoefficient"]


	parameters[:Electrolyte] = setup_parameters(multimodel[:Electrolyte], prm_elyte)

	############################
	# Positive active material #
	############################

	prm_peam = Dict{Symbol, Any}()
	inputparams_peam = cell_parameters["PositiveElectrode"]["ActiveMaterial"]

	prm_peam[:Conductivity] = compute_effective_conductivity(multimodel[:PositiveElectrodeActiveMaterial], cell_parameters["PositiveElectrode"])
	prm_peam[:Temperature] = T


	if discretisation_type(multimodel[:PositiveElectrodeActiveMaterial]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(multimodel[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion
		prm_peam[:Diffusivity] = inputparams_peam["DiffusionCoefficient"]
	end

	parameters[:PositiveElectrodeActiveMaterial] = setup_parameters(multimodel[:PositiveElectrodeActiveMaterial], prm_peam)

	if haskey(model.settings, "CurrentCollectors")

		#######################################
		# Positive current collector (if any) #
		#######################################

		prm_pecc = Dict{Symbol, Any}()
		inputparams_pecc = cell_parameters["PositiveElectrode"]["CurrentCollector"]
		prm_pecc[:Conductivity] = inputparams_pecc["ElectronicConductivity"]

		parameters[:PositiveElectrodeCurrentCollector] = setup_parameters(multimodel[:PositiveElectrodeCurrentCollector], prm_pecc)
	end

	###########
	# Control #
	###########

	prm_control = Dict{Symbol, Any}()

	protocol = cycling_protocol["Protocol"]

	if protocol == "Function"
		cap = computeCellCapacity(multimodel)
		con = Constants()
		parameters[:Control] = setup_parameters(multimodel[:Control])

	else
		total_time = haskey(cycling_protocol, "TotalTime") ? cycling_protocol["TotalTime"] : calculate_total_time(cycling_protocol)
		prm_control[:TotalTime] = total_time
		parameters[:Control] = setup_parameters(multimodel[:Control], prm_control)

	end

	return parameters

end



##################
# Setup coupling #
##################

function setup_coupling_cross_terms!(model::IntercalationBattery,
	parameters::Dict{Symbol, <:Any},
	couplings)

	multimodel = model.multimodel

	stringNames = Dict(:NegativeElectrodeCurrentCollector => "NegativeCurrentCollector",
		:NegativeElectrodeActiveMaterial => "NegativeElectrode",
		:PositiveElectrodeActiveMaterial => "PositiveElectrode",
		:PositiveElectrodeCurrentCollector => "PositiveCurrentCollector")

	#################################
	# Setup coupling NeAm <-> Elyte #
	#################################

	srange = collect(couplings["NegativeElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["NegativeElectrode"]["cells"]) # electrolyte (negative side)

	if discretisation_type(multimodel[:NegativeElectrodeActiveMaterial]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(multimodel, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(multimodel, ct_pair)

		if multimodel[:NegativeElectrodeActiveMaterial] isa SEImodel
			ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :sei_mass_cons)
			add_cross_term!(multimodel, ct_pair)
			ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :Electrolyte, equation = :sei_voltage_drop)
			add_cross_term!(multimodel, ct_pair)
		end

	else

		@assert discretisation_type(multimodel[:NegativeElectrodeActiveMaterial]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :NegativeElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(multimodel, ct_pair)

	end

	#################################
	# setup coupling Elyte <-> PeAm #
	#################################

	srange = collect(couplings["PositiveElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["PositiveElectrode"]["cells"])

	if discretisation_type(multimodel[:PositiveElectrodeActiveMaterial]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(multimodel, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeActiveMaterial, source = :Electrolyte, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeActiveMaterial, source = :Electrolyte, equation = :solid_diffusion_bc)
		add_cross_term!(multimodel, ct_pair)

	else

		@assert discretisation_type(multimodel[:PositiveElectrodeActiveMaterial]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Electrolyte, source = :PositiveElectrodeActiveMaterial, equation = :mass_conservation)
		add_cross_term!(multimodel, ct_pair)

	end

	if haskey(model.settings, "CurrentCollectors")

		################################
		# Setup coupling NeCc <-> NeAm #
		################################

		#Ncc  = geomparams[:NegativeElectrodeCurrentCollector][:N]

		srange_cells = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["cells"])
		trange_cells = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["cells"])

		srange_faces = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["faces"])
		trange_faces = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["faces"])

		msource = multimodel[:NegativeElectrodeCurrentCollector]
		mtarget = multimodel[:NegativeElectrodeActiveMaterial]

		psource = parameters[:NegativeElectrodeCurrentCollector]
		ptarget = parameters[:NegativeElectrodeActiveMaterial]

		# Here, the indexing in BoundaryFaces is used
		couplingfaces = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingfaces[:, 1] = srange_faces
		couplingfaces[:, 2] = trange_faces

		couplingcells = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingcells[:, 1] = srange_cells
		couplingcells[:, 2] = trange_cells

		trans = getTrans(msource, mtarget,
			couplingfaces,
			couplingcells,
			psource, ptarget,
			:Conductivity)
		@assert size(trans, 1) == size(srange_cells, 1)
		ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeActiveMaterial, source = :NegativeElectrodeCurrentCollector, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)
		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :NegativeElectrodeCurrentCollector, source = :NegativeElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)

		################################
		# setup coupling PeCc <-> PeAm #
		################################

		#Npam  = geomparams[:PositiveElectrodeActiveMaterial][:N]

		srange_cells = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["cells"])
		trange_cells = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["cells"])

		srange_faces = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["faces"])
		trange_faces = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["faces"])

		msource = multimodel[:PositiveElectrodeCurrentCollector]
		mtarget = multimodel[:PositiveElectrodeActiveMaterial]

		psource = parameters[:PositiveElectrodeCurrentCollector]
		ptarget = parameters[:PositiveElectrodeActiveMaterial]

		# Here, the indexing in BoundaryFaces is used
		couplingfaces = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingfaces[:, 1] = srange_faces
		couplingfaces[:, 2] = trange_faces


		couplingcells = Array{Int64}(undef, size(srange_faces, 1), 2)
		couplingcells[:, 1] = srange_cells
		couplingcells[:, 2] = trange_cells

		trans = getTrans(msource, mtarget,
			couplingfaces,
			couplingcells,
			psource, ptarget,
			:Conductivity)
		@assert size(trans, 1) == size(srange_cells, 1)
		ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeActiveMaterial, source = :PositiveElectrodeCurrentCollector, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)

		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :PositiveElectrodeCurrentCollector, source = :PositiveElectrodeActiveMaterial, equation = :charge_conservation)
		add_cross_term!(multimodel, ct_pair)

	end

	########################################
	# setup coupling PeCc/NeAm <-> control #
	########################################

	if haskey(model.settings, "CurrentCollectors")
		controlComp = :PositiveElectrodeCurrentCollector
	else
		controlComp = :PositiveElectrodeActiveMaterial
	end

	stringControlComp = stringNames[controlComp]

	trange = couplings[stringControlComp]["External"]["cells"]
	srange = Int64.(ones(size(trange)))

	msource     = multimodel[controlComp]
	mparameters = parameters[controlComp]

	# Here the indexing in BoundaryFaces in used
	couplingfaces = couplings[stringControlComp]["External"]["boundaryfaces"]
	couplingcells = trange
	trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

	ct = TPFAInterfaceFluxCT(trange, srange, trans)
	ct_pair = setup_cross_term(ct, target = controlComp, source = :Control, equation = :charge_conservation)
	add_cross_term!(multimodel, ct_pair)

	ct = AccumulatorInterfaceFluxCT(1, trange, trans)
	ct_pair = setup_cross_term(ct, target = :Control, source = controlComp, equation = :charge_conservation)
	add_cross_term!(multimodel, ct_pair)

	ct1 = AccumulatorInterfaceFluxCT(1, trange, trans * 0.0)
	ct1_pair = setup_cross_term(ct1, target = :Control, source = controlComp, equation = :control)
	add_cross_term!(multimodel, ct1_pair)


end


function setup_initial_state(input, model::IntercalationBattery)

	multimodel = model.multimodel

	include_cc = haskey(model.settings, "CurrentCollectors")

	refT     = 298.15
	T        = get(input.cycling_protocol, "InitialTemperature", refT)
	SOC_init = input.cycling_protocol["InitialStateOfCharge"]

	function setup_init_am(name, multimodel)

		theta0   = multimodel[name].system[:theta0]
		theta100 = multimodel[name].system[:theta100]
		cmax     = multimodel[name].system[:maximum_concentration]
		N        = multimodel[name].system.discretization[:N]
		refT     = 298.15

		theta = SOC_init * (theta100 - theta0) + theta0
		c = theta * cmax
		SOC = SOC_init
		nc = count_entities(multimodel[name].data_domain, Cells())
		init = Dict()
		init[:SurfaceConcentration] = fill(c, nc)
		init[:ParticleConcentration] = fill(c, N, nc)

		if multimodel[name] isa SEImodel
			init[:normalizedSEIlength] = ones(nc)
			init[:normalizedSEIvoltageDrop] = zeros(nc)
		end

		if haskey(multimodel[name].system.params, :ocp_funcexp)
			OCP = multimodel[name].system[:ocp_func](c, T, refT, cmax)
		elseif haskey(multimodel[name].system.params, :ocp_funcdata)

			OCP = multimodel[name].system[:ocp_func](theta)
		elseif haskey(multimodel[name].system.params, :ocp_constant)
			OCP = multimodel[name].system[:ocp_constant]

		else
			OCP = multimodel[name].system[:ocp_func](c, T, refT, cmax)
		end

		return (init, nc, OCP)

	end

	function setup_current_collector(name, phi, multimodel)
		nc = count_entities(multimodel[name].data_domain, Cells())
		init = Dict()
		if phi isa Int
			phi = convert(Float64, phi)
		end
		init[:ElectricPotential] = fill(phi, nc)
		return init
	end

	initState = Dict()

	# Setup initial state in negative active material

	init, nc, negOCP = setup_init_am(:NegativeElectrodeActiveMaterial, multimodel)
	init[:ElectricPotential] = zeros(typeof(negOCP), nc)
	initState[:NegativeElectrodeActiveMaterial] = init

	# Setup initial state in electrolyte

	nc = count_entities(multimodel[:Electrolyte].data_domain, Cells())

	init = Dict()
	init[:ElectrolyteConcentration] = input.cell_parameters["Electrolyte"]["Concentration"] * ones(nc)
	init[:ElectricPotential] = fill(-negOCP, nc)

	initState[:Electrolyte] = init

	# Setup initial state in positive active material

	init, nc, posOCP = setup_init_am(:PositiveElectrodeActiveMaterial, multimodel)
	init[:ElectricPotential] = fill(posOCP - negOCP, nc)

	initState[:PositiveElectrodeActiveMaterial] = init

	if include_cc
		# Setup negative current collector
		initState[:NegativeElectrodeCurrentCollector] = setup_current_collector(:NegativeElectrodeCurrentCollector, 0, multimodel)
		# Setup positive current collector
		initState[:PositiveElectrodeCurrentCollector] = setup_current_collector(:PositiveElectrodeCurrentCollector, posOCP - negOCP, multimodel)
	end

	init = Dict()
	init[:ElectricPotential] = posOCP - negOCP
	init[:Current] = get_initial_current(multimodel[:Control])

	initState[:Control] = init

	initState = setup_state(multimodel, initState)

	return initState

end

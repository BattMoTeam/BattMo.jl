
export
	run_battery,
	setup_simulation


###############
# Run battery #
###############

"""


"""
# abstract type SolvingProcess end

# struct Simulate <: SolvingProcess
# 	model::MultiModel,
# 	initial_states::OrderedDict{Any, Any},
# 	time_steps::Vector,
# 	forces::OrderedDict{Any, Any}
# 	run::Function

# 	function Simulate(model, cycling_parameters; simulation_settings = (number_of_time_steps = 100, use_ramp_up = true, number_of_ramp_up_steps = 10))

# 	end
# end




function run_battery(inputparams::AbstractInputParams, battery_model::BatteryModel;
	hook = nothing,
	kwargs...)
	"""
		Run battery wrapper method. Call setup_simulation function and run the simulation with the setup that is returned. A hook function can be given to modify the setup after the call to setup_simulation
	"""

	#Setup simulation
	output = setup_simulation(deepcopy(inputparams), battery_model; kwargs...)

	simulator = output[:simulator]
	model     = output[:model]
	state0    = output[:state0]
	forces    = output[:forces]
	timesteps = output[:timesteps]
	cfg       = output[:cfg]

	if !isnothing(hook)
		hook(simulator,
			model,
			state0,
			forces,
			timesteps,
			cfg)
	end

	# Perform simulation
	states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	extra = output
	extra[:timesteps] = timesteps

	if isa(inputparams, MatlabInputParams)
		cellSpecifications = nothing
	else
		cellSpecifications = computeCellSpecifications(model)
	end

	return (states             = states,
		cellSpecifications = cellSpecifications,
		reports            = reports,
		inputparams        = inputparams,
		extra              = extra)

end


"""
	run_battery(inputparams::AbstractInputParams; hook = nothing)

Simulate a battery for a given input. The input is expected to be an instance of AbstractInputParams. Such input can be
prepared from a json file using the function [`readBattMoJsonInputFile`](@ref).


"""
function run_battery(inputparams::AbstractInputParams, ::Type{M};
	hook = nothing,
	kwargs...) where {M <: BatteryModel}
	"""
		Run battery wrapper method. Call setup_simulation function and run the simulation with the setup that is returned. A hook function can be given to modify the setup after the call to setup_simulation
	"""

	battery_model = M(inputparams; kwargs...)

	#Setup simulation
	output = setup_simulation(deepcopy(inputparams), battery_model; kwargs...)

	simulator = output[:simulator]
	model     = output[:model]
	state0    = output[:state0]
	forces    = output[:forces]
	timesteps = output[:timesteps]
	cfg       = output[:cfg]

	if !isnothing(hook)
		hook(simulator,
			model,
			state0,
			forces,
			timesteps,
			cfg)
	end

	# Perform simulation
	states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

	extra = output
	extra[:timesteps] = timesteps

	if isa(inputparams, MatlabInputParams)
		cellSpecifications = nothing
	else
		cellSpecifications = computeCellSpecifications(model)
	end

	return (states             = states,
		cellSpecifications = cellSpecifications,
		reports            = reports,
		inputparams        = inputparams,
		extra              = extra)

end










############################
# Setup battery parameters #
############################

function setup_battery_parameters(inputparams::InputParams,
	model::MultiModel,
)

	function computeEffectiveConductivity(comodel, coinputparams)

		# Compute effective conductivity for the coating

		# First we compute the intrinsic conductivity as volume weight average of the subcomponents
		am = "ActiveMaterial"
		bd = "Binder"
		ad = "ConductingAdditive"

		compnames = [am, bd, ad]

		vfs = comodel.system.params[:volume_fractions]
		kappa = 0
		for icomp in eachindex(compnames)
			compname = compnames[icomp]
			vf = vfs[icomp]
			kappa += vf * coinputparams[compname]["electronicConductivity"]
		end

		vf = comodel.system.params[:volume_fraction]
		bg = coinputparams["bruggemanCoefficient"]

		kappaeff = (vf^bg) * kappa

		return kappaeff

	end

	parameters = Dict{Symbol, Any}()

	T0 = inputparams["initT"]

	include_cc = include_current_collectors(model)

	if include_cc

		#######################################
		# Negative current collector (if any) #
		#######################################

		prm_necc = Dict{Symbol, Any}()
		inputparams_necc = inputparams["NegativeElectrode"]["CurrentCollector"]
		prm_necc[:Conductivity] = inputparams_necc["electronicConductivity"]
		parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)

	end

	############################
	# Negative active material #
	############################

	prm_neam = Dict{Symbol, Any}()
	inputparams_neam = inputparams["NegativeElectrode"]["Coating"]["ActiveMaterial"]

	prm_neam[:Conductivity] = computeEffectiveConductivity(model[:NeAm], inputparams["NegativeElectrode"]["Coating"])
	prm_neam[:Temperature] = T0

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_neam[:Diffusivity] = inputparams_neam["InterDiffusionCoefficient"]
	end

	parameters[:NeAm] = setup_parameters(model[:NeAm], prm_neam)

	###############
	# Electrolyte #
	###############

	prm_elyte = Dict{Symbol, Any}()
	prm_elyte[:Temperature] = T0


	parameters[:Elyte] = setup_parameters(model[:Elyte], prm_elyte)

	############################
	# Positive active material #
	############################

	prm_peam = Dict{Symbol, Any}()
	inputparams_peam = inputparams["PositiveElectrode"]["Coating"]["ActiveMaterial"]

	prm_peam[:Conductivity] = computeEffectiveConductivity(model[:PeAm], inputparams["PositiveElectrode"]["Coating"])
	prm_peam[:Temperature] = T0


	if discretisation_type(model[:PeAm]) == :P2Ddiscretization
		# nothing to do
	else
		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
		prm_peam[:Diffusivity] = inputparams_peam["InterDiffusionCoefficient"]
	end

	parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

	if include_cc

		#######################################
		# Positive current collector (if any) #
		#######################################

		prm_pecc = Dict{Symbol, Any}()
		inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]
		prm_pecc[:Conductivity] = inputparams_pecc["electronicConductivity"]

		parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
	end

	###########
	# Control #
	###########

	prm_control = Dict{Symbol, Any}()

	controlPolicy = inputparams["Control"]["controlPolicy"]

	if controlPolicy == "CCDischarge"

		cap = computeCellCapacity(model)
		con = Constants()

		DRate = inputparams["Control"]["DRate"]
		prm_control[:ImaxDischarge] = (cap / con.hour) * DRate

		parameters[:Control] = setup_parameters(model[:Control], prm_control)

	elseif controlPolicy == "CCCV"

		cap = computeCellCapacity(model)
		con = Constants()

		DRate                       = inputparams["Control"]["DRate"]
		CRate                       = inputparams["Control"]["CRate"]
		prm_control[:ImaxDischarge] = (cap / con.hour) * DRate
		prm_control[:ImaxCharge]    = (cap / con.hour) * CRate

		parameters[:Control] = setup_parameters(model[:Control], prm_control)

	else
		error("control policy $controlPolicy not recognized")
	end

	return parameters

end

#######################
# Setup initial state #
#######################



##################
# Setup coupling #
##################

function setup_coupling_cross_terms!(inputparams::InputParams,
	model::MultiModel,
	parameters::Dict{Symbol, <:Any},
	couplings)

	include_cc = inputparams["include_current_collectors"]


	stringNames = Dict(:NeCc => "NegativeCurrentCollector",
		:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode",
		:PeCc => "PositiveCurrentCollector")

	#################################
	# Setup coupling NeAm <-> Elyte #
	#################################

	srange = collect(couplings["NegativeElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["NegativeElectrode"]["cells"]) # electrolyte (negative side)

	if discretisation_type(model[:NeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

		if model[:NeAm] isa SEImodel
			ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :sei_mass_cons)
			add_cross_term!(model, ct_pair)
			ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :sei_voltage_drop)
			add_cross_term!(model, ct_pair)
		end

	else

		@assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	#################################
	# setup coupling Elyte <-> PeAm #
	#################################

	srange = collect(couplings["PositiveElectrode"]["Electrolyte"]["cells"])
	trange = collect(couplings["Electrolyte"]["PositiveElectrode"]["cells"])

	if discretisation_type(model[:PeAm]) == :P2Ddiscretization

		ct = ButlerVolmerActmatToElyteCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

		ct = ButlerVolmerElyteToActmatCT(srange, trange)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :solid_diffusion_bc)
		add_cross_term!(model, ct_pair)

	else

		@assert discretisation_type(model[:PeAm]) == :NoParticleDiffusion

		ct = ButlerVolmerInterfaceFluxCT(trange, srange)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
		add_cross_term!(model, ct_pair)

	end

	if include_cc

		################################
		# Setup coupling NeCc <-> NeAm #
		################################

		#Ncc  = geomparams[:NeCc][:N]

		srange_cells = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["cells"])
		trange_cells = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["cells"])

		srange_faces = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["faces"])
		trange_faces = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["faces"])

		msource = model[:NeCc]
		mtarget = model[:NeAm]

		psource = parameters[:NeCc]
		ptarget = parameters[:NeAm]

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
		ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)
		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :NeCc, source = :NeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		################################
		# setup coupling PeCc <-> PeAm #
		################################

		#Npam  = geomparams[:PeAm][:N]

		srange_cells = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["cells"])
		trange_cells = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["cells"])

		srange_faces = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["faces"])
		trange_faces = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["faces"])

		msource = model[:PeCc]
		mtarget = model[:PeAm]

		psource = parameters[:PeCc]
		ptarget = parameters[:PeAm]

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
		ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

		ct = TPFAInterfaceFluxCT(srange_cells, trange_cells, trans)
		ct_pair = setup_cross_term(ct, target = :PeCc, source = :PeAm, equation = :charge_conservation)
		add_cross_term!(model, ct_pair)

	end

	########################################
	# setup coupling PeCc/NeAm <-> control #
	########################################

	if include_cc
		controlComp = :PeCc
	else
		controlComp = :PeAm
	end

	stringControlComp = stringNames[controlComp]

	trange = couplings[stringControlComp]["External"]["cells"]
	srange = Int64.(ones(size(trange)))

	msource     = model[controlComp]
	mparameters = parameters[controlComp]

	# Here the indexing in BoundaryFaces in used
	couplingfaces = couplings[stringControlComp]["External"]["boundaryfaces"]
	couplingcells = trange
	trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

	ct = TPFAInterfaceFluxCT(trange, srange, trans)
	ct_pair = setup_cross_term(ct, target = controlComp, source = :Control, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)

	ct = AccumulatorInterfaceFluxCT(1, trange, trans)
	ct_pair = setup_cross_term(ct, target = :Control, source = controlComp, equation = :charge_conservation)
	add_cross_term!(model, ct_pair)

	ct1 = AccumulatorInterfaceFluxCT(1, trange, trans * 0.0)
	ct1_pair = setup_cross_term(ct1, target = :Control, source = controlComp, equation = :control)
	add_cross_term!(model, ct1_pair)


end

##################
# Setup scalings #
##################

function get_scalings(model, parameters)

	refT = 298.15

	electrolyte = model[:Elyte].system

	eldes = (:NeAm, :PeAm)

	j0s   = Array{Float64}(undef, 2)
	Rvols = Array{Float64}(undef, 2)

	F = FARADAY_CONSTANT

	for (i, elde) in enumerate(eldes)

		rate_func = model[elde].system.params[:reaction_rate_constant_func]
		cmax      = model[elde].system[:maximum_concentration]
		vsa       = model[elde].system[:volumetric_surface_area]

		c_a            = 0.5 * cmax
		R0             = rate_func(c_a, refT)
		c_e            = 1000.0
		activematerial = model[elde].system

		j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial)
		Rvols[i] = j0s[i] * vsa / F

	end

	j0Ref   = mean(j0s)
	RvolRef = mean(Rvols)

	if include_current_collectors(model)
		component_names = (:NeCc, :NeAm, :Elyte, :PeAm, :PeCc)
		cc_mapping      = Dict(:NeAm => :NeCc, :PeAm => :PeCc)
	else
		component_names = (:NeAm, :Elyte, :PeAm)
	end

	volRefs = Dict()

	for name in component_names

		rep = model[name].domain.representation
		if rep isa MinimalECTPFAGrid
			volRefs[name] = mean(rep.volumes)
		else
			volRefs[name] = mean(rep[:volumes])
		end

	end

	scalings = []

	scaling = (model_label = :Elyte, equation_label = :charge_conservation, value = F * volRefs[:Elyte] * RvolRef)
	push!(scalings, scaling)

	scaling = (model_label = :Elyte, equation_label = :mass_conservation, value = volRefs[:Elyte] * RvolRef)
	push!(scalings, scaling)

	for elde in eldes

		scaling = (model_label = elde, equation_label = :charge_conservation, value = F * volRefs[elde] * RvolRef)
		push!(scalings, scaling)

		if include_current_collectors(model)

			# We use the same scaling as for the coating multiplied by the conductivity ration
			cc = cc_mapping[elde]
			coef = parameters[cc][:Conductivity] / parameters[elde][:Conductivity]

			scaling = (model_label = cc, equation_label = :charge_conservation, value = F * coef[1] * volRefs[elde] * RvolRef)
			push!(scalings, scaling)

		end

		rp   = model[elde].system.discretization[:rp]
		volp = 4 / 3 * pi * rp^3

		coef = RvolRef * volp

		scaling = (model_label = elde, equation_label = :mass_conservation, value = coef)
		push!(scalings, scaling)
		scaling = (model_label = elde, equation_label = :solid_diffusion_bc, value = coef)
		push!(scalings, scaling)

		if model[elde] isa SEImodel

			vsa = model[elde].system[:volumetric_surface_area]
			L   = model[elde].system[:SEIlengthInitial]
			k   = model[elde].system[:SEIionicConductivity]

			SEIvoltageDropRef = F * RvolRef / vsa * L / k

			scaling = (model_label = elde, equation_label = :sei_voltage_drop, value = SEIvoltageDropRef)
			push!(scalings, scaling)

			De = model[elde].system[:SEIelectronicDiffusionCoefficient]
			ce = model[elde].system[:SEIintersticialConcentration]

			scaling = (model_label = elde, equation_label = :sei_mass_cons, value = De * ce / L)
			push!(scalings, scaling)

		end

	end

	return scalings

end

######################
# Setup timestepping #
######################



######################################
# Setup solver configuration options #
######################################

"""
	setup_config(sim::Jutul.JutulSimulator,
					  model::MultiModel        ,
					  linear_solver::Symbol    ,
					  extra_timing::Bool;
					  kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function setup_config(sim::JutulSimulator,
	model::MultiModel,
	parameters,
	linear_solver::Symbol,
	extra_timing::Bool,
	use_model_scaling::Bool;
	kwargs...)

	cfg = simulator_config(sim; kwargs...)

	cfg[:linear_solver]            = battery_linsolve(model, linear_solver)
	cfg[:debug_level]              = 0
	cfg[:max_timestep_cuts]        = 10
	cfg[:max_residual]             = 1e20
	cfg[:output_substates]         = true
	cfg[:min_nonlinear_iterations] = 1
	cfg[:extra_timing]             = extra_timing
	# cfg[:max_nonlinear_iterations] = 5
	cfg[:safe_mode]             = false
	cfg[:error_on_incomplete]   = false
	cfg[:failure_cuts_timestep] = true

	if use_model_scaling
		scalings = get_scalings(model, parameters)
		tol_default = 1e-5
		for scaling in scalings
			model_label = scaling[:model_label]
			equation_label = scaling[:equation_label]
			value = scaling[:value]
			cfg[:tolerances][model_label][equation_label] = value * tol_default
		end
	else
		for key in Jutul.submodels_symbols(model)
			cfg[:tolerances][key][:default] = 1e-5
		end
	end

	if model[:Control].system.policy isa CyclingCVPolicy

		cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)

		function post_hook(done, report, sim, dt, forces, max_iter, cfg)

			s = Jutul.get_simulator_storage(sim)
			m = Jutul.get_simulator_model(sim)

			if s.state.Control.ControllerCV.numberOfCycles >= m[:Control].system.policy.numberOfCycles
				report[:stopnow] = true
			else
				report[:stopnow] = false
			end

			return (done, report)

		end

		cfg[:post_ministep_hook] = post_hook

	end

	return cfg

end




#########################
# Setup volume fraction # 
#########################

function setup_volume_fractions!(model::MultiModel, grids, coupling)

	Nelyte      = number_of_cells(grids["Electrolyte"])
	vfelyte     = zeros(Nelyte)
	vfseparator = zeros(Nelyte)

	names = [:NeAm, :PeAm]
	stringNames = Dict(:NeAm => "NegativeElectrode",
		:PeAm => "PositiveElectrode")

	for name in names
		stringName = stringNames[name]
		ncell = number_of_cells(grids[stringName])
		ammodel = model[name]
		vf = ammodel.system[:volume_fraction]
		ammodel.domain.representation[:volumeFraction] = vf * ones(ncell)
		elytecells = coupling[stringName]["cells"]
		vfelyte[elytecells] .= 1 - vf
	end

	separator_porosity = model[:Elyte].system[:separator_porosity]
	elytecells         = coupling["Separator"]["cells"]

	vfelyte[elytecells]     .= separator_porosity * ones()
	vfseparator[elytecells] .= (1 - separator_porosity)

	model[:Elyte].domain.representation[:volumeFraction] = vfelyte
	model[:Elyte].domain.representation[:separator_volume_fraction] = vfseparator

end

######################
# Transmissibilities #
######################

function getTrans(model1::Dict{String, <:Any},
	model2::Dict{String, Any},
	faces,
	cells,
	quantity::String)
	""" setup transmissibility for coupling between models at boundaries"""

	T_all1 = model1["G"]["operators"]["T_all"][faces[:, 1]]
	T_all2 = model2["G"]["operators"]["T_all"][faces[:, 2]]


	function getcellvalues(values, cellinds)

		if length(values) == 1
			values = values * ones(length(cellinds))
		else
			values = values[cellinds]
		end
		return values

	end

	s1 = getcellvalues(model1[quantity], cells[:, 1])
	s2 = getcellvalues(model2[quantity], cells[:, 2])

	T = 1.0 ./ ((1.0 ./ (T_all1 .* s1)) + (1.0 ./ (T_all2 .* s2)))

	return T

end

function getTrans(model1::SimulationModel,
	model2::SimulationModel,
	bcfaces,
	bccells,
	parameters1,
	parameters2,
	quantity)
	""" setup transmissibility for coupling between models at boundaries. Intermediate 1d version"""

	d1 = physical_representation(model1)
	d2 = physical_representation(model2)

	bcTrans1 = d1[:bcTrans][bcfaces[:, 1]]
	bcTrans2 = d2[:bcTrans][bcfaces[:, 2]]
	cells1   = bccells[:, 1]
	cells2   = bccells[:, 2]

	s1 = parameters1[quantity][cells1]
	s2 = parameters2[quantity][cells2]

	T = 1.0 ./ ((1.0 ./ (bcTrans1 .* s1)) + (1.0 ./ (bcTrans2 .* s2)))

	return T

end

function getHalfTrans(model::Jutul.SimulationModel,
	bcfaces,
	bccells,
	parameters,
	quantity)
	""" recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the corresponding given cells. Intermediate 1d version. Note the indexing in BoundaryFaces is used"""

	d       = physical_representation(model)
	bcTrans = d[:bcTrans][bcfaces]
	s       = parameters[quantity][bccells]

	T = bcTrans .* s

	return T
end

function getHalfTrans(model::Dict{String, Any},
	faces,
	cells,
	quantity::String)
	""" recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the given cells.
	Here, the faces should belong the corresponding cells at the same index"""

	T_all = model["G"]["operators"]["T_all"]
	s = model[quantity]
	if length(s) == 1
		s = s * ones(length(cells))
	else
		s = s[cells]
	end

	T = T_all[faces] .* s

	return T

end

function getHalfTrans(model::Dict{String, <:Any},
	faces)
	""" recover the half transmissibilities for boundary faces"""

	T_all = model["G"]["operators"]["T_all"]
	T = T_all[faces]

	return T

end






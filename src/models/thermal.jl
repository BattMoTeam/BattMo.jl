struct EffectiveVolumetricHeatCapacity <: ScalarVariable end
struct EffectiveThermalConductivity <: ScalarVariable end

const ThermalParameters = JutulStorage

struct ThermalSystem{T} <: BattMoSystem where {T <: ThermalParameters}
	params::T
end

function ThermalSystem(params::ThermalParameters)
	params = Jutul.convert_to_immutable_storage(params)
	return ThermalSystem{typeof(params)}(params)
end

function ThermalSystem()
	ThermalSystem(Dict())
end

const ThermalModel = SimulationModel{O, S, F, C} where {O <: JutulDomain, S <: ThermalSystem, F <: JutulFormulation, C <: JutulContext}


function Jutul.select_minimum_output_variables!(out,
	system::ThermalSystem, model::SimulationModel,
)
	push!(out, :Temperature)
	push!(out, :Energy)
end

function Jutul.select_primary_variables!(
	S, system::ThermalSystem, model::SimulationModel,
)
	S[:Temperature] = Temperature()
end

function Jutul.select_secondary_variables!(
	S, system::ThermalSystem, model::SimulationModel,
)
	# S[:TPkGrad_Voltage] = TPkGrad{ElectricPotential}()
	S[:Energy] = Energy()

end

@jutul_secondary function update_energy!(acc,
	tv::Energy,
	model,
	Temperature,
	Volume,
	EffectiveVolumetricHeatCapacity,
	ix)
	for i in ix
		@inbounds acc[i] = Temperature[i] * Volume[i] * EffectiveVolumetricHeatCapacity[i]
	end

end

# @jutul_secondary function update_as_secondary!(acc,
# 	tv::Energy,
# 	model,
# 	Temperature,
# 	ix)
# 	for i in ix
# 		@inbounds acc[i] = Temperature[i]
# 	end

# end

function Jutul.select_parameters!(S,
	system::ThermalSystem,
	model::BattMoModel)

	S[:EffectiveThermalConductivity] = EffectiveThermalConductivity()
	S[:EffectiveVolumetricHeatCapacity] = EffectiveVolumetricHeatCapacity()
	S[:BoundaryTemperature] = BoundaryTemperature() # BoundaryTemperature is declared below
	S[:ExternalHeatTransferCoefficient] = ExternalHeatTransferCoefficient() # ExternalHeatTransferCoefficient is declared below

end

# function select_parameters!(S,
# 	system::Thermal,
# 	model::SimulationModel)

# 	S[:EffectiveThermalConductivity] = EffectiveThermalConductivity()
# 	if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
# 		if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
# 			S[:BoundaryTemperature] = BoundaryTemperature(:Temperature)
# 		end
# 	end

# end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model::ThermalModel, dt, flow_disc) where T

	htrans_cell, htrans_other = setup_half_trans(model, face, c, other, face_sign)

	j = - half_face_two_point_kgrad(c, other, htrans_cell, htrans_other, state.Temperature, state.EffectiveThermalConductivity)

	return T(j)

end

function Jutul.apply_forces_to_equation!(diag_part, storage, model::ThermalModel, eq::ConservationLaw{:Energy}, eq_s, force, time)

	for i in eachindex(force)
		diag_part[i] -= force[i]
	end

end

function Jutul.select_equations!(eqs,
	system::ThermalSystem,
	model::SimulationModel)

	disc = model.domain.discretizations.flow
	eqs[:energy_conservation] = ConservationLaw(disc, :Energy)

end


#######################
# Boundary conditions #
#######################


struct BoundaryTemperature <: ScalarVariable end
Jutul.associated_entity(::BoundaryTemperature) = BoundaryFaces()

struct ExternalHeatTransferCoefficient <: ScalarVariable end
Jutul.associated_entity(::ExternalHeatTransferCoefficient) = BoundaryFaces()

function apply_bc_to_equation!(storage, parameters, model::ThermalModel, eq::ConservationLaw{:Energy}, eq_s)

	acc   = get_diagonal_entries(eq, eq_s)
	state = storage.state

	apply_boundary_temperature!(acc, state, parameters, model, eq)

end

function apply_boundary_temperature!(acc, state, parameters, model::ThermalModel, eq::ConservationLaw{:Energy})

	dolegacy = false

	# if model.domain.representation isa MinimalECTPFAGrid

	# 	error("not supported yet")
	# 	bc = model.domain.representation.boundary_cells
	# 	if length(bc) > 0
	# 		dobc = true
	# 	else
	# 		dobc = false
	# 	end

	# 	dolegacy = true

	# else

	# 	bchalftrans = model.domain.representation[:bcTrans]
	# 	bccells     = model.domain.representation[:boundary_neighbors]

	# end

	bchalftrans = model.domain.representation[:bcTrans]
	bccells     = model.domain.representation[:boundary_neighbors]

	dobc = true

	if dobc

		T = state[:Temperature]
		BoundaryT = state[:BoundaryTemperature]
		conductivity = state[:EffectiveThermalConductivity]
		extcoef = state[:ExternalHeatTransferCoefficient]
		use_boundary_series_resistance = get(model.system.params, :use_boundary_series_resistance, true)

		if dolegacy
			T_hf = model.domain.representation.boundary_hfT
			for (i, c) in enumerate(bc)
				m = 1/(1/conductivity[c]*T_hf[i] + 1/extcoef)
				@inbounds acc[c] += m*(T[c] - value(BoundaryT[i]))
			end
		else
			for (i, (ht, c)) in enumerate(zip(bchalftrans, bccells))
				if extcoef[i] > 0

					m = 1/(1/(ht*conductivity[c]) + 1/extcoef[i])

				else
					m = 0
				end
				@inbounds acc[c] += m*(T[c] - value(BoundaryT[i]))
			end
		end
	end

end

#######################
# setup thermal model #
#######################

function setup_thermal_model(model, submodels, input, grids, global_maps)

	cell_parameters = input.cell_parameters
	thermal_parameters = cell_parameters["ThermalModel"]
	maps = global_maps

	@show keys(maps)

	ne = "NegativeElectrode"
	pe = "PositiveElectrode"
	elyte = "Electrolyte"
	sep = "Separator"
	am = "ActiveMaterial"
	bd = "Binder"
	ad = "ConductiveAdditive"
	cc = "CurrentCollector"

	eldes = [ne, pe] # Electrode domains

	global_grid = grids["Global"]

	nc = Jutul.number_of_cells(global_grid)

	volumetric_heat_capacity = zeros(nc)
	thermal_conductivity = zeros(nc)

	for ind in eachindex(eldes)
		elde = eldes[ind]

		# Current collectors
		if haskey(model.settings, "CurrentCollectors")

			cc_map = maps[string(elde, cc)][1].cellmap
			cc_volumetric_heat_capacity = submodels[string(elde, cc)].system.params[:effective_volumetric_heat_capacity]
			cc_thermal_conductivity = submodels[string(elde, cc)].system.params[:effective_thermal_conductivity]

			volumetric_heat_capacity[cc_map] .= cc_volumetric_heat_capacity
			thermal_conductivity[cc_map] .= cc_thermal_conductivity
		end

		# Active material (coating)
		am_map = maps[string(elde, am)][1].cellmap
		am_volumetric_heat_capacity = submodels[string(elde, am)].system.params[:effective_volumetric_heat_capacity]
		am_thermal_conductivity = submodels[string(elde, am)].system.params[:effective_thermal_conductivity]

		volumetric_heat_capacity[am_map] .= am_volumetric_heat_capacity
		thermal_conductivity[am_map] .= am_thermal_conductivity

	end

	# Electrolyte
	elyte_map = maps[string(elyte)][1].cellmap
	elyte_volumetric_heat_capacity = submodels[string(elyte)].system.params[:effective_volumetric_heat_capacity]
	elyte_thermal_conductivity = submodels[string(elyte)].system.params[:effective_thermal_conductivity]

	volumetric_heat_capacity[elyte_map] .= elyte_volumetric_heat_capacity
	thermal_conductivity[elyte_map] .= elyte_thermal_conductivity

	# Separator
	sep_map = maps[string(sep)][1].cellmap
	sep_volumetric_heat_capacity = submodels[string(sep)].system.params[:effective_volumetric_heat_capacity]
	sep_thermal_conductivity = submodels[string(sep)].system.params[:effective_thermal_conductivity]

	volumetric_heat_capacity[sep_map] .= sep_volumetric_heat_capacity
	thermal_conductivity[sep_map] .= sep_thermal_conductivity


	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)

	prm                                   = JutulStorage()
	prm[:BoundaryTemperature]             = thermal_parameters["ExternalTemperature"]
	prm[:ExternalHeatTransferCoefficient] = thermal_parameters["ExternalHeatTransferCoefficient"]
	prm[:EffectiveVolumetricHeatCapacity] = volumetric_heat_capacity
	prm[:EffectiveThermalConductivity]    = thermal_conductivity

	prm_dict                                   = Dict{Symbol, Any}()
	prm_dict[:BoundaryTemperature]             = thermal_parameters["ExternalTemperature"]
	prm_dict[:ExternalHeatTransferCoefficient] = thermal_parameters["ExternalHeatTransferCoefficient"]
	prm_dict[:EffectiveVolumetricHeatCapacity] = volumetric_heat_capacity
	prm_dict[:EffectiveThermalConductivity]    = thermal_conductivity

	# Setup system

	thermalsystem = ThermalSystem(prm)

	model = setup_component(global_grid, thermalsystem)

	@show propertynames(prm)

	parameters = setup_parameters(model, prm_dict)

	# parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
	parameters[:ExternalHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:ExternalHeatTransferCoefficient]

	return model, parameters

end

function setup_thermal_model(input, grids)

	cell_parameters = input.cell_parameters

	grid = grids["ThermalModel"]
	nc = Jutul.number_of_cells(grid)
	thermal_parameters = cell_parameters["ThermalModel"]

	thermalsystem = ThermalSystem()

	model = setup_component(grid, thermalsystem)

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)

	prm                                   = Dict{Symbol, Any}()
	prm[:BoundaryTemperature]             = thermal_parameters["ExternalTemperature"]
	prm[:ExternalHeatTransferCoefficient] = thermal_parameters["ExternalHeatTransferCoefficient"]

	prm[:EffectiveVolumetricHeatCapacity] = thermal_parameters["EffectiveVolumetricHeatCapacity"]

	prm[:EffectiveThermalConductivity] = thermal_parameters["EffectiveThermalConductivity"]

	parameters = setup_parameters(model, prm)

	# parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
	parameters[:ExternalHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:ExternalHeatTransferCoefficient]

	return model, parameters

end



###########################################
# The following two setups are not working

# function setup_thermal_model(::Val{:simple}, inputparams::AdditionaInputFormats; N = 2, Nz = 10)

# 	grid = CartesianMesh((N, N, Nz), (1.0, 1.0, 1.0))
# 	grid = UnstructuredMesh(grid)

# 	sys = ThermalSystem()

# 	domain = DataDomain(grid)

# 	# operators only, use geometry, not property
# 	k = ones(number_of_cells(grid))

# 	T    = compute_face_trans(domain, k)
# 	T_hf = compute_half_face_trans(domain, k)
# 	T_b  = compute_boundary_trans(domain, k)

# 	domain[:trans, Faces()]           = T
# 	domain[:halfTrans, HalfFaces()]   = T_hf
# 	domain[:bcTrans, BoundaryFaces()] = T_b

# 	flow = PotentialFlow(grid)

# 	disc = (flow = flow,)
# 	domain = DiscretizedDomain(domain, disc)

# 	model = SimulationModel(domain, sys)

# 	prm                                   = Dict{Symbol, Any}()
# 	prm[:EffectiveVolumetricHeatCapacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:EffectiveThermalConductivity]                    = inputparams["ThermalModel"]["conductivity"]
# 	prm[:BoundaryTemperature]             = inputparams["ThermalModel"]["externalTemperature"]
# 	prm[:ExternalHeatTransferCoefficient] = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]

# 	parameters = setup_parameters(model, prm)

# 	parameters[:ExternalHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:ExternalHeatTransferCoefficient]

# 	vertfaces = [findBoundary(grid, 1, true); findBoundary(grid, 1, false)]
# 	vertfaces = append!(vertfaces, [findBoundary(grid, 2, true); findBoundary(grid, 2, false)])
# 	parameters[:ExternalHeatTransferCoefficient][vertfaces] .= 0

# 	return model, parameters

# end


# function setup_thermal_model(inputparams::AdditionaInputFormats;
# 	general_ad = true,
# 	kwargs...)

# 	grids, = setup_grids_and_couplings(inputparams)

# 	grid = grids["ThermalModel"]

# 	thermalsystem = ThermalSystem()

# 	model = setup_component(grid, thermalsystem;
# 		general_ad = general_ad)


# 	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
# 	# sensitivities)

# 	prm                                   = Dict{Symbol, Any}()
# 	prm[:EffectiveVolumetricHeatCapacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:EffectiveThermalConductivity]                    = inputparams["ThermalModel"]["conductivity"]
# 	prm[:BoundaryTemperature]             = inputparams["ThermalModel"]["externalTemperature"]
# 	prm[:ExternalHeatTransferCoefficient] = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]

# 	parameters = setup_parameters(model, prm)

# 	# parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
# 	parameters[:ExternalHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:ExternalHeatTransferCoefficient]

# 	return model, parameters

# end



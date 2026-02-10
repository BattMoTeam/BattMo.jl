struct Capacity <: ScalarVariable end

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
	Capacity,
	ix)
	for i in ix
		@inbounds acc[i] = Temperature[i] * Volume[i] * Capacity[i]
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

	S[:Conductivity]                    = Conductivity()
	S[:Capacity]                        = Capacity()
	S[:BoundaryTemperature]             = BoundaryTemperature() # BoundaryTemperature is declared below
	S[:ExternalHeatTransferCoefficient] = ExternalHeatTransferCoefficient() # ExternalHeatTransferCoefficient is declared below

end

# function select_parameters!(S,
# 	system::Thermal,
# 	model::SimulationModel)

# 	S[:Conductivity] = Conductivity()
# 	if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
# 		if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
# 			S[:BoundaryTemperature] = BoundaryTemperature(:Temperature)
# 		end
# 	end

# end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model::ThermalModel, dt, flow_disc) where T

	htrans_cell, htrans_other = setup_half_trans(model, face, c, other, face_sign)

	j = - half_face_two_point_kgrad(c, other, htrans_cell, htrans_other, state.Temperature, state.Conductivity)

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

		T            = state[:Temperature]
		BoundaryT    = state[:BoundaryTemperature]
		conductivity = state[:Conductivity]
		extcoef      = state[:ExternalHeatTransferCoefficient]

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

function setup_thermal_model(input, grids)

	cell_parameters = input.cell_parameters

	grid = grids["ThermalModel"]

	thermalsystem = ThermalSystem()

	model = setup_component(grid, thermalsystem)

	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
	# sensitivities)

	prm = Dict{Symbol, Any}()
	# prm[:Capacity]                        = cell_parameters["ThermalModel"]["Capacity"]
	# prm[:Conductivity]                    = cell_parameters["ThermalModel"]["Conductivity"]
	prm[:BoundaryTemperature]             = cell_parameters["ThermalModel"]["ExternalTemperature"]
	prm[:ExternalHeatTransferCoefficient] = cell_parameters["ThermalModel"]["ExternalHeatTransferCoefficient"]

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
# 	prm[:Capacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:Conductivity]                    = inputparams["ThermalModel"]["conductivity"]
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
# 	prm[:Capacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:Conductivity]                    = inputparams["ThermalModel"]["conductivity"]
# 	prm[:BoundaryTemperature]             = inputparams["ThermalModel"]["externalTemperature"]
# 	prm[:ExternalHeatTransferCoefficient] = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]

# 	parameters = setup_parameters(model, prm)

# 	# parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
# 	parameters[:ExternalHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:ExternalHeatTransferCoefficient]

# 	return model, parameters

# end



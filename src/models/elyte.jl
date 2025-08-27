# Model for a electrolyte

export
	Electrolyte,
	DmuDc,
	ChemCoef,
	p1,
	p2,
	p3,
	diffusivity,
	ElectrolyteModel

const ElectrolyteParameters = JutulStorage

struct Electrolyte{D} <: BattMoSystem where {D <: AbstractDict}
	params::ElectrolyteParameters
	#  
	# - bruggeman          
	# - charge             
	# - conductivity_data  
	# - conductivity_func  
	# - diffusivity_data   
	# - diffusivity_func   
	# - separator_porosity 
	# - transference
	# - electrolyte_density
	# - separator_density
	scalings::D
end

function Electrolyte(params, scalings = Dict())

	return Electrolyte{typeof(scalings)}(params, scalings)

end

# Alias for convenience
const ElectrolyteModel = SimulationModel{<:Any, <:Electrolyte, <:Any, <:Any}

# Is it necesessary with a new struct for all of these?
struct DmuDc <: ScalarVariable end
struct ChemCoef <: ScalarVariable end

function Jutul.select_primary_variables!(S,
	system::Electrolyte,
	model::SimulationModel)

	S[:Voltage] = Voltage()
	S[:Concentration] = Concentration()

end

function Jutul.select_parameters!(S,
	system::Electrolyte,
	model::SimulationModel,
)

	S[:Temperature] = Temperature()
	S[:BruggemanCoefficient] = BruggemanCoefficient()
	S[:VolumeFraction] = VolumeFraction()

end

function Jutul.select_equations!(eqs,
	system::Electrolyte,
	model::SimulationModel,
)

	disc = model.domain.discretizations.flow

	eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
	eqs[:mass_conservation]   = ConservationLaw(disc, :Mass)

end

function Jutul.select_secondary_variables!(S,
	system::Electrolyte,
	model::SimulationModel)

	S[:Conductivity] = Conductivity()
	S[:Diffusivity]  = Diffusivity()
	S[:DmuDc]        = DmuDc()
	S[:ChemCoef]     = ChemCoef()

	S[:Charge] = Charge()
	S[:Mass]   = Mass()

end

function Jutul.select_minimum_output_variables!(out,
	system::Electrolyte,
	model::SimulationModel)

	for k in [:Charge, :Mass, :Conductivity, :Diffusivity]
		push!(out, k)
	end

end


#######################
# Secondary Variables #
#######################

const poly_param = [
	-10.5       0.074       -6.96e-5;
	0.668e-3    -1.78e-5    2.80e-8;
	0.494e-6    -8.86e-10   0
]
const p1 = Polynomial(poly_param[1:end, 1])
const p2 = Polynomial(poly_param[1:end, 2])
const p3 = Polynomial(poly_param[1:end, 3])

@inline function computeElectrolyteConductivity_default(c::Real, T::Real)
	""" Compute the electrolyte conductivity as a function of temperature and concentration
	"""
	fact = 1e-4
	return fact * c * (p1(c) + p2(c) * T + p3(c) * T^2)^2
end

@inline function computeElectrolyteConductivity_Chen2020(c::Real, T::Real)
	""" Compute the electrolyte conductivity as a function of concentration
	"""
	c = c / 1000
	return 0.1297 * c^3 - 2.51 * c^(1.5) + 3.329 * c
end

@inline function computeElectrolyteConductivity_Xu2015(c::Real, T::Real)
	""" Compute the electrolyte conductivity as a function of concentration
	"""
	conductivityFactor = 1e-4

	# cnst = [-10.5   , 0.074    , -6.96e-5; ...
	#         0.668e-3, -1.78e-5 , 2.80e-8; ...
	#         0.494e-6, -8.86e-10, 0];            


	#  Ionic conductivity, [S m^-1]
	# conductivity = conductivityFactor.* c .*( polyval(cnst(end:-1:1,1),c) + polyval(cnst(end:-1:1,2),c) .* T + ...
	#                                           polyval(cnst(end:-1:1,3),c) .* T.^2).^2;
	# From cideMOD

	conductivity = c * 1e-4 * 1.2544 * (-8.2488 + 0.053248 * T - 2.987e-5 * (T^2) + 0.26235e-3 * c - 9.3063e-6 * c * T + 8.069e-9 * c * T^2 + 2.2002e-7 * c^2 - 1.765e-10 * T * c^2)
	return conductivity
end

const diff_params = [
	-4.43   -54;
	-0.22   0.0
]
const Tgi = [229 5.0]

@inline function computeDiffusionCoefficient_default(c::Real, T::Real)
	""" Compute the diffusion coefficient as a function of temperature and concentration
	"""
	return (
		1e-4 * 10^(
			diff_params[1, 1] +
			diff_params[1, 2] / (T - Tgi[1] - Tgi[2] * c * 1e-3) +
			diff_params[2, 1] * c * 1e-3
		)
	)
end

@inline function computeDiffusionCoefficient_Chen2020(c::Real, T::Real)
	""" Compute the diffusion coefficient as a function of concentration
	"""
	c = c / 1000
	return 8.794 * 10^(-11) * c^2 - 3.972 * 10^(-10) * c + 4.862 * 10^(-10)
end


@inline function computeDiffusionCoefficient_Xu2015(c::Real, T::Real)
	""" Compute the diffusion coefficient as a function of concentration
	"""
	# Calculate diffusion coefficients constant for the diffusion coefficient calculation
	cnst = [                                                                    -4.43 -54
		-0.22 0.0]

	Tgi = [229 5.0]

	# Diffusion coefficient, [m^2 s^-1]
	#Removed 10⁻⁴ otherwise the same
	D = 10^((cnst[1, 1] + cnst[1, 2] / (T - Tgi[1] - Tgi[2] * c * 1e-3) + cnst[2, 1] * c * 1e-3))
	return D
end

@inline function transference(system::Electrolyte)
	return system[:transference]
end

@jutul_secondary(
	function update_dmudc!(dmudc, dmudc_def::DmuDc, model, Temperature, Concentration, ix)
		R = GAS_CONSTANT
		@tullio dmudc[i] = R * (Temperature[i] / Concentration[i])
	end
)

# ? Does this maybe look better ?
@jutul_secondary(
	function update_conductivity!(kappa, kappa_def::Conductivity, model::ElectrolyteModel, Temperature, Concentration, VolumeFraction, BruggemanCoefficient, ix)
		""" Register conductivity function
		"""

		# We use Bruggeman coefficient
		for i in ix
			b = BruggemanCoefficient[i]
			if haskey(model.system.params, :conductivity_data)

				@inbounds kappa[i] = model.system[:conductivity_func](Concentration[i]) * VolumeFraction[i]^b
			elseif haskey(model.system.params, :conductivity_constant)
				@inbounds kappa[i] = model.system[:conductivity_constant] * VolumeFraction[i]^b
			else
				@inbounds kappa[i] = model.system[:conductivity_func](Concentration[i], Temperature[i]) * VolumeFraction[i]^b
			end
		end
	end
)

@jutul_secondary function update_diffusivity!(D, D_def::Diffusivity, model::ElectrolyteModel, Concentration, Temperature, VolumeFraction, BruggemanCoefficient, ix)
	""" Register diffusivity function
	"""

	for i in ix
		b = BruggemanCoefficient[i]
		if haskey(model.system.params, :diffusivity_data)

			@inbounds D[i] = model.system[:diffusivity_func](Concentration[i]) * VolumeFraction[i]^b

		elseif haskey(model.system.params, :diffusivity_constant)
			@inbounds D[i] = model.system[:diffusivity_constant] * VolumeFraction[i]^b

		else

			@inbounds D[i] = model.system[:diffusivity_func](Concentration[i], Temperature[i]) * VolumeFraction[i]^b
		end

	end

end

@jutul_secondary function update_chem_coef!(chemCoef, tv::ChemCoef, model::ElectrolyteModel, Conductivity, DmuDc, ix)
	"""Register constant for chemical flux
	"""
	sys = model.system
	t = transference(sys)
	F = FARADAY_CONSTANT
	for i in ix
		@inbounds chemCoef[i] = 1.0 / F * (1.0 - t) * Conductivity[i] * 2.0 * DmuDc[i]
	end
end


function computeFlux(::Val{:Charge}, model::ElectrolyteModel, state, cell, other_cell, face, face_sign)

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)

	j     = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Voltage, state.Conductivity)
	jchem = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Concentration, state.ChemCoef)

	j = j - jchem * (1.0)

	return j

end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T

	j = computeFlux(Val(:Charge), model, state, c, other, face, face_sign)

	return T(j)

end

""" 
   computeFlux(::Val{:Diffusion}, model::ElectrolyteModel, state, cell, other_cell, face, face_sign)

   Uses the (effective) diffusitivty coefficient and return  -D grad(c) , where D is effective diffusivity coefficient and Concentration in the concentration
# Arguments

- `model       ::ElectrolyteModel` : 
- `state`      : 
- `cell`       : 
- `other_cell` : 
- `face`       : 

# Returns
diffFlux
"""
function computeFlux(::Val{:Diffusion}, model::ElectrolyteModel, state, cell, other_cell, face, face_sign)

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)
	diffFlux = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Concentration, state.Diffusivity)

	return diffFlux

end

function computeFlux(::Val{:Mass}, model::ElectrolyteModel, state, cell, other_cell, face, face_sign)

	t = transference(model.system)
	z = 1.0
	F = FARADAY_CONSTANT

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)

	diffFlux = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Concentration, state.Diffusivity)
	j        = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Voltage, state.Conductivity)
	jchem    = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Concentration, state.ChemCoef)

	j = j - jchem * (1.0)

	massFlux = diffFlux + t / (z * F) * j

	return massFlux

end


function Jutul.face_flux!(q::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model::ElectrolyteModel, dt, flow_disc) where T

	massFlux = computeFlux(Val(:Mass), model, state, c, other, face, face_sign)

	return setindex(q, massFlux, 1)::T

end

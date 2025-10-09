export
	half_face_two_point_kgrad

function Jutul.declare_entities(G::MinimalTpfaGrid)
	# cells
	c = (entity = Cells(), count = length(G.volumes))
	# faces
	f = (entity = Faces(), count = size(G.neighborship, 2))
	# boundary faces
	bf = (entity = BoundaryDirichletFaces(), count = length(G.boundary_cells))
	return [c, f, bf]
end

@jutul_secondary function update_ion_mass!(acc,
	tv::Mass,
	model,
	ElectrolyteConcentration,
	Volume,
	VolumeFraction,
	ix)
	for i in ix
		@inbounds acc[i] = ElectrolyteConcentration[i] * Volume[i] * VolumeFraction[i]
	end
end

@jutul_secondary function update_as_secondary!(acc,
	tv::Charge,
	model,
	ElectricPotential,
	ix)
	for i in ix
		@inbounds acc[i] = 0.0
	end
end

#####################
# Gradient operator #
#####################


""" 
   harmonic_average(c1, c2, k)

Computes the harmonic average weighted with half-transmissibilities

# Arguments

- `c1` : first cell input, tuple with keys :cell (cell index) and :htrans (value of half-transmissibility)
- `c2` : second cell input, same format as `c1`
- `k`  : vector containing the value to be average

"""
@inline function harmonic_average(c1, c2, ht1, ht2, k)


	@inbounds l   = k[c1]
	@inbounds r   = k[c2]
	@inbounds htl = ht1
	@inbounds htr = ht2

	return 1.0 / (1.0 / (htl * l) + 1.0 / (htr * r))

end

@inline grad(c_self, c_other, p::AbstractArray) = @inbounds (p[c_other] - p[c_self])


@inline function half_face_two_point_kgrad(c_self,
	c_other,
	ht_self,
	ht_other,
	phi::AbstractArray,
	k::AbstractArray,
)

	k_av = harmonic_average(c_self, c_other, ht_self, ht_other, k)
	grad_phi = grad(c_self, c_other, phi)

	return k_av * grad_phi

end

function setupHalfTrans(model, face, cell, other_cell, face_sign)

	htrans = model.domain.representation[:halftransfaces][:, face]
	if face_sign > 0
		htrans_cell  = htrans[1]
		htrans_other = htrans[2]
	else
		htrans_cell  = htrans[2]
		htrans_other = htrans[1]
	end

	return (htrans_cell, htrans_other)

end


@inline function Jutul.face_flux!(q_i, face, eq::ConservationLaw, state, model::BattMoModel, dt, flow_disc::PotentialFlow, ldisc)

	# Inner version, for generic flux
	kgrad, upw = ldisc.face_disc(face)
	(; left, right, face_sign) = kgrad

	return Jutul.face_flux!(q_i, left, right, face, face_sign, eq, state, model, dt, flow_disc)

end

function computeFlux(::Val{:Mass}, model, state, cell, other_cell, face, face_sign)

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)
	q = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.ElectrolyteConcentration, state.Diffusivity)

	return q
end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Mass, <:Any}, state, model, dt, flow_disc) where T

	q = computeFlux(Val(:Mass), model, state, c, other, face, face_sign)

	return T(q)
end

function computeFlux(::Val{:Charge}, model, state, cell, other_cell, face, face_sign)

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)
	q = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.ElectricPotential, state.Conductivity)

	return q

end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Charge, <:Any}, state, model, dt, flow_disc) where T

	q = computeFlux(Val(:Charge), model, state, c, other, face, face_sign)
	return T(q)

end

function Jutul.face_flux!(::T, cell, other_cell, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model, dt, flow_disc) where T

	htrans_cell, htrans_other = setupHalfTrans(model, face, cell, other_cell, face_sign)
	q = -half_face_two_point_kgrad(cell, other_cell, htrans_cell, htrans_other, state.Temperature, state.Conductivity)

	return T(q)

end


export output_flux

function output_flux(model, state, parameters, eqname = :mass_conservation)

	n   = number_of_faces(model)
	N   = model.domain.representation.neighborship
	out = zeros(n)
	fd  = model.domain.discretizations.flow
	dt  = NaN

	state_t = convert_to_immutable_storage(merge(state, parameters))

	if haskey(model.equations, eqname)
		eq = model.equations[eqname]
		for i in eachindex(out)
			l = N[1, i]
			r = N[2, i]
			out[i] = Jutul.face_flux!(1.0, l, r, i, 1, eq, state_t, model, dt, fd)
		end
	else
		@. out = NaN
	end
	return out
end

####################
# Setup Parameters #
####################

function Jutul.select_parameters!(prm, D::MinimalTpfaGrid, model::BattMoModel)

	prm[:Volume]         = Volume()
	prm[:VolumeFraction] = VolumeFraction()

end

function Jutul.select_parameters!(prm, d::DataDomain, model::BattMoModel)
	prm[:Volume] = Volume()
end


#######################
# Boundary conditions #
#######################


function Jutul.apply_boundary_conditions!(storage, parameters, model::BattMoModel)
	equations_storage = storage.equations
	equations = model.equations
	for (eq, eq_s) in zip(values(equations), equations_storage)
		apply_bc_to_equation!(storage, parameters, model, eq, eq_s)
	end
end


function apply_bc_to_equation!(storage, parameters, model::BattMoModel, eq::ConservationLaw{:Charge}, eq_s)

	acc   = get_diagonal_entries(eq, eq_s)
	state = storage.state

	apply_boundary_potential!(acc, state, parameters, model, eq)

end

apply_bc_to_equation!(storage, parameters, model::BattMoModel, eq, eq_s) = nothing

function apply_boundary_potential!(acc, state, parameters, model::BattMoModel, eq::ConservationLaw{:Charge})

	dolegacy = false

	if model.domain.representation isa MinimalTpfaGrid
		bc = model.domain.representation.boundary_cells
		if length(bc) > 0
			dobc = true
		else
			dobc = false
		end
		dolegacy = true
	elseif Jutul.hasentity(model.domain, BoundaryDirichletFaces())
		nc = count_active_entities(model.domain, BoundaryDirichletFaces())
		dobc = nc > 0
		if dobc
			bcdirhalftrans = model.domain.representation[:bcDirHalfTrans]
			bcdircells     = model.domain.representation[:bcDirCells]
			bcdirinds      = model.domain.representation[:bcDirInds]
		end
	else
		dobc = false
	end

	if dobc

		ElectricPotential = state[:ElectricPotential]
		BoundaryVoltage = state[:BoundaryVoltage]
		conductivity = state[:Conductivity]

		if dolegacy
			T_hf = model.domain.representation.boundary_hfT
			for (i, c) in enumerate(bc)
				@inbounds acc[c] += conductivity[c] * T_hf[i] * (ElectricPotential[c] - value(BoundaryVoltage[i]))
			end
		else
			for (ht, c, i) in zip(bcdirhalftrans, bcdircells, bcdirinds)
				@inbounds acc[c] += conductivity[c] * ht * (ElectricPotential[c] - value(BoundaryVoltage[i]))
			end
		end
	end

end

apply_boundary_potential!(acc, state, parameters, model::BattMoModel, eq::ConservationLaw) = nothing

function setupHalfTransFaces(domain)

	g = domain.representation
	neighbors = get_neighborship(g)

	d = domain

	cells = d[:half_face_cells]
	faces = d[:half_face_faces]

	pos = []
	for (cell, face) in zip(cells, faces)
		if neighbors[1, face] == cell
			push!(pos, 1)
		else
			push!(pos, 2)
		end
	end

	A = hcat(faces, pos, cells)

	ind = sortperm(eachrow(A))

	hT = d[:halfTrans]
	hT = hT[ind]
	hT = reshape(hT, (2, :))

	return hT

end


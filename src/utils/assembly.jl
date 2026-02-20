export compute_flux_vector

function get_energy_source!(thermal_model::ThermalModel, model::IntercalationBattery, state, maps, operators = setup_flux_operators(model))
    
	multimodel = model.multimodel

	nc = number_of_cells(thermal_model.domain)
	src = zeros(Float64, nc)

	components_ = ["NegativeElectrodeActiveMaterial",
                   "PositiveElectrodeActiveMaterial",
				   "Electrolyte"]

    if include_current_collectors(multimodel)

        components_ = vcat(components_,
        	               ["NegativeElectrodeCurrentCollector",
        	                "PositiveElectrodeCurrentCollector"])
    end

    components = map(components_) do component Symbol(component) end

    symb2str = Dict(zip(components, components_)) # map from symbol tro string
    
	sources = Dict()

	for component in components

		map = maps[symb2str[component]][1][:cellmap]
		comp_src = get_energy_source(multimodel[component],
			                         state[component],
			                         operators[component])

		src[map] .+= comp_src

		sources[component] = fill(NaN, nc)
		sources[component][map] = comp_src

	end

    cross_terms = filter(model.multimodel.cross_terms) do c
        isa(c.cross_term,  ButlerVolmerActmatToElyteCT) && c.target_equation == :charge_conservation
    end

    for cross_term in cross_terms
        reaction_src = get_reaction_energy_source(cross_term, multimodel, state)
        map = maps[symb2str[cross_term.source]][1][:cellmap]
        src[map] .+= reaction_src
    end
    
	return src, sources

end

function get_reaction_energy_source(cross_term, models, state)

    elde_cells = cross_term.cross_term.source_cells
    elyte_cells = cross_term.cross_term.target_cells

    elde  = cross_term.source    
    elyte = cross_term.target

    activematerial = models[elde].system
    
	phi_e    = state[elyte][:ElectricPotential][elyte_cells]
	phi_a    = state[elde][:ElectricPotential][elde_cells]
	ocp      = state[elde][:OpenCircuitPotential][elde_cells]
	R0       = state[elde][:ReactionRateConstant][elde_cells]
	c_e      = state[elyte][:ElectrolyteConcentration][elyte_cells]
	c_a_surf = state[elde][:SurfaceConcentration][elde_cells]
	T        = state[elde][:Temperature][elde_cells]

    if activematerial.params[:include_entropy_change]
        dUdT = state[elde][:EntropyChange]
    end
    
    vols = models[elde].data_domain[:volumes]

	eta = phi_a - phi_e - ocp

    src = similar(eta)

    F   = FARADAY_CONSTANT
	n   = activematerial.params[:n_charge_carriers]
	vsa = activematerial.params[:volumetric_surface_area]

    for i in eachindex(src)
        
	    R = reaction_rate(eta[i],
			              c_a_surf[i],
			              R0[i],
			              T[i],
			              c_e[i],
			              activematerial,
			              models[elyte].system)
        if activematerial.params[:include_entropy_change]
            R = R*(eta[i] + T[i]*dUdT[i])
        else
            R = R*eta[i]
        end
        src[i] = n*F*vols[i]*vsa*R
        
    end

    return src
    
end

function get_energy_source(model::ElectrolyteModel, state, operators)

	vols = state[:Volume]

	# Ohmic flux

	kappa = state[:Conductivity] # Effective conductivity

	fluxvec = compute_flux_vector(model, state, operators)
	fluxnorm = transpose(sum(fluxvec .^ 2; dims = 1))

	src = fluxnorm .* vols ./ kappa

	# Diffusion flux

	D     = state[:Diffusivity] # Effective diffusivity
	dmudc = state[:DmuDc] # Effective diffusivity

	fluxvec = compute_flux_vector(model, state, operators, fieldname = :Diffusion)
	fluxnorm = transpose(sum(fluxvec .^ 2; dims = 1))

	src .+= dmudc .* fluxnorm .* vols ./ D

	return src

end



function get_energy_source(model::ActiveMaterialModel, state, operators)

	vols  = state[:Volume]
	kappa = state[:Conductivity] # Effective conductivity

	# Ohmic flux

	fluxvec = compute_flux_vector(model, state, operators)
	fluxnorm = transpose(sum(fluxvec .^ 2; dims = 1))

	src = fluxnorm .* vols ./ kappa

	return src

end

function get_energy_source(model::CurrentCollectorModel, state, operators)

	vols  = state[:Volume]
	kappa = state[:Conductivity]

	# Ohmic flux

	fluxvec = compute_flux_vector(model, state, operators)
	fluxnorm = transpose(sum(fluxvec .^ 2; dims = 1))

	src = fluxnorm .* vols ./ kappa

	return src

end

"""
   get_state_with_secondary_variables(model, state, parameters)

Compute and add to the state variables all the secondary variables

# Arguments

- `model`      :
- `state`      :

# Returns

state : state with the added secondary variables

"""
function get_state_with_secondary_variables(model, state, parameters)

	storage = Jutul.setup_storage(model;
		setup_linearized_system = false,
		setup_equations         = false,
		state0                  = state,
		parameters              = parameters,
		state_ad                = false)

	storage = convert_to_immutable_storage(storage)
	Jutul.update_secondary_variables!(storage, model)

	state = storage[:state]

	return state

end

"""
   compute_flux_vector(model, state, operators; fieldname = :Charge)

For a given model and state, compute the reconstruction of the flux vector at each cell from the integrated flux value
at the faces (which we typically simply call flux)

# Arguments

- `model`              : simulation model
- `state`              : state variable
						 All the secondary variables that are needed to compute the flux should be present there.
						 To add those, you can use the `get_state_with_secondary_variables` function
- `operators`          : list of local matrices that are used to compute the flux vector from face integrated values,
						 see `setup_flux_operator
- `fieldname = :Charge`: Name of the flux that is computed, which corresponds to the name of the equation where this flux is primarily intended to be used,
						 see the function `compute_flux` and their specializations

# Returns

- fluxVector : Flux vector of size dim x ncells, where dim is the spatial dimension and ncells is the number of discretization cells

"""
function compute_flux_vector(model, state, operators; fieldname = :Charge)

	domain = model.domain.representation

	g = domain.representation

	cfmap     = g.faces.cells_to_faces
	neighbors = g.faces.neighbors

	nc = Jutul.number_of_cells(g)

	fluxVector = Array{Float64}(undef, 3, nc)

	for cell in 1:nc

		cface_inds = cfmap.pos[cell]:(cfmap.pos[cell+1]-1)
		cface_inds = cfmap.vals[cface_inds]

		localflux = Vector{Float64}(undef, length(cface_inds))

		for (iloc, iface) in enumerate(cface_inds)
			if cell == neighbors[iface][1]
				other_cell = neighbors[iface][2]
				face_sign = 1
			else
				other_cell = neighbors[iface][1]
				face_sign = 2
			end

			localflux[iloc] = compute_flux(Val(fieldname), model, state, cell, other_cell, iface, face_sign)

		end

		op = operators[cell]

		fluxVector[:, cell] = op*localflux

	end

	return fluxVector

end


function setup_flux_operators(model::IntercalationBattery)

	models = model.multimodel.models

	components = [:NegativeElectrodeActiveMaterial,
                  :PositiveElectrodeActiveMaterial,
				  :Electrolyte]

    if include_current_collectors(model.multimodel)

        components = vcat(components,
        	              [:NegativeElectrodeCurrentCollector,
        	              :PositiveElectrodeCurrentCollector])
    end

	operators = Dict()

	for name in keys(models)
		submodel = models[name]
		if name in components
			operators[name] = setup_flux_operator(submodel.domain.representation)
		end
	end

	return operators

end

"""
	setup_flux_operator(domain::DataDomain{R, <:Any, <:Any}) where {R <: UnstructuredMesh}

Assemble the list of the operators, one per cell. For a given cell the operator maps the integrated flux on each face
(called only flux in rest of code) to the flux vector in the cell, see setup_flux_operator(normals::AbstractVector, flux::AbstractVector) 


# Arguments
- `domain`: data domain which contains the mesh of type UnstructuredMesh

# Returns
- List of flux operators, one per cell
"""
function setup_flux_operator(domain::DataDomain{R, <:Any, <:Any}) where {R <: UnstructuredMesh}

	g = domain.representation
	# IndirectionMap
	cfmap     = g.faces.cells_to_faces
	neighbors = g.faces.neighbors

	nc = Jutul.number_of_cells(g)

	# normals array (size dim x nf)
	normals = domain[:normals]
	areas   = domain[:areas]

	operator = []

	for ic in 1:nc

		cface_inds = cfmap.pos[ic]:(cfmap.pos[ic+1]-1)
		cface_inds = cfmap.vals[cface_inds]

		cnormals = normals[:, cface_inds]
		for (iloc, iface) in enumerate(cface_inds)
			if ic == neighbors[iface][1]
				sgn = 1
			else
				sgn = -1
			end
			cnormals[:, iloc] = sgn*areas[iface]*cnormals[:, iloc]
		end

		locoperator = setup_flux_operator(cnormals)

		push!(operator, locoperator)

	end

	return operator

end

"""
	setup_flux_operator(normals::AbstractVector, flux::AbstractVector)

Assemble an operator that maps the integrated flux on each face (called only flux in rest of code) to the flux vector in the cell

We use a least square method for the reconstruction

# Arguments
- `normals`: Array with the normals (size dim x nf, where nf is the number of faces of the cell and dim is the spatial dimention)

# Returns
- Flux operator, matrix of size (dim x nf)
"""
function setup_flux_operator(normals::AbstractArray)

	return inv(normals*transpose(normals))*normals

end

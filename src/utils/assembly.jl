export computeFluxVector

function getEnergySource!(thermal_model::ThermalModel, model::BatteryModel, state, maps, operators = setupFluxOperators(model))

    nc = number_of_cells(thermal_model.domain)
    src = zeros(Float64, nc)

    # names of component versus names in maps (since they do not match... should be fixed for the sake of simplicity)
    mapnames = (Elyte = "Electrolyte"             ,
                NeCc  = "NegativeCurrentCollector",
                PeAm  = "PositiveElectrode"       ,
                PeCc  = "PositiveCurrentCollector",
                NeAm  = "NegativeElectrode")

    if include_current_collectors(model)
        components = (:NeCc, :NeAm, :Elyte, :PeAm, :PeCc)
    else
        components = (:NeAm, :Elyte, :PeAm)
    end

    for component in components

        addEnergySource!(src                 ,
                         model[component]    ,
                         state[component]    ,
                         operators[component],
                         maps[mapnames[component]])

    end

    return src

end

function addEnergySource!(src, model::ElectrolyteModel, state, operators, maps)

    map = maps[:cellmap]

    vols = state[:Volume]
    
    # Ohmic flux

    kappa = state[:Conductivity] # Effective conductivity
    
    fluxvec = computeFluxVector(model, state, operators)
    fluxnorm = transpose(sum(fluxvec.^2; dims = 1))

    src[map] .+= fluxnorm.*vols./kappa

    # Diffusion flux
    
    D     = state[:Diffusivity] # Effective diffusivity
    dmudc = state[:DmuDc] # Effective diffusivity
    
    fluxvec = computeFluxVector(model, state, operators, fieldname = :Diffusion)
    fluxnorm = transpose(sum(fluxvec.^2; dims = 1))

    src[map] .+= dmudc.*fluxnorm.*vols./D

end

function addEnergySource!(src, model::ActiveMaterialModel, state, operators, maps)

    map = maps[:cellmap]

    vols  = state[:Volume]
    kappa = state[:Conductivity] # Effective conductivity
    
    # Ohmic flux

    fluxvec = computeFluxVector(model, state, operators)
    fluxnorm = transpose(sum(fluxvec.^2; dims = 1))

    src[map] .+= fluxnorm.*vols./kappa
    
end

function addEnergySource!(src, model::CurrentCollectorModel, state, operators, maps)

    map = maps[:cellmap]

    vols  = state[:Volume]
    kappa = state[:Conductivity]
    
    # Ohmic flux

    fluxvec = computeFluxVector(model, state, operators)
    fluxnorm = transpose(sum(fluxvec.^2; dims = 1))

    src[map] .+= fluxnorm.*vols./kappa

end

"""
   getStateWithSecondaryVariables(model, state, parameters)

Compute and add to the state variables all the secondary variables

# Arguments

- `model`      :
- `state`      :

# Returns

state : state with the added secondary variables

"""
function getStateWithSecondaryVariables(model, state, parameters)

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
   computeFluxVector(model, state, operators; fieldname = :Charge)

For a given model and state, compute the reconstruction of the flux vector at each cell from the integrated flux value
at the faces (which we typically simply call flux)

# Arguments

- `model`              : simulation model
- `state`              : state variable
                         All the secondary variables that are needed to compute the flux should be present there.
                         To add those, you can use the `getStateWithSecondaryVariables` function
- `operators`          : list of local matrices that are used to compute the flux vector from face integratedvalues,
                         see `setupFluxOperator
- `fieldname = :Charge`: Name of the flux that is computed, which corresponds to the name of the equation where this flux is primarily intended to be used,
                         see the function `computeFlux` and their specializations

# Returns

- fluxVector : Flux vector of size dim x ncells, where dim is the spatial dimension and ncells is the number of discretization cells

"""
function computeFluxVector(model, state, operators; fieldname = :Charge)

    domain = model.domain.representation

    g = domain.representation

    cfmap     = g.faces.cells_to_faces
    neighbors = g.faces.neighbors

    nc = Jutul.number_of_cells(g)

    fluxVector = Array{Float64}(undef, 3, nc)

    for cell in 1 : nc

        cface_inds = cfmap.pos[cell] : (cfmap.pos[cell + 1] - 1)
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

            localflux[iloc] = computeFlux(Val(fieldname), model, state, cell, other_cell, iface)

        end

        op = operators[cell]

        fluxVector[:, cell] = op*localflux

    end

    return fluxVector

end

function setupFluxOperators(model::BatteryModel)

    models = model.models

    operators = Dict()

    for name in keys(models)
        submodel = models[name]
        if name in [:NeCc, :NeAm, :Elyte, :PeAm, :PeCc]
            operators[name] = setupFluxOperator(submodel.domain.representation)
        end
    end

    return operators
    
end

function setupFluxOperator(domain::DataDomain{R, <:Any, <:Any}) where {R <: UnstructuredMesh}

    g = domain.representation
    # IndirectionMap
    cfmap     = g.faces.cells_to_faces
    neighbors = g.faces.neighbors

    nc = Jutul.number_of_cells(g)

    # normals array (size dim x nf)
    normals = domain[:normals]
    areas   = domain[:areas]

    operator = []

    for ic in 1 : nc

        cface_inds = cfmap.pos[ic] : (cfmap.pos[ic + 1] - 1)
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

        locoperator = setupFluxOperator(cnormals)

        push!(operator, locoperator)

    end

    return operator

end

"""
    setupFluxOperator(normals::AbstractVector, flux::AbstractVector)

Assemble an operator that maps the integrated flux on each face (called only flux in rest of code) to the flux vector in the cell

We use a least square method for the reconstruction

# Arguments
- `normals`: Array with the normals (size dim x nf, where nf is the number of faces of the cell and dim is the spatial dimention)

# Returns
- Flux operator, matrix of size (dim x nf)
"""
function setupFluxOperator(normals::AbstractArray)

    return inv(normals*transpose(normals))*normals

end

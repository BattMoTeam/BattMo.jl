function setupFluxOperator(domain::DataDomain{R, <:Any, <:Any}) where {R <: UnstructuredMesh}
    
    g = domain.representation
    # IndirectionMap
    cfmap     = g.faces.cells_to_faces 
    neighbors = g.faces.neighbors
    
    nc = Jutul.number_of_cells(g)
    nf = Jutul.number_of_faces(g)

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

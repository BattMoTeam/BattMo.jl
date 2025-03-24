
using Jutul: JutulMesh

export convert_geometry

# struct MrstMesh{V, N, B, BT, M} <: JutulMesh
#     """
#     Simple grid for a electro chemical component
#     """
#     neighborship::N
#     boundary_cells::B # indices of the boundary cells (some can can be repeated if a cell has two boundary faces). Same length as boundary_hfT.
#     boundary_hfT::BT # Boundary half face transmissibilities
#     P::M # Tensor to map from cells to faces
#     S::M # Tensor map cell vector to cell scalar
#     vol_frac::V
#     trans::V
#     function MrstMesh(pv, N, T; bc_cells = [], bc_hfT = [], P = [], S = [], vf = [])
#         nc = length(pv)
#         pv::AbstractVector
#         @assert size(N, 1) == 2
#         if length(N) > 0
#             @assert minimum(N) > 0
#             @assert maximum(N) <= nc
#         end
#         @assert all(pv .> 0)
#         @assert size(bc_cells) == size(bc_hfT)
#         if isempty(vf)
#             vf = 1
#         end
#         if length(vf) != nc
#             vf = vf*ones(nc)
#         end
#         new{typeof(pv), typeof(N), typeof(bc_cells), typeof(bc_hfT), typeof(P)}(pv, N,T, bc_cells, bc_hfT, P, S, vf)
#     end
# end

# number_of_cells(G::MrstMesh) = length(G.volumes)

# Base.show(io::IO, g::MrstMesh) = print(io, "MrstMesh ($(number_of_cells(g)) cells, $(number_of_faces(g)) faces)")


"""
 Convert the grids given in MRST format (given as dictionnaries, also called raw grids) to Jutul format (UnstructuredMesh)
 In particular, for the external face couplings, we need to recover the coupling face indices in the boundary face indexing (jutul mesh structure holds a different indexing for the boundary faces)
"""
function convert_geometry(grids, couplings; include_current_collectors = true)

    if include_current_collectors
        components = ["NegativeCurrentCollector",
                      "NegativeElectrode"       ,
                      "Separator"               ,
                      "PositiveElectrode"       ,
                      "PositiveCurrentCollector",
                      "Electrolyte"]
    else
        components = ["NegativeElectrode"       ,
                      "Separator"               ,
                      "PositiveElectrode"       ,
                      "Electrolyte"]
    end

    ugrids = Dict()

    for component in components
        ugrids[component] = UnstructuredMesh(grids[component])
    end

    ucouplings = deepcopy(couplings)

    for component in components

        component_couplings = ucouplings[component]

        grid  = grids[component]
        ugrid = ugrids[component]

        for (other_component, coupling) in component_couplings

            if !isempty(coupling)

                if coupling["face_type"]

                    faces = coupling["faces"]
                    cells = coupling["cells"]

                    for fi in eachindex(faces)

                        face = faces[fi]
                        cell = cells[fi]

                        candidates = ugrid.boundary_faces.cells_to_faces[cell]
                        rface = face
                        rawfaces = grid["faces"]
                        lnodePos = rawfaces["nodePos"][rface : (rface + 1)]
                        lnodes = Set(rawfaces["nodes"][lnodePos[1] : lnodePos[2] - 1])
                        count = 0

                        for lfi in eachindex(candidates)
                            fnodes = Set(ugrid.boundary_faces.faces_to_nodes[candidates[lfi]])
                            if fnodes == lnodes
                                faces[fi] = candidates[lfi]
                                count += 1
                            end
                        end
                        @assert count == 1
                    end
                else
                    @assert isempty(coupling["faces"])
                end
            end
        end
    end

    if haskey(grids, "Global")
        ugrids["Global"] = UnstructuredMesh(grids["Global"])
    end
    
    return ugrids, ucouplings

end
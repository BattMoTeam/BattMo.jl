using BattMo, Jutul, GLMakie

function getinput(name)
    return read_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
end

# load geometry parameters
inputparams_geometry = getinput("4680-geometry.json")
# load material parameters
inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
# load control parameters
inputparams_control = getinput("cc_discharge_control.json")

inputparams = merge_input_params([inputparams_geometry, inputparams_material, inputparams_control])

geometry = inputparams["Geometry"]

nangles = geometry["numberOfDiscretizationCellsAngular"]
nz      = geometry["numberOfDiscretizationCellsVertical"]
rinner  = geometry["innerRadius"]
router  = geometry["outerRadius"] 
height  = geometry["height"] 

function get_vector(inputparams, fdname)

    v = [inputparams["NegativeElectrode"]["CurrentCollector"][fdname],
         inputparams["NegativeElectrode"]["Coating"][fdname],
         inputparams["Separator"][fdname],
         inputparams["NegativeElectrode"]["Coating"][fdname],
         inputparams["NegativeElectrode"]["CurrentCollector"][fdname]]
    return v
end

Ns = get_vector(inputparams, "N")
dxs = get_vector(inputparams, "thickness")

dx = mapreduce((dx, N) -> repeat([dx], N), vcat, dxs, Ns)

spacing = [0; cumsum(dx)]
spacing = spacing/spacing[end]

thickness = sum(dxs)

depths = [0; cumsum(repeat([height/nz], nz))]

spacingtags = Dict()
spacingtags[:NeCc]  = collect(1 : Ns[1])
spacingtags[:NeAm]  = Ns[1] .+ collect(1 : Ns[2])
spacingtags[:Elyte] = Ns[1] .+ collect(1 : sum(Ns[2 : 4]))
spacingtags[:PeAm]  = sum(Ns[1 : 3]) .+ collect(1 : Ns[4])
spacingtags[:PeCc]  = sum(Ns[1 : 4]) .+ collect(1 : Ns[5])

C = rinner
A = thickness/2*pi

nrot = Int(round((router - rinner)/(2*pi*A)))

g2d = Jutul.RadialMeshes.spiral_mesh(nangles, nrot; spacing = spacing, A = A, C = C)

g3d = Jutul.extrude_mesh(g2d, depths)

tags = Jutul.RadialMeshes.spiral_mesh_tags(g3d, spacing)

elyte_cells = findall(x -> x in spacingtags[:NeAm], tags[:spacing])

elyte_g3d = Jutul.extract_submesh(g3d, elyte_cells)

fig, ax, plt = plot_mesh(elyte_g3d)
Jutul.plot_mesh_edges_impl!(ax, elyte_g3d)

fig

if false
    
    # We compute the arguments of spiral_mesh, nrot, A and C as function of router, rinner, thickness

    # Depths must be in increasing order

    tags = Jutul.RadialMeshes.spiral_mesh_tags(g3d, spacing)

    function top_and_bottom_tags(g)
        top = Int[]
        bottom = Int[]
        geo = tpfv_geometry(g)
        for bf in 1:number_of_boundary_faces(g)
            N = geo.boundary_normals[:, bf]
            cell = g.boundary_faces.neighbors[bf]
            Nz = N[3]
            if abs(N[1]) + abs(N[2]) < 0.01*abs(Nz)
                if Nz > 0
                    push!(top, bf)
                else
                    push!(bottom, bf)
                end
            end
        end
        return (top, bottom)
    end

    tf, bf = top_and_bottom_tags(g3d)

    fig, ax, plt = plot_cell_data(g3d, tags[:spacing])
    plot_mesh!(ax, g3d, boundaryfaces = tf, color = :red, alpha = 0.5)
    plot_mesh!(ax, g3d, boundaryfaces = bf, color = :blue, alpha = 0.5)
    fig
    
end

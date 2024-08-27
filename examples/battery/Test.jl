using Jutul, BattMo, Plots, GLMakie
using StatsBase

function plot_grid_test(G)
    fig, ax = plot_mesh(G)
    Jutul.plot_mesh_edges!(ax, G)
end;


function find_tags(h, paramsz_z)
    h_with_geo = tpfv_geometry(h)
    cut_offs = cumsum(paramsz_z)
    tag = searchsortedfirst.([cut_offs], h_with_geo.cell_centroids[3,:])
    return [findall(x -> x == i,tag) for i in 1:5]
end;



function basic_grid_example_p4d2()
    # just defining some values. feel free to change them. 
    #these values are taken from picture 
    #https://battmoteam.github.io/BattMo/geometryinput.html#batterygeneratorp4d
        
    ne_cc_nx = 3
    int_elyte_nx = 4
    pe_cc_nx = 3
    
    ne_cc_ny = 3
    elyte_ny = 10
    pe_cc_ny = 3

    ne_cc_nz = 2
    ne_am_nz = 3
    sep_nz = 3
    pe_am_nz = 3
    pe_cc_nz = 2
    
    x0_cells, x4_cells = 1, 1 ### These can be 0 => CC is on edge
    x0, x4 = 6, 6

    x = [x0, 4, 2, 4, x4] .* 1e-2 
    y = [2, 20, 2] .* 1e-3
    z = [10, 100, 50, 80, 10] .* 1e-6
    
    
    paramsx = [x0_cells, ne_cc_nx, int_elyte_nx, pe_cc_nx, x4_cells]
    paramsy = [ne_cc_ny, elyte_ny, pe_cc_ny]
    paramsz = [ne_cc_nz, ne_am_nz, sep_nz, pe_am_nz, pe_cc_nz]

    same_side = false # if true, needs pe_cc_ny >= ne_cc_ny. I think they usually are equal
    strip = true

    Lx = StatsBase.inverse_rle(x, paramsx)
    Ly = StatsBase.inverse_rle(y, paramsy)
    Lz = StatsBase.inverse_rle(z, paramsz)
    
    Nx = length(Lx)
    Ny = length(Ly)
    Nz = length(Lz)
    
    h = CartesianMesh((Nx, Ny, Nz), (Lx, Ly, Lz))
    H_back = convert_to_mrst_grid(UnstructuredMesh(h));
    
    #################################################################
    
    list_of_iterators = [Nx * (i * Ny - pe_cc_ny)  + 1 : Nx * Ny * i for i in 1:Nz]
    cells1 = cat(list_of_iterators..., dims = 1)
    
    index_of_pcc = cat([Nx * i - pe_cc_nx + 1 : Nx * i for i in 1:pe_cc_ny]..., dims = 1)
    add_cells_pcc = cat(getindex.(list_of_iterators[end - pe_cc_nz + 1:end], [index_of_pcc .- x4_cells])..., dims = 1)
    
    setdiff!(cells1, add_cells_pcc)
    
    list_of_iterators2 = [Nx * Ny * (i-1)  + 1 : Nx * (Ny * (i-1) + ne_cc_ny) for i in 1:Nz]
    cells2 = cat(list_of_iterators2..., dims = 1)
    
    index_of_ncc = cat([Nx * (i - 1) + 1 : Nx * (i - 1) + ne_cc_nx for i in 1:ne_cc_ny]..., dims = 1)
    
    if same_side
        add_cells_ncc = cat(getindex.(list_of_iterators[1:ne_cc_nz], [index_of_ncc .+ x0_cells])..., dims = 1)
        setdiff!(cells1, add_cells_ncc)
    else
        add_cells_ncc = cat(getindex.(list_of_iterators2[1:ne_cc_nz], [index_of_ncc .+ x0_cells])..., dims = 1)
        setdiff!(cells2, add_cells_ncc)
    end
    
    return remove_cells(H_back, vcat(cells1, cells2))

end;
    
H_mother, maps... = basic_grid_example_p4d2()
plot_grid_test(UnstructuredMesh(H_mother))

paramsz =  [2, 3, 3, 3, 2] .* [10, 100, 50, 80, 10] .* 1e-6



begin
    tags = find_tags(UnstructuredMesh(H_mother), paramsz)

    G_NCC, maps_NCC... = remove_cells(H_mother, setdiff(1:1836, tags[1]))
    G_NAM, maps_NAM... = remove_cells(H_mother, setdiff(1:1836, tags[2]))
    G_SEP, maps_SEP... = remove_cells(H_mother, setdiff(1:1836, tags[3])) #ikke helt riktig
    G_PAM, maps_PAM... = remove_cells(H_mother, setdiff(1:1836, tags[4]))
    G_PCC, maps_PCC... = remove_cells(H_mother, setdiff(1:1836, tags[5]))

    G_EL, maps_EL... = remove_cells(H_mother, setdiff(1:1836, vcat(tags[2:4]...)))
end;











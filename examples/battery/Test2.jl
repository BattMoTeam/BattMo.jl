using Jutul, BattMo, Plots, GLMakie
using StatsBase

function plot_grid_test(G)
    fig, ax = plot_mesh(G)
    Jutul.plot_mesh_edges!(ax, G)
end;

function basic_grid_example_p4d()
# just defining some values. feel free to change them. 
#these values are taken from picture 
    #https://battmoteam.github.io/BattMo/geometryinput.html#batterygeneratorp4d
    
    ne_cc_nx = 3
    int_elyte_nx = 4
    pe_cc_nx = 3
    
    ne_cc_ny = 3
    elyte_ny = 10
    pe_cc_ny = 3

    pe_cc_nz = 2
    pe_am_nz = 3
    sep_nz = 3
    ne_am_nz = 3
    ne_cc_nz = 2
    
    x = [4, 2, 4] .* 1e-2
    y = [1, 20, 1] .* 1e-3
    z = [10, 100, 50, 80, 10] .* 1e-6
    
    Lx = StatsBase.inverse_rle(x, [ne_cc_nx, int_elyte_nx, pe_cc_nx])
    Ly = StatsBase.inverse_rle(y, [ne_cc_ny, elyte_ny, pe_cc_ny])
    Lz = StatsBase.inverse_rle(z, [pe_cc_nz, pe_am_nz, sep_nz, ne_am_nz, ne_cc_nz])
    
    Nx = length(Lx)
    Ny = length(Ly)
    Nz = length(Lz)
    
    h = CartesianMesh((Nx, Ny, Nz), (Lx, Ly, Lz))
    H_back = back_converter(UnstructuredMesh(h));

    #################################################################

    list_of_iterators = [Nx * (i * Ny - pe_cc_ny)  + 1 : Nx * Ny * i for i in 1:Nz]
    cells1 = cat(list_of_iterators..., dims = 1)
    
    index_of_pcc = cat([Nx * i - pe_cc_nx + 1 : Nx * i for i in 1:pe_cc_ny]..., dims = 1)
    add_cells_pcc = cat(getindex.(list_of_iterators[end - pe_cc_nz + 1:end], [index_of_pcc])..., dims = 1)
    
    setdiff!(cells1, add_cells_pcc)
    
    list_of_iterators2 = [Nx * Ny * (i-1)  + 1 : Nx * (Ny * (i-1) + ne_cc_ny) for i in 1:Nz]
    cells2 = cat(list_of_iterators2..., dims = 1)
    
    index_of_ncc = cat([Nx * (i - 1) + 1 : Nx * (i - 1) + ne_cc_nx for i in 1:ne_cc_ny]..., dims = 1)
    add_cells_ncc = cat(getindex.(list_of_iterators2[1:pe_cc_nz], [index_of_ncc])..., dims = 1)
    
    setdiff!(cells2, add_cells_ncc)
    
    H_back_removed,  = remove_cells(H_back, vcat(cells1, cells2));

    plot_grid_test(UnstructuredMesh(H_back_removed))
end;

basic_grid_example_p4d()






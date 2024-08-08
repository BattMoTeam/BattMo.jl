using Jutul, BattMo, Plots, GLMakie

function plot_grid_test(G)
    fig, ax = plot_mesh(G)
    Jutul.plot_mesh_edges!(ax, G)
end;

begin
    Nx, Ny = 10, 10;
    Lx, Ly = 2., 2.;
    dN = (4, 12, 4);
    dx = (.4, 1.2, .4);
    
    N = (Nx, Ny, sum(dN));
    L = (Lx, Ly, sum(dx));
    
    G = UnstructuredMesh(CartesianMesh(N, L));
    G_back = back_converter(G);
end;

# Her skal jeg remove
num_of_cells = G_back["cells"]["num"]
#disse gjelder kun for min case
cells_PAM = setdiff(collect(1:num_of_cells), collect(1:400))
cells_SEP = setdiff(collect(1:num_of_cells), collect(401:1600))
cells_NAM = setdiff(collect(1:num_of_cells), collect(1601:2000))


G_PAM, maps_PAM... = remove_cells(G_back, cells_PAM);
G_SEP, maps_SEP... = remove_cells(G_back, cells_SEP);
G_NAM, maps_NAM... = remove_cells(G_back, cells_NAM);



plot_grid_test(UnstructuredMesh(G_PAM))
plot_grid_test(UnstructuredMesh(G_SEP))
plot_grid_test(UnstructuredMesh(G_NAM))






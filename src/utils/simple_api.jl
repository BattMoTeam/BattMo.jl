export extract_time_series
export get_simple_coords
export extract_spatial_data
export get_model_coords
export get_all_coords

function extract_time_series(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})
    
    states = output[:states]
    
    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]
    
    time_series = Dict("time" => t, "voltage" => E, "current" => I)
    
    return time_series

end


function get_model_coords(model_part::SimulationModel)
    # Get the grid wrap for the model part
    grid_wrap = physical_representation(model_part);
    
    # Extract the centroids of the cells and boundaries
    centroids_cells = grid_wrap[:cell_centroids, Cells()];
    centroids_boundaries = grid_wrap[:boundary_centroids, BoundaryFaces()];


    # Return the coordinates as a tuple
    cell_centroids = (x=centroids_cells[1, :], y=centroids_cells[2, :], z=centroids_cells[3, :]);
    face_centroids = (x=centroids_boundaries[1, :], y=centroids_boundaries[2, :], z=centroids_boundaries[3, :]);

    return (cells = cell_centroids, faces = face_centroids)

end



function get_all_coords(model::MultiModel{:Battery})

    # TODO get this to loop through all the models in the multi model
    Ne_grid = get_model_coords(model[:NeAm]);
    Pe_grid = get_model_coords(model[:PeAm]);
    Elyte_grid = get_model_coords(model[:Elyte]);


    return (Ne = Ne_grid, Pe = Pe_grid, Elyte = Elyte_grid)

end


function extract_spatial_data(output::NamedTuple{(:states, :cellSpecifications, :reports, :inputparams, :extra)})
    
    states = output[:states]
    x = [state[:]]
    return spatial
    
end



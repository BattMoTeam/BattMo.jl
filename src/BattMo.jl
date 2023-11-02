module BattMo
using PrecompileTools
using StaticArrays

import JSON
import Jutul:
    number_of_cells, number_of_faces,
    degrees_of_freedom_per_entity,
    values_per_entity,
    absolute_increment_limit,
    relative_increment_limit,
    maximum_value,
    minimum_value,
    select_primary_variables!,
    select_parameters!,
    initialize_primary_variable_ad!,
    update_primary_variable!,
    select_secondary_variables!,
    default_value,
    initialize_variable_ad!,
    update_half_face_flux!,
    update_accumulation!,
    update_equation!,
    update_equation_in_entity!,
    select_equations!,
    setup_parameters,
    count_entities,
    count_active_entities,
    associated_entity,
    active_entities,
    number_of_entities,
    declare_entities,
    get_neighborship,
    Faces,
    align_to_jacobian!,
    diagonal_alignment!,
    half_face_flux_cells_alignment!,
    update_cross_term!,
    get_entry,
    get_jacobian_pos,
    DiagonalEquation,
    fill_equation_entries!,
    update_linearized_system_equation!,
    check_convergence,
    update!,
    linear_operator,
    transfer,
    operator_nrows,
    matrix_layout,
    apply!,
    apply_forces_to_equation!,
    convergence_criterion,
    get_dependencies,
    setup_forces,
    setup_state,
    setup_state!,
    declare_pattern,
    select_minimum_output_variables!,
    physical_representation

include("physical_constants.jl")
include("battery_types.jl")
include("tensor_tools.jl")
include("battery_utils.jl")
include("models/elyte.jl")
include("models/current_collector.jl")
include("models/ocp.jl")
include("models/activematerial.jl")

include("function_input_tools.jl")
include("models/current_and_voltage_boundary.jl")
include("models/battery_cross_terms.jl") # Works now
include("models/convergence.jl")
include("physics.jl")
include("types.jl")
include("mrst_test_utils.jl")
include("linsolve.jl")

# Precompilation of solver. Run a small battery simulation to precompile everything.
@compile_workload begin
   for use_general_ad in [false, true]
        init = "p2d_40"
        run_battery(init; general_ad = use_general_ad,info_level = -1);
   end
end

end # module

module BattMo
    greet() = print("Hello World!")
    function f()
        return 1
    end
    import JutulDarcy
    #import Jutul:select_equations_system!
    import Jutul: number_of_cells, number_of_faces,
    degrees_of_freedom_per_entity,
    values_per_entity,
    absolute_increment_limit, relative_increment_limit, maximum_value, minimum_value,
    select_primary_variables!,
    initialize_primary_variable_ad!,
    update_primary_variable!,
    select_secondary_variables!,
    update_secondary_variable!,
    default_value,
    initialize_variable_value!,
    initialize_variable_ad,
    update_half_face_flux!,
    update_accumulation!,
    update_equation!,
    minimum_output_variables,
    select_equations!,
    select_output_variables,
    setup_parameters,
    count_entities,
    count_active_entities,
    associated_entity,
    active_entities,
    number_of_entities,
    declare_entities,
    get_neighborship

    import Jutul: Faces,
    get_diagonal_cache,
    align_to_jacobian!,
    diagonal_alignment!,
    half_face_flux_cells_alignment!,
    update_cross_term!,
    get_entry,
    get_jacobian_pos,
    DiagonalEquation

import Jutul: setup_parameters_domain!, setup_parameters_system!, setup_parameters_context!, setup_parameters_formulation!
import Jutul: fill_equation_entries!, update_linearized_system_equation!, check_convergence, update!, linear_operator, transfer, operator_nrows, matrix_layout, apply!
import Jutul: apply_forces_to_equation!, convergence_criterion
import Jutul: get_dependencies
import Jutul: setup_forces, setup_state, setup_state!
import Jutul: declare_pattern, select_primary_variables!
#using Jutul
#using ForwardDiff, StaticArrays, SparseArrays, LinearAlgebra, Statistics
#using AlgebraicMultigrid, Krylov
# PVT
#using MultiComponentFlash
#using MAT
#using Tullio, LoopVectorization, Polyester, CUDA
#using TimerOutputs
    #include("battery.jl")
    include("physical_constants.jl")
    include("battery_types.jl")
    include("tensor_tools.jl")
    include("physics.jl")
    include("battery_utils.jl")
    include("test_setup.jl")

    include("models/elchem_component.jl")
    include("models/elyte.jl")
    include("models/current_collector.jl")
    include("models/current_collector_temp.jl")
    include("models/activematerial.jl")
    include("models/ocd.jl")
    include("models/simple_elyte.jl")
    include("models/CurrentAndVoltageBoundary.jl")
    include("models/battery_cross_terms.jl") # Works now
end # module

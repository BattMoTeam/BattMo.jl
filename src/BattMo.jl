module BattMo
using PrecompileTools
using StaticArrays
using Statistics
using StatsBase
using LinearAlgebra
using SparseArrays

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

timeit_debug_enabled() = Jutul.timeit_debug_enabled()

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
    physical_representation,
    get_1d_interpolator
    
include("utils/physical_constants.jl")

include("input/io_types.jl")
include("input/input_types.jl")
include("input/function_input_tools.jl")


include("models/battmo_types.jl")
include("models/thermal.jl")
include("utils/assembly.jl")
include("models/elyte.jl")
include("models/current_collector.jl")
include("models/ocp.jl")
include("models/activematerial.jl")
include("models/sei_layer.jl")
include("models/current_and_voltage_boundary.jl")
include("models/battery_cross_terms.jl") # Works now
include("models/battery_utils.jl")

include("setup/model_setup.jl")
include("setup/matlab_model_setup.jl")

include("utils/battery_cell_specifications.jl")

include("solver/linsolve.jl")

include("grid/tensor_tools.jl")
include("grid/remove_cells.jl") #Trenger StatsBase
include("grid/grid_conversion.jl")
include("grid/grid_utils.jl")
include("solver/solver_as_preconditioner_system.jl")
include("solver/precondgenneral.jl")
include("solver/sparse_utils.jl")
# Precompilation of solver. Run a small battery simulation to precompile everything.
# @compile_workload begin
#    for use_general_ad in [false, true]
#         init = "p2d_40"
#         run_battery(init; general_ad = use_general_ad,info_level = -1);
#    end
# end

end # module

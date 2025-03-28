module BattMo

using JSON

# Internally exported JSONSchema functions and types
using JSONSchema: Schema, SingleIssue
using JSONSchema: validate

# Non-exported JSONSchema functions and types
import JSONSchema: Schema
import JSONSchema: _validate_entry, _validate, show, isvalid, _resolve_refs


using LinearAlgebra
using MAT: matread
using PrecompileTools
using RuntimeGeneratedFunctions
using SparseArrays
using StaticArrays
using StatsBase
using Statistics
using Tullio: @tullio


RuntimeGeneratedFunctions.init(@__MODULE__)

timeit_debug_enabled() = Jutul.timeit_debug_enabled()

# Import Jutul Types
using Jutul: ScalarVariable
using Jutul: SimulationModel, MultiModel
using Jutul: JutulEquation, DiagonalEquation
using Jutul: Faces
using Jutul: CTSkewSymmetry
using Jutul: Simulator

# Import Jutul functions
using Jutul: simulate
using Jutul: hasentity, haskey
using Jutul: number_of_cells, number_of_faces, number_of_entities
using Jutul: update_primary_variable!, update_half_face_flux!, update_accumulation!, update_equation!, update_equation_in_entity!
using Jutul: update_linearized_system_equation!, update_cross_term!, update!
using Jutul: setup_forces, setup_state, setup_state!, setup_parameters
using Jutul: initialize_primary_variable_ad!, initialize_variable_ad!
using Jutul: count_entities, count_active_entities, active_entities, associated_entity
using Jutul: get_neighborship, local_discretization
using Jutul: align_to_jacobian!, diagonal_alignment!, get_jacobian_pos, half_face_flux_cells_alignment!
using Jutul: check_convergence, convergence_criterion
using Jutul: get_dependencies, get_entry
using Jutul: linear_operator, transfer, operator_nrows, matrix_layout
using Jutul: fill_equation_entries!, apply_forces_to_equation!, apply!
using Jutul: physical_representation, get_1d_interpolator

# Import Jutul functions to extend
using Jutul: face_flux!
using Jutul: maximum_value, minimum_value, absolute_increment_limit, relative_increment_limit, default_value
using Jutul: select_minimum_output_variables!, select_equations!, select_primary_variables!, select_secondary_variables!, select_parameters!
using Jutul: degrees_of_freedom_per_entity, declare_entities
using Jutul: cross_term_entities, cross_term_entities_source, update_cross_term_in_entity!
using Jutul: symmetry


##############################################
# Include variables
include("variables/physical_constants.jl")
include("variables/types.jl")

##############################################
# Include parameters
include("parameters/types.jl")
include("parameters/base_extensions.jl")
include("parameters/meta_data/parameters.jl")
include("parameters/schemas/cell_parameter_set.jl")
include("parameters/defaults/cell_parameter_set.jl")
include("parameters/tools/loader.jl")
include("parameters/tools/merger.jl")
include("parameters/tools/validater.jl")
include("parameters/tools/formatter.jl")



include("models/submodels/functional_valued_parameters/tools.jl")
include("models/submodels/functional_valued_parameters/ocp.jl")
include("models/submodels/functional_valued_parameters/electrolyte_conductivity.jl")
include("models/submodels/functional_valued_parameters/electrolyte_diffusivity.jl")


##############################################
# Include meshes
include("meshes/mesh.jl")
include("meshes/mrst_mesh.jl")
include("meshes/tensor_tools.jl")
include("meshes/remove_cells.jl") #Trenger StatsBase
include("meshes/grid_utils.jl")

##############################################
# Include geometries
include("geometries/1D.jl")
include("geometries/pouch_cell.jl")


##############################################
# Include models
include("models/full_battery_models/battery_model.jl")
include("models/full_battery_models/lithium_ion.jl")
include("models/battmo_types.jl")
include("models/submodels/thermal.jl")
include("models/submodels/electrolyte.jl")
include("models/submodels/current_collector.jl")
include("models/submodels/activematerial.jl")
include("models//reaction_rate.jl")
include("models/submodels/sei_layer.jl")
include("models/submodels/current_and_voltage_boundary.jl")
include("models/battery_cross_terms.jl") # Works now
include("models/battery_utils.jl")

##############################################
# Include setup
include("setup/model_setup.jl")
include("setup/matlab_model_setup.jl")

##############################################
# Include forward_simulation
include("forward_simulation/simulate.jl")


##############################################
# Include utils
include("utils/battery_cell_specifications.jl")

##############################################
# Include solver
include("solver/linsolve.jl")
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

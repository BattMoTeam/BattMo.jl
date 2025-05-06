module BattMo

# ─────────────────────────────────────────────────────────────────────────────
# 📌 Core Libraries & Utilities
# ─────────────────────────────────────────────────────────────────────────────
using PrecompileTools                             # Precompilation optimizations
using RuntimeGeneratedFunctions                   # Code generation


# ─────────────────────────────────────────────────────────────────────────────
# 📂 File Handling & Data Processing
# ─────────────────────────────────────────────────────────────────────────────
using JSON: JSON                                  # JSON parsing
using MAT: matread

# Internally exported JSONSchema functions and types
using JSONSchema: Schema, SingleIssue

# Non-exported JSONSchema functions and types
import JSONSchema: show, isvalid, _resolve_refs

# ─────────────────────────────────────────────────────────────────────────────
# 🧮 Plotting and visualization
# ─────────────────────────────────────────────────────────────────────────────

using Jutul: plot_multimodel_interactive
using GLMakie

# ─────────────────────────────────────────────────────────────────────────────
# 🧮 Optimization and Adjoint solving
# ─────────────────────────────────────────────────────────────────────────────
using LBFGSB: lbfgsb
using Jutul: solve_adjoint_sensitivities, optimization_config, setup_parameter_optimization
using Jutul: devectorize_variables!

# ─────────────────────────────────────────────────────────────────────────────
# 🧮 Mathematical & Computational Tools
# ─────────────────────────────────────────────────────────────────────────────
using Polynomials: fit, coeffs, Polynomial        # Polynomial fitting & manipulation
using LinearAlgebra: LinearAlgebra                               # Linear algebra operations
using SparseArrays: AbstractSparseMatrixCSC, SparseMatrixCSC
using SparseArrays: require_one_based_indexing, getcolptr, rowvals, nzrange, nonzeros        # Sparse matrix support
using StaticArrays                                # Static-sized arrays
using Statistics                                  # Basic statistical functions
using StatsBase: inverse_rle                      # Statistical utility
using Tullio: @tullio                             # Einstein summation notation


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Jutul Core Structures & functions
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: Jutul
using Jutul: hasentity, haskey
using Jutul: physical_representation
using Jutul: @tic, @jutul_secondary

using Jutul: ProgressRecorder


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Physical and mathemathical models
# ─────────────────────────────────────────────────────────────────────────────

using Jutul: ConservationLaw
using Jutul: CTSkewSymmetry, PotentialFlow, TwoPointPotentialFlowHardCoded
using Jutul: get_1d_interpolator
using Jutul: symmetry, number_of_degrees_of_freedom
using Jutul: conserved_symbol

# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Variables
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: ScalarVariable, VectorVariables
using Jutul: JutulStorage

using Jutul: update!, update_primary_variable!, update_secondary_variables!
using Jutul: update_accumulation!, update_value
using Jutul: absolute_increment_limit, relative_increment_limit
using Jutul: select_minimum_output_variables!, select_primary_variables!
using Jutul: select_secondary_variables!, select_parameters!
using Jutul: maximum_value, minimum_value, default_value
using Jutul: variable_scale, default_parameter_values, value

# ─────────────────────────────────────────────────────────────────────────────
# 📊 Entities
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: JutulEntity

using Jutul: active_entities, associated_entity
using Jutul: declare_entities
using Jutul: count_entities, count_active_entities
using Jutul: degrees_of_freedom_per_entity, number_of_entities


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Equations
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: JutulEquation, DiagonalEquation

using Jutul: update_equation!, update_equation_in_entity!, update_linearized_system_equation!
using Jutul: fill_equation_entries!, apply_forces_to_equation!
using Jutul: select_equations!
using Jutul: number_of_equations_per_entity


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Mesh and Discretization
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: JutulMesh, CartesianMesh, UnstructuredMesh, FiniteVolumeMesh, MRSTWrapMesh
using Jutul: JutulDomain, DiscretizedDomain, DataDomain
using Jutul: Faces, BoundaryFaces, HalfFaces, Cells

using Jutul: number_of_faces, number_of_boundary_faces, number_of_cells
using Jutul: compute_face_trans, compute_half_face_trans, compute_boundary_trans
using Jutul: compute_centroid_and_measure
using Jutul: local_discretization


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Cross terms
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: AdditiveCrossTerm

using Jutul: cross_term_entities, cross_term_entities_source
using Jutul: setup_cross_term, add_cross_term!
using Jutul: update_cross_term!, update_cross_term_in_entity!

# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Fluxes
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: face_flux!, half_face_flux_cells_alignment!
using Jutul: update_half_face_flux!


# ─────────────────────────────────────────────────────────────────────────────
# 🎛️ Simulation and model
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: SimulationModel, MultiModel
using Jutul: JutulSimulator, Simulator
using Jutul: JutulSystem, JutulFormulation, JutulContext, DefaultContext

using Jutul: simulate, simulator_config
using Jutul: setup_forces, setup_state, setup_state!, setup_parameters
using Jutul: initialize_primary_variable_ad!, initialize_variable_ad!
using Jutul: get_neighborship, get_simulator_storage, get_simulator_model
using Jutul: get_submodel_offsets, submodels_symbols


# ─────────────────────────────────────────────────────────────────────────────
# 🔍 Solver, Convergence & Preconditioning
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: JutulPreconditioner
using Jutul: LinearizedSystem, LinearOperator
using Jutul: LUSolver

using Jutul: check_convergence, convergence_criterion, linear_solve!
using Jutul: update_preconditioner!, apply!, mul!, operator_nrows
using Jutul: perform_step_solve_impl!, reset_state_to_previous_state!, partial_update_preconditioner!
using Jutul: is_left_preconditioner, is_right_preconditioner, opEye


# ─────────────────────────────────────────────────────────────────────────────
# 🏗️ Matrix & Linear System Handling
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: align_to_jacobian!, diagonal_alignment!
using Jutul: get_jacobian_pos, linear_operator, transfer, operator_nrows, matrix_layout
using Jutul: get_diagonal_entries


# ─────────────────────────────────────────────────────────────────────────────
# 🛠️ Other
# ─────────────────────────────────────────────────────────────────────────────
using Jutul: get_dependencies, get_entry, convert_to_immutable_storage
using Jutul: tpfv_geometry, apply!, is_cell_major
using Jutul: StaticCSR, ParallelCSRContext


timeit_debug_enabled() = Jutul.timeit_debug_enabled()


RuntimeGeneratedFunctions.init(@__MODULE__)


include("input/input_types.jl")
include("input/meta_data/parameters.jl")
include("input/printer.jl")
include("input/schemas/get_schema.jl")
include("input/schemas/get_json_from_schema.jl")

include("utils/physical_constants.jl")
include("utils/battery_kpis.jl")


include("models/battmo_types.jl")
include("models/full_battery_model_setups/battery_model.jl")
include("models/full_battery_model_setups/lithium_ion.jl")

include("input/loader.jl")
include("input/defaults.jl")
include("input/writer.jl")
include("input/function_input_tools.jl")
include("input/formatter.jl")
include("input/validator.jl")



include("models/thermal.jl")
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

include("plotting/3D.jl")

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

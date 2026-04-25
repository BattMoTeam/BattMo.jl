export Simulation
export solve
export setup_config


"""
	abstract type AbstractSimulation

Abstract type for Simulation structs. Subtypes of `AbstractSimulation` represent specific simulation configurations.
"""
abstract type AbstractSimulation end


"""
	Simulation(model::ModelConfigured,
                   cell_parameters::CellParameters,
                   cycling_protocol::CyclingProtocol;
                   simulation_settings::SimulationSettings = get_default_simulation_settings(model))

Constructs a `Simulation` object that sets up and validates all necessary components for simulating a battery model.

# Arguments
- `model::ModelConfigured`: A fully configured model object that includes the physical and numerical setup.
- `cell_parameters::CellParameters`: Parameters defining the physical characteristics of the battery cell.
- `cycling_protocol::CyclingProtocol`: The protocol specifying the charging/discharging cycles for the simulation.
- `simulation_settings::SimulationSettings` (optional): Configuration settings controlling solver behavior, time stepping, etc. If not provided, default settings are generated based on the model.
- `time_steps` (optional): A pre-computed array of time steps to use for the simulation. If `nothing` (default), time steps are computed from the cycling protocol and simulation settings.
- `state0` (optional): A pre-computed initial state to use for the simulation. If `nothing` (default), the initial state is computed from the model and cycling protocol.
- `output_all_secondary_variables::Bool` (optional): If `true`, all secondary variables (e.g. `SolidDiffFlux`, `DmuDc`, `ChemCoef`) are included in the simulation output states. This makes the output states directly usable as `initial_state` for subsequent simulations. Default is `false`.

# Behavior
- Validates `model`, `cell_parameters`, `cycling_protocol`, and `simulation_settings`.
- Sets up default solver options if not explicitly defined.
- Initializes computational grids and couplings.
- Configures the physical model and parameters.
- Prepares the initial simulation state and external forcing functions.
- Instantiates a `Simulator` from the Jutul framework with the prepared state and parameters.
- Defines the time-stepping strategy for the simulation.
- Assembles a simulation configuration object used to control execution.

# Returns
A `Simulation` struct instance that includes:
- Validation flag (`is_valid`)
- Prepared simulation components: model, grids, couplings, parameters, initial state, forces, time steps, and simulator instance.

# Throws
- An error if `model.is_valid == false`, halting construction with a helpful message.

"""
struct Simulation <: AbstractSimulation
    model::ModelConfigured
    cell_parameters::CellParameters
    cycling_protocol::CyclingProtocol
    simulation_settings::SimulationSettings
    time_steps::Any
    forces::Any
    initial_state::Any
    grids::Any
    couplings::Any
    parameters::Any
    simulator::Any
    output_all_secondary_variables::Bool
    is_valid::Bool
    validate::Bool


    function Simulation(
            model::M,
            cell_parameters::CellParameters,
            cycling_protocol::CyclingProtocol;
            simulation_settings::SimulationSettings = get_default_simulation_settings(model),
            time_steps = nothing,
            initial_state = nothing,
            output_all_secondary_variables::Bool = false,
            hook = nothing,
            validate::Bool = true,
            kwargs...,
        ) where {M <: ModelConfigured}

        model_settings = model.settings

        if validate
            model_is_valid = model.is_valid
            cell_parameters_is_valid = validate_parameter_set(cell_parameters, model_settings)
            cycling_protocol_is_valid = validate_parameter_set(cycling_protocol, model_settings)
            simulation_settings_is_valid = validate_parameter_set(simulation_settings, model_settings)
            is_valid = model_is_valid && cell_parameters_is_valid && cycling_protocol_is_valid && simulation_settings_is_valid
        else
            is_valid = true
        end

        input = (
            model_settings = model_settings,
            cell_parameters = cell_parameters,
            cycling_protocol = cycling_protocol,
            simulation_settings = simulation_settings,
            time_steps = time_steps,
            initial_state = initial_state,
            output_all_secondary_variables = output_all_secondary_variables,
        )

        sim_cfg = simulation_configuration(model, input)

        return new(
            sim_cfg.model,
            cell_parameters,
            cycling_protocol,
            simulation_settings,
            sim_cfg.time_steps,
            sim_cfg.forces,
            sim_cfg.initial_state,
            sim_cfg.grids,
            sim_cfg.couplings,
            sim_cfg.parameters,
            sim_cfg.simulator,
            output_all_secondary_variables,
            is_valid,
            validate,
        )

    end
end


function simulation_configuration(model, input)

    # Setup grids and couplings
    grids, couplings = setup_grids_and_couplings(model, input)

    # Setup simulation
    model, parameters = setup_model!(model, input, grids, couplings)

    # Setup initial state
    initial_state = setup_initial_state(input, model)

    # Setup forces
    forces = setup_forces(model.multimodel)

    # Add all secondary variables to output if requested
    if get(input, :output_all_secondary_variables, false)
        for key in submodels_symbols(model.multimodel)
            submodel = model.multimodel[key]
            union!(submodel.output_variables, keys(submodel.secondary_variables))
        end
    end

    # Setup jutul simulator
    simulator = Simulator(model.multimodel; state0 = initial_state, parameters = parameters, copy_state = true)

    # Setup time steps
    time_steps = setup_timesteps(input)

    return (
        model = model,
        grids = grids,
        couplings = couplings,
        parameters = parameters,
        initial_state = initial_state,
        forces = forces,
        simulator = simulator,
        time_steps = time_steps,
    )

end


#########
# Solve #
#########

"""
	solve(problem::Simulation;
              accept_invalid = false,
              hook = nothing,
              info_level = 0,
              end_report = info_level > -1,
              include_initial_state = false,
              kwargs...)

Solves a battery `Simulation` problem by executing the simulation workflow defined in `solve_simulation_case`.

# Arguments
- `problem::Simulation`: A fully constructed `Simulation` object, containing all model parameters, solver settings, and initial conditions.
- `accept_invalid::Bool` (optional): If `true`, bypasses the internal validation check on the `Simulation` object. Use with caution. Default is `false`.
- `hook` (optional): A user-defined callback or observer function that can be inserted into the simulation loop.
- `info_level::Int` (optional): Controls verbosity of simulation logging and output. Default is `0`.
- `end_report::Bool` (optional): Whether to print a summary report after simulation. Defaults to `true` if `info_level > -1`.
- `include_initial_state::Bool` (optional): If `true`, the initial state (at `t = 0`) is
  prepended to the output time series (`Time`, `Voltage`, `Current`, capacity, etc.).
  This eliminates the gap between the initial condition and the first solver output,
  improving plots and RMSE comparisons when restarting from a saved state.  Default is `false`.
- `kwargs...`: Additional keyword arguments forwarded to `solve_simulation_case`.

# Behavior
- Validates the `Simulation` object unless `accept_invalid` is `true`.
- Prepares simulation configuration options, including verbosity and report behavior.
- Calls `solve_simulation_case`, passing in the simulation problem and configuration.

# Returns
- The result of `solve_simulation_case`, typically containing simulation outputs such as state trajectories, solver diagnostics, and performance metrics.

# Throws
- An error if the `Simulation` object is invalid and `accept_invalid` is not set to `true`.

# Example
```julia
sim = Simulation(model, cell_parameters, cycling_protocol)
result = solve(sim; info_level = 1)

# Include initial state in the time series output
result = solve(sim; include_initial_state = true)
```
"""
function solve(
        problem::Simulation;
        accept_invalid::Bool = false,
        solver_settings = get_default_solver_settings(problem.model),
        logger = nothing,
        include_initial_state = false,
        kwargs...
    )

    validate = problem.validate

    if validate && !problem.is_valid && !accept_invalid
        error(
            """
            Your Simulation object is not valid.

            TIP: Validation happens when instantiating the Simulation object.
            Check the warnings to see exactly where things went wrong.

            If you are confident you know what you are doing, you can bypass this
            validation result when solving:

                solve(sim; accept_invalid = true)

            Note that `accept_invalid = true` only applies when validation is enabled.
            """,
        )
    end

    return solve_simulation_case(
        problem;
        solver_settings,
        logger,
        include_initial_state,
        validate,
        accept_invalid,
        kwargs...,
    )

end

"""
	solve_simulation_case(sim::Simulation;
                              hook = nothing,
                              kwargs...)

Executes the simulation workflow for a battery `Simulation` object by advancing the system state over the defined time steps using the configured solver and model.

# Arguments
- `sim::Simulation`: A `Simulation` instance containing all preconfigured simulation components including model, state, solver, time steps, and settings.
- `hook` (optional): A user-supplied callback function to be invoked *before* the simulation begins. Useful for modifying or logging internal simulation structures (e.g., for debugging, monitoring, or visualization).
- `kwargs...`: Additional keyword arguments passed to the lower-level solver configuration.

# Behavior
- Extracts all relevant simulation components from the `Simulation` object.
- Optionally invokes a user-defined `hook` function with simulation internals.
- Calls the `simulate` function to perform time integration across defined time steps.
- Constructs a set of metadata dictionaries for downstream analysis or inspection.

# Returns
A named tuple with the following fields:
- `states`: The computed simulation states over all time steps.
- `cellSpecifications`: Cell-level metrics computed from the final model state.
- `reports`: Simulation logs and diagnostics generated during execution.
- `input`: A dictionary of the original input settings used in the simulation.
- `extra`: A dictionary containing internal simulation structures such as:
  - Simulator, initial state, parameters
  - Grids and couplings
  - Time steps and configuration
  - Model, cell parameters, cycling protocol

# Example
```julia
result = solve_simulation_case(sim)
```
"""
function solve_simulation_case(
        sim::Union{Simulation, NamedTuple};
        solver_settings,
        logger = nothing,
        include_initial_state = false,
        validate::Bool = true,
        accept_invalid::Bool = false,
        kwargs...
    )

    simulator = sim.simulator
    model = sim.model
    state0 = sim.initial_state
    forces = sim.forces
    timesteps = sim.time_steps
    grids = sim.grids
    couplings = sim.couplings
    parameters = sim.parameters
    simulation_settings = sim.simulation_settings
    cell_parameters = sim.cell_parameters
    cycling_protocol = sim.cycling_protocol

    # Setup solver configuration
    cfg = solver_configuration(
        simulator,
        model.multimodel,
        parameters;
        solver_settings,
        validate,
        accept_invalid,
        logger,
        kwargs...,
    )

    # Setup hook if given
    hook = get(kwargs, :hook, nothing)
    if !isnothing(hook)
        hook(
            simulator,
            model.multimodel,
            state0,
            forces,
            timesteps,
            cfg,
        )
    end

    # Perform simulation
    jutul_states, jutul_reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg, kwargs...)

    jutul_output = (
        states = jutul_states,
        reports = jutul_reports,
        solver_configuration = cfg,
        multimodel = model.multimodel,
    )

    input = FullSimulationInput(
        Dict(
            "BaseModel" => string(nameof(typeof(model))),
            "ModelSettings" => model.settings.all,
            "CellParameters" => cell_parameters.all,
            "CyclingProtocol" => cycling_protocol.all,
            "SimulationSettings" => simulation_settings.all,
            "SolverSettings" => solver_settings.all,
        ),
    )

    # Optionally include the initial state as the first data point
    if include_initial_state
        jutul_output_for_ts = (
            states = vcat([deepcopy(state0)], jutul_states),
            reports = jutul_reports,
            solver_configuration = cfg,
            multimodel = model.multimodel,
        )
    else
        jutul_output_for_ts = jutul_output
    end

    time_series = get_output_time_series(jutul_output_for_ts)
    states = get_output_states(jutul_output, grids, input)
    metrics = get_output_metrics(jutul_output)

    return SimulationOutput(
        time_series,
        states,
        metrics,
        input,
        jutul_output,
        model,
        sim,
    )

end

function overwrite_solver_settings_kwargs!(solver_settings; kwargs...)
    settings = kwarg_dict(; kwargs...)  # Convert kwargs to Dict

    # Initialize return variables as nothing
    linear_solver = nothing
    relaxation = nothing
    timestep_selectors = nothing

    for (dict_key, dict) in settings
        if !isnothing(dict) && !ismissing(dict)
            if dict_key == "LinearSolver"
                if isa(dict, Dict)
                    solver_settings[dict_key] = dict
                else
                    solver_settings[dict_key] = Dict("Method" => "UserDefined")
                    linear_solver = dict
                end

            else

                for (key, value) in dict

                    if !isnothing(value) && !ismissing(value)

                        if key == :TimeStepSelectors
                            if isa(value, String)
                                solver_settings[dict_key][key] = value
                            else
                                solver_settings[dict_key][key] = "UserDefined"
                                timestep_selectors = value
                            end

                        elseif key == :Relaxation
                            if isa(value, String)
                                solver_settings[dict_key][key] = value
                            else
                                solver_settings[dict_key][key] = "UserDefined"
                                relaxation = value
                            end


                        else
                            # Overwrite for all other keys
                            solver_settings[dict_key][key] = value

                        end
                    end
                end

            end
        end

    end

    return (
        solver_settings = solver_settings,
        linear_solver = linear_solver,
        relaxation = relaxation,
        timestep_selectors = timestep_selectors,
    )

end


function kwarg_dict(; kwargs...)
    kwarg_dict = Dict(
        "NonLinearSolver" => Dict(
            "MaxTimestepCuts" => get(kwargs, :max_timestep_cuts, nothing),
            "MaxTimestep" => get(kwargs, :max_timestep, nothing),
            "TimestepMaxIncrease" => get(kwargs, :timestep_max_increase, nothing),
            "TimestepMaxDecrease" => get(kwargs, :timestep_max_decrease, nothing),
            "MaxResidual" => get(kwargs, :max_residual, nothing),
            "MaxNonLinearIterations" => get(kwargs, :max_nonlinear_iterations, nothing),
            "MinNonLinearIterations" => get(kwargs, :min_nonlinear_iterations, nothing),
            "FailureCutsTimesteps" => get(kwargs, :failure_cuts_timestep, nothing),
            "CheckBeforeSolve" => get(kwargs, :check_before_solve, nothing),
            "AlwaysUpdateSecondary" => get(kwargs, :always_update_secondary, nothing),
            "ErrorOnIncomplete" => get(kwargs, :error_on_incomplete, nothing),
            "CuttingCriterion" => get(kwargs, :cutting_criterion, nothing),
            "Tolerances" => get(kwargs, :tolerances, nothing),
            "TolFactorFinalIteration" => get(kwargs, :tol_factor_final_iteration, nothing),
            "SafeMode" => get(kwargs, :safe_mode, nothing),
            "ExtraTiming" => get(kwargs, :extra_timing, nothing),
            "TimeStepSelectors" => get(kwargs, :timestep_selectors, nothing),
            "Relaxation" => get(kwargs, :relaxation, nothing),
        ),
        "LinearSolver" => get(kwargs, :linear_solver, nothing),
        "Verbose" => Dict(
            "InfoLevel" => get(kwargs, :info_level, nothing),
            "DebugLevel" => get(kwargs, :debug_level, nothing),
            "EndReport" => get(kwargs, :end_report, nothing),
            "ASCIITerminal" => get(kwargs, :ascii_terminal, nothing),
            "ID" => get(kwargs, :id, nothing),
            "ProgressColor" => get(kwargs, :progress_color, nothing),
            "ProgressGlyphs" => get(kwargs, :progress_glyphs, nothing),
        ),
        "Output" => Dict(
            "OutputPath" => get(kwargs, :output_path, nothing),
            "OutputStates" => get(kwargs, :output_states, nothing),
            "OutputReports" => get(kwargs, :output_reports, nothing),
            "InMemoryReports" => get(kwargs, :in_memory_reports, nothing),
            "ReportLevel" => get(kwargs, :report_level, nothing),
            "OutputSubstrates" => get(kwargs, :output_substates, nothing),
        ),
    )

    return kwarg_dict
end

######################################
# Setup solver configuration options #
######################################

"""
        setup_configuration(sim::JutulSimulator,
                            model::MultiModel,
                            parameters;
                            inputparams::AdvancedDictInput,
                            extra_timing::Bool,
                            use_model_scaling,
                            kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function solver_configuration(
        sim::JutulSimulator,
        model::MultiModel,
        parameters;
        use_model_scaling::Bool = true,
        solver_settings,
        logger = nothing,
        validate::Bool = true,
        accept_invalid::Bool = false,
        kwargs...
    )

    solver_settings = deepcopy(solver_settings)

    overwritten_settings = overwrite_solver_settings_kwargs!(solver_settings; kwargs...)
    solver_settings = overwritten_settings.solver_settings

    if validate
        solver_settings_is_valid = validate_parameter_set(solver_settings)

        if !solver_settings_is_valid && !accept_invalid
            error(
                """
                Your SolverSettings are not valid.

                TIP: Solver settings are validated when calling `solve`.
                Check the warnings to see exactly where things went wrong.

                If you are confident you know what you are doing, you can bypass this
                validation result when solving:

                    solve(sim; accept_invalid = true)

                Note that `accept_invalid = true` only applies when validation is enabled.
                """,
            )
        end
    end

    non_linear_solver = solver_settings["NonLinearSolver"]
    linear_solver_dict = solver_settings["LinearSolver"]
    output = solver_settings["Output"]
    verbose = solver_settings["Verbose"]

    relaxation = non_linear_solver["Relaxation"]
    if relaxation == "NoRelaxation"
        relax = NoRelaxation()
    elseif relaxation == "SimpleRelaxation"
        relax = SimpleRelaxation()
    else
        error("Relaxation method $(relaxation) not recognized. Only 'NoRelaxation' and 'SimpleRelaxation' are currently implemented.")
    end

    timestep_selector = non_linear_solver["TimeStepSelectors"]
    if timestep_selector == "TimestepSelector"
        timesel = [TimestepSelector()]
    else
        error("Timestep selector $(timestep_selector) not recognized. Only 'TimestepSelector' is currently implemented.")
    end

    if linear_solver_dict["Method"] == "UserDefined"
        linear_solver = overwritten_settings.linear_solver
    else
        linear_solver = battery_linsolve(linear_solver_dict)
    end

    cfg = simulator_config(
        sim;
        info_level = verbose["InfoLevel"],
        debug_level = verbose["DebugLevel"],
        end_report = verbose["EndReport"],
        ascii_terminal = verbose["ASCIITerminal"],
        id = verbose["ID"],
        progress_color = Symbol(verbose["ProgressColor"]),
        progress_glyphs = Symbol(verbose["ProgressGlyphs"]),
        max_timestep_cuts = non_linear_solver["MaxTimestepCuts"],
        max_timestep = non_linear_solver["MaxTimestep"],
        timestep_max_increase = non_linear_solver["TimestepMaxIncrease"],
        timestep_max_decrease = non_linear_solver["TimestepMaxDecrease"],
        max_residual = non_linear_solver["MaxResidual"],
        max_nonlinear_iterations = non_linear_solver["MaxNonLinearIterations"],
        min_nonlinear_iterations = non_linear_solver["MinNonLinearIterations"],
        failure_cuts_timestep = non_linear_solver["FailureCutsTimesteps"],
        check_before_solve = non_linear_solver["CheckBeforeSolve"],
        always_update_secondary = non_linear_solver["AlwaysUpdateSecondary"],
        error_on_incomplete = non_linear_solver["ErrorOnIncomplete"],
        cutting_criterion = non_linear_solver["CuttingCriterion"],
        tol_factor_final_iteration = non_linear_solver["TolFactorFinalIteration"],
        safe_mode = non_linear_solver["SafeMode"],
        extra_timing = non_linear_solver["ExtraTiming"],
        linear_solver = linear_solver,
        relaxation = relax,
        timestep_selectors = timesel,
        output_states = output["OutputStates"],
        output_reports = output["OutputReports"],
        output_path = output["OutputPath"] == "" ? nothing : output["OutputPath"],
        in_memory_reports = output["InMemoryReports"],
        report_level = output["ReportLevel"],
        output_substates = output["OutputSubstrates"],
    )

    if !isempty(non_linear_solver["Tolerances"])
        cfg[:tolerances] = non_linear_solver["Tolerances"]
    end

    if !isnothing(logger)
        cfg[:post_iteration_hook] = logger
    end

    if use_model_scaling
        scalings = get_scalings(model, parameters)
        tol_default = 1.0e-5
        for scaling in scalings
            model_label = scaling[:model_label]
            equation_label = scaling[:equation_label]
            value = scaling[:value]
            cfg[:tolerances][model_label][equation_label] = value * tol_default
        end
    else
        for key in submodels_symbols(model)
            cfg[:tolerances][key][:default] = 1.0e-5
        end
    end

    if model[:Control].system.policy isa CyclingCVPolicy || model[:Control].system.policy isa CCPolicy
        if model[:Control].system.policy isa CyclingCVPolicy

            cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)

        elseif model[:Control].system.policy isa CCPolicy && model[:Control].system.policy.numberOfCycles > 0
            cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)
        end

        function post_hook(done, report, sim, dt, forces, max_iter, cfg)

            s = get_simulator_storage(sim)
            m = get_simulator_model(sim)

            if model[:Control].system.policy isa CyclingCVPolicy

                if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
                    report[:stopnow] = true
                else
                    report[:stopnow] = false
                end

            elseif model[:Control].system.policy isa CCPolicy

                if m[:Control].system.policy.numberOfCycles == 0

                    if m[:Control].system.policy.initialControl == "charging"

                        if s.state.Control.ElectricPotential[1] >= m[:Control].system.policy.upperCutoffVoltage
                            report[:stopnow] = true
                        else
                            report[:stopnow] = false
                        end

                    elseif m[:Control].system.policy.initialControl == "discharging"

                        if s.state.Control.ElectricPotential[1] <= m[:Control].system.policy.lowerCutoffVoltage
                            report[:stopnow] = true

                        else

                            report[:stopnow] = false
                        end
                    end
                else
                    if s.state.Control.Controller.numberOfCycles >= m[:Control].system.policy.numberOfCycles
                        report[:stopnow] = true
                    else
                        report[:stopnow] = false
                    end
                end
            end

            return (done, report)

        end

        cfg[:post_ministep_hook] = post_hook

    end

    return cfg

end


function get_scalings(model, parameters)

    refT = 298.15
    T = refT

    eldes = (:NegativeElectrodeActiveMaterial, :PositiveElectrodeActiveMaterial)

    j0s = Array{Float64}(undef, 2)
    Rvols = Array{Float64}(undef, 2)

    F = FARADAY_CONSTANT

    for (i, elde) in enumerate(eldes)

        rate_func = model[elde].system.params[:reaction_rate_constant_func]
        cmax = model[elde].system[:maximum_concentration]
        # Eak       = model[elde].system[:activation_energy_of_reaction]
        vsa = model[elde].system[:volumetric_surface_area]

        Ea = hasproperty(model[elde].system.params, :activation_energy_of_diffusion) ?
            model[elde].system.params[:activation_energy_of_diffusion] :
            0.0

        temperature_dependence_model = Symbol(model[elde].system[:setting_temperature_dependence])

        c_a = 0.5 * cmax

        if isa(rate_func, Real)
            R0 = temperature_dependent(refT, rate_func, Ea, temperature_dependence_model)
            # R0 = arrhenius(refT, rate_func, Eak)
        elseif isa(rate_func, String) || isa(rate_func, Function)
            R0 = temperature_dependent(refT, rate_func(c_a, T, refT, cmax), Ea, temperature_dependence_model)
        elseif isa(rate_func, Dict)
            R0 = temperature_dependent(refT, rate_func(c_a), Ea, temperature_dependence_model)
        else
            error("Unsupported type for reaction rate constant function: $(typeof(rate_func))")
        end
        c_e = 1000.0
        activematerial = model[elde].system

        j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial)

        # j0s[i] = reaction_rate_coefficient(R0, c_e, c_a, activematerial, c_a, c_e)

        Rvols[i] = j0s[i] * vsa / F

    end

    j0Ref = mean(j0s)
    RvolRef = mean(Rvols)

    if include_current_collectors(model)
        component_names = (:NegativeElectrodeCurrentCollector, :NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial, :PositiveElectrodeCurrentCollector)
        cc_mapping = Dict(:NegativeElectrodeActiveMaterial => :NegativeElectrodeCurrentCollector, :PositiveElectrodeActiveMaterial => :PositiveElectrodeCurrentCollector)
    else
        component_names = (:NegativeElectrodeActiveMaterial, :Electrolyte, :PositiveElectrodeActiveMaterial)
    end

    volRefs = Dict()

    for name in component_names

        rep = model[name].domain.representation
        if rep isa MinimalTpfaGrid
            volRefs[name] = mean(rep.volumes)
        else
            volRefs[name] = mean(rep[:volumes])
        end

    end

    scalings = []

    scaling = (model_label = :Electrolyte, equation_label = :charge_conservation, value = F * volRefs[:Electrolyte] * RvolRef)
    push!(scalings, scaling)

    scaling = (model_label = :Electrolyte, equation_label = :mass_conservation, value = volRefs[:Electrolyte] * RvolRef)
    push!(scalings, scaling)

    for elde in eldes

        scaling = (model_label = elde, equation_label = :charge_conservation, value = F * volRefs[elde] * RvolRef)
        push!(scalings, scaling)

        if include_current_collectors(model)

            # We use the same scaling as for the coating multiplied by the conductivity ration
            cc = cc_mapping[elde]
            coef = parameters[cc][:Conductivity] / parameters[elde][:Conductivity]

            scaling = (model_label = cc, equation_label = :charge_conservation, value = F * coef[1] * volRefs[elde] * RvolRef)
            push!(scalings, scaling)

        end

        rp = model[elde].system.discretization[:rp]
        volp = 4 / 3 * pi * rp^3

        coef = RvolRef * volp

        scaling = (model_label = elde, equation_label = :mass_conservation, value = coef)
        push!(scalings, scaling)
        scaling = (model_label = elde, equation_label = :solid_diffusion_bc, value = coef)
        push!(scalings, scaling)

        if model[elde] isa SEImodel

            vsa = model[elde].system[:volumetric_surface_area]
            L = model[elde].system[:InitialThickness]
            k = model[elde].system[:IonicConductivity]

            SEIVoltageDropRef = F * RvolRef / vsa * L / k

            scaling = (model_label = elde, equation_label = :sei_voltage_drop, value = SEIVoltageDropRef)
            push!(scalings, scaling)

            De = model[elde].system[:ElectronicDiffusionCoefficient]
            ce = model[elde].system[:InterstitialConcentration]

            scaling = (model_label = elde, equation_label = :sei_mass_cons, value = De * ce / L)
            push!(scalings, scaling)

        end

    end

    return scalings

end


function setup_timesteps(
        input;
        kwargs...,
    )
    """
    	Method for setting up the timesteps from a json file object.
    """
    if hasproperty(input, :time_steps) && !isnothing(input.time_steps)
        return input.time_steps
    end

    cycling_protocol = input.cycling_protocol
    simulation_settings = input.simulation_settings

    protocol = cycling_protocol["Protocol"]

    if protocol == "CC"
        if cycling_protocol["TotalNumberOfCycles"] == 0

            if cycling_protocol["InitialControl"] == "discharging"
                CRate = cycling_protocol["DRate"]
            else
                CRate = cycling_protocol["CRate"]
            end

            con = Constants()
            totalTime = 1.1 * con.hour / CRate

            dt = simulation_settings["TimeStepDuration"]

            if haskey(input.model_settings, "RampUp")
                nr = simulation_settings["RampUpSteps"]
            else
                nr = 1
            end

            timesteps = compute_rampup_timesteps(totalTime, dt, nr)

        else

            ncycles = cycling_protocol["TotalNumberOfCycles"]
            DRate = cycling_protocol["DRate"]
            CRate = cycling_protocol["CRate"]

            con = Constants()

            totalTime = ncycles * 2 * (1 * con.hour / CRate + 1 * con.hour / DRate)

            dt = simulation_settings["TimeStepDuration"]
            n = Int64(floor(totalTime / dt))

            timesteps = repeat([dt], n)
        end

    elseif protocol == "CCCV"

        ncycles = cycling_protocol["TotalNumberOfCycles"]
        DRate = cycling_protocol["DRate"]
        CRate = cycling_protocol["CRate"]

        con = Constants()

        totalTime = ncycles * 2.5 * (1 * con.hour / CRate + 1 * con.hour / DRate)

        dt = simulation_settings["TimeStepDuration"]
        n = Int64(floor(totalTime / dt))

        timesteps = repeat([dt], n)

    elseif protocol == "Function"

        totalTime = cycling_protocol["TotalTime"]
        dt = simulation_settings["TimeStepDuration"]
        n = totalTime / dt
        timesteps = repeat([dt], Int64(floor(n)))

    elseif protocol == "InputCurrentSeries"

        # The time series defines the time steps directly
        series_times = Float64.(cycling_protocol["Times"])
        timesteps = diff(series_times)
        timesteps = timesteps[timesteps .> 0.0]

    else

        error("Protocol $protocol not recognized")

    end

    return timesteps

end

function compute_rampup_timesteps(time::Real, dt::Real, n::Integer = 8)

    ind = collect(range(n, 1, step = -1))
    dt_init = [dt / 2^k for k in ind]
    cs_time = cumsum(dt_init)

    if any(cs_time .> time)
        dt_init = dt_init[cs_time .< time]
    end

    dt_left = time .- sum(dt_init)

    # Even steps
    dt_rem = dt * ones(floor(Int64, dt_left / dt))

    # Final ministep if present
    dt_final = time - sum(dt_init) - sum(dt_rem)

    # Less than to account for rounding errors leading to a very small
    # negative time-step.
    if dt_final <= 0
        dt_final = []
    end

    # Combined timesteps
    dT = [dt_init; dt_rem; dt_final]

    return dT
end

####################
# Current function #
####################

function currentFun(t::Real, inputI::Real, tup::Real = 0.1)

    t, inputI, tup, val = promote(t, inputI, tup, 0.0)

    if t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t)
    else
        val = inputI
    end

    return val

end

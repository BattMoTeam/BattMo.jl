export prepare_state_for_simulation

"""
    prepare_state_for_simulation(state)

Prepare a simulation output state for use as an initial state in a new simulation.
"""
function prepare_state_for_simulation(state)
    state = deepcopy(state)
    for (component_name, component_state) in state
        # P2D active material components: add SolidDiffFlux if missing
        if haskey(component_state, :ParticleConcentration) && !haskey(component_state, :SolidDiffFlux)
            pc = component_state[:ParticleConcentration]
            N = size(pc, 1)   # number of particle discretization nodes
            nc = size(pc, 2)  # number of cells
            # SolidDiffFlux has N-1 dof per cell (flux at interfaces between N nodes)
            component_state[:SolidDiffFlux] = zeros(eltype(pc), N - 1, nc)
        end
        # Electrolyte component: add DmuDc and ChemCoef if missing
        if haskey(component_state, :ElectrolyteConcentration)
            nc = length(component_state[:ElectrolyteConcentration])
            if !haskey(component_state, :DmuDc)
                component_state[:DmuDc] = zeros(nc)
            end
            if !haskey(component_state, :ChemCoef)
                component_state[:ChemCoef] = zeros(nc)
            end
        end
    end
    return state
end


function get_model(base_model::String, model_settings::ModelSettings)

    if base_model == "LithiumIonBattery"
        model = LithiumIonBattery(; model_settings = model_settings)
    elseif base_model == "SodiumIonBattery"
        model = SodiumIonBattery(; model_settings = model_settings)
    else
        error("BaseModel $base_model is not valid. The following models are available: LithiumIonBattery, SodiumIonBattery")
    end

    return model
end

struct SourceAtCell
    cell::Any
    src::Any
    function SourceAtCell(cell, src)
        return new(cell, src)
    end
end


function amg_precond(; max_levels = 10, max_coarse = 10, type = :smoothed_aggregation)

    gs_its = 1
    cyc = AlgebraicMultigrid.V()
    if type == :smoothed_aggregation
        m = smoothed_aggregation
    else
        m = ruge_stuben
    end
    gs = GaussSeidel(ForwardSweep(), gs_its)

    return AMGPreconditioner(m, max_levels = max_levels, max_coarse = max_coarse, presmoother = gs, postsmoother = gs, cycle = cyc)

end

#export run_battery 

function run_battery(init::InputFile,
    use_p2d::Bool       = true,
    extra_timing::Bool  = false,
    max_step::Int64      = nothing,
    linear_solver = :direct,
    general_ad::Bool    = false,
    use_groups::Bool    = false,
    kwarg...)

    sim, forces, state0, parameters, init, model = setup_sim(init, use_p2d = use_p2d, use_groups = use_groups, general_ad = general_ad)

    timesteps,cfg=prepare_simulate(init,linear_solver,model,sim,max_step)

    states, reports = simulate(sim, timesteps, forces = forces, config = cfg)

    extra = Dict(:model      => model,
                 :state0     => state0,
                 :parameters => parameters,
                 :init   => init,
                 :timesteps  => timesteps,
                 :config     => cfg,
                 :forces     => forces,
                 :simulator  => sim)

    return (states = states, reports = reports, extra = extra)
end

#Allows running run_battery with simple option for loading mat files
function run_battery(init::Symbol,
    use_p2d::Bool       = true,
    extra_timing::Bool  = false,
    max_step::Int64      = nothing,
    linear_solver = :direct,
    general_ad::Bool    = false,
    use_groups::Bool    = false,
    kwarg...)

    path=""
    suffix=".mat"
    return run_battery(MatlabFile(path*init*suffix),use_p2d,extra_timing,max_step,linear_solver,general_ad,use_groups,kwarg)
end

function prepare_simulate(init::JSONFile,
                          linear_solver,
                          model,
                          sim,
                          max_step)
    total = init.object["TimeStepping"]["totalTime"]
    n     = init.object["TimeStepping"]["N"]

    dt = total/n
    timesteps = rampupTimesteps(total, dt, 5);    
    
    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver]              = battery_linsolve(model, linear_solver)
    cfg[:debug_level]                = 0
    cfg[:max_residual]               = 1e20
    cfg[:min_nonlinear_iterations]   = 1
    cfg[:extra_timing]               = extra_timing
    cfg[:safe_mode]                  = false
    cfg[:error_on_incomplete]        = false
    cfg[:failure_cuts_timestep]      = true
    
    if false
        cfg[:info_level]               = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts]        = 0
    end

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    return timesteps,cfg
end

function prepare_simulate(init::MatlabFile,
                          linear_solver,
                          model,
                          sim,
                          max_step)
    steps        = size(init.object["schedule"]["step"]["val"], 1)
    alltimesteps = Vector{Float64}(undef, steps)
    time         = 0;
    end_step     = 0
    minE         = 3.2
    
    for i = 1 : steps
        alltimesteps[i] =  init.object["schedule"]["step"]["val"][i] #- time
        time = init.object["states"][i]["time"]
        E = init.object["states"][i]["Control"]["E"]
        if (E > minE + 0.001)
            end_step = i
        end
    end
    if !isnothing(max_step)
        end_step = min(max_step, end_step)
    end
    
    timesteps = alltimesteps
    
    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver]              = battery_linsolve(model, linear_solver)
    cfg[:debug_level]                = 0
    #cfg[:max_timestep_cuts]         = 0
    cfg[:max_residual]               = 1e20
    cfg[:min_nonlinear_iterations]   = 1
    cfg[:extra_timing]               = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode]                  = false
    cfg[:error_on_incomplete]        = true
    if false
        cfg[:info_level]               = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts]        = 0
    end

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    return timesteps,cfg
end



struct Constants
    F
    R
    hour
    function Constants()
        new(96485.3329,
            8.31446261815324,
            3600)
    end
end

struct SourceAtCell
    cell
    src
    function SourceAtCell(cell, src)
        new(cell, src)
    end 
end

function rampupTimesteps(time, dt, n = 8)

    ind = [8; collect(range(n, 1, step=-1))]
    dt_init = [dt/2^k for k in ind]
    cs_time = cumsum(dt_init)
    if any(cs_time .> time)
        dt_init = dt_init[cs_time .< time];
    end
    dt_left = time .- sum(dt_init)

    # Even steps
    dt_rem = dt*ones(floor(Int64, dt_left/dt));
    # Final ministep if present
    dt_final = time - sum(dt_init) - sum(dt_rem);
    # Less than to account for rounding errors leading to a very small
    # negative time-step.
    if dt_final <= 0
        dt_final = [];
    end
    # Combined timesteps
    dT = [dt_init; dt_rem; dt_final];

    return dT
end

function my_number_of_cells(model::MultiModel)
    
    cells = 0
    for smodel in model.models
        cells += number_of_cells(smodel.domain)
    end

    return cells
    
end

function convert_to_int_vector(x::Float64)
    vec = Int64.(Vector{Float64}([x]))
    return vec
end

function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(Vector{Float64}(x[:,1]))
    return vec
end
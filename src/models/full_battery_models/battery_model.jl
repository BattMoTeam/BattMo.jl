###################################################################
# In this module we define methods to handle the BatteryModel. This model
# is a base model for more specific full battery models like:
# - LithiumIonP2D
# 
# File structure:
#
#
###################################################################

export BatteryModel


abstract type BatteryModel end

####################
# Current function #
####################

function currentFun(t::T, inputI::T, tup::T = 0.1) where T
    val::T = 0.0
    if  t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t) 
    else
        val = inputI
    end
    return val
end


#############
# Utilities #
#############

function include_current_collectors(inputparams::InputParams)

    jsondict = inputparams.dict

    if haskey(jsondict, "include_current_collectors") && !jsondict["include_current_collectors"]
        include_cc = false
    else
        include_cc = true
    end
    
    return include_cc
    
end

function include_current_collectors(model)
    
    if haskey(model.models, :NeCc)
        include_cc = true
        @assert haskey(model.models, :PeCc)
    else
        include_cc = false
        @assert !haskey(model.models, :PeCc)
    end

    return include_cc
    
end

function rampupTimesteps(time::Real, dt::Real, n::Integer=8)

    ind = collect(range(n, 1, step = -1))
    dt_init = [dt / 2^k for k in ind]
    cs_time = cumsum(dt_init)
    if any(cs_time .> time)
        dt_init = dt_init[cs_time.<time]
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


struct SourceAtCell
    cell
    src
    function SourceAtCell(cell, src)
        new(cell, src)
    end
end

function convert_to_int_vector(x::Float64)
    vec = Int64.(Vector{Float64}([x]))
    return vec
end

function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(Vector{Float64}(x[:, 1]))
    return vec
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
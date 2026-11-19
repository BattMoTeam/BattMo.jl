# Julia side of the BattMo MCP server.
#
# Every public function takes and returns JSON strings, so the Python side never
# has to convert Julia types. Anything BattMo prints to stdout is captured and
# returned as a "log" field instead of reaching the MCP stdio channel.

module BattMoMCPBridge

using BattMo
using Logging
using Dates

const JSON = BattMo.JSON

# ---------------------------------------------------------------------------
# Run registry
# ---------------------------------------------------------------------------

mutable struct RunRecord
    id::String
    created::DateTime
    spec::Dict{String, Any}
    output::Any            # SimulationOutput or nothing
    status::String         # "success" | "incomplete" | "failed"
    message::String
    wall_time::Float64
end

const RUNS = Dict{String, RunRecord}()
const RUN_COUNTER = Ref(0)

const CATEGORIES = Dict(
    "cell_parameters" => "cell_parameters",
    "cycling_protocol" => "cycling_protocols",
    "model_settings" => "model_settings",
    "simulation_settings" => "simulation_settings",
    "solver_settings" => "solver_settings",
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

tojson(x) = JSON.json(sanitize(x))

parsejson(s::AbstractString) = JSON.parse(s; dicttype = Dict{String, Any})

# Make values JSON-safe (NaN/Inf are not valid JSON).
sanitize(x::AbstractFloat) = isfinite(x) ? x : nothing
sanitize(x::AbstractDict) = Dict{String, Any}(string(k) => sanitize(v) for (k, v) in x)
sanitize(x::AbstractArray{<:Number}) = ndims(x) == 1 ? [sanitize(v) for v in x] : [sanitize(collect(s)) for s in eachslice(x; dims = 1)]
sanitize(x::AbstractVector) = [sanitize(v) for v in x]
sanitize(x::Tuple) = [sanitize(v) for v in x]
sanitize(x::NamedTuple) = Dict{String, Any}(string(k) => sanitize(v) for (k, v) in pairs(x))
sanitize(x::Symbol) = string(x)
sanitize(x) = x

"""
Run `f()` while capturing stdout and log messages. Returns `(result, log, err)`,
where `err` is a string if `f` threw.
"""
function captured(f)
    path, io = mktemp()
    result = nothing
    err = nothing
    try
        redirect_stdout(io) do
            with_logger(SimpleLogger(io, Logging.Info)) do
                try
                    result = f()
                catch e
                    err = sprint(showerror, e)
                end
            end
        end
    finally
        flush(io)
        close(io)
    end
    log = read(path, String)
    rm(path; force = true)
    return result, strip_ansi(log), err
end

# Remove colour codes and OSC-8 hyperlink wrappers (ESC ] 8 ;; url ESC \) from terminal output.
strip_ansi(s::AbstractString) = replace(s, r"\e\[[0-9;]*[A-Za-z]" => "", r"\e\]8;;[^\e]*\e\x5c" => "")

function tail(s::AbstractString, n::Int = 4000)
    return length(s) <= n ? s : "…(truncated)…\n" * last(s, n)
end

function deep_merge!(base::AbstractDict, override::AbstractDict)
    for (k, v) in override
        if v isa AbstractDict && haskey(base, k) && base[k] isa AbstractDict
            deep_merge!(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end

is_bpx(d::AbstractDict) = haskey(d, "Parameterisation") && haskey(d, "Header")

"""
Turn a source spec into a `Dict` plus an optional BPX file path.

A source is either a default-set name (e.g. "chen_2020"), a path to a JSON file,
or an inline Dict.
"""
function resolve_source(category::String, source)
    if source isa AbstractDict
        return deepcopy(Dict{String, Any}(source)), nothing
    end
    source isa AbstractString || error("Source for $category must be a default-set name, a JSON file path or an object.")
    if isfile(source)
        d = JSON.parsefile(source; dicttype = Dict{String, Any})
        return d, (is_bpx(d) ? source : nothing)
    end
    folder = CATEGORIES[category]
    path = BattMo.parameter_file_path(folder, source; check = false)
    isfile(path) || error(
        "'$source' is neither an existing JSON file nor a default $category set. " *
            "Available default sets: $(join(default_set_names(folder), ", "))",
    )
    return JSON.parsefile(path; dicttype = Dict{String, Any}), nothing
end

function load_set(category::String, source, overrides)
    d, bpx_path = resolve_source(category, source)
    if !isnothing(bpx_path)
        set = category == "cell_parameters" ? load_cell_parameters(; from_bpx_file_path = bpx_path) :
            category == "cycling_protocol" ? load_cycling_protocol(; from_bpx_file_path = bpx_path) :
            error("BPX files can only be used for cell_parameters and cycling_protocol.")
        d = set.all
    end
    if !isnothing(overrides) && !isempty(overrides)
        deep_merge!(d, overrides)
    end
    return category == "cell_parameters" ? CellParameters(d) :
        category == "cycling_protocol" ? CyclingProtocol(d) :
        category == "model_settings" ? ModelSettings(d) :
        category == "simulation_settings" ? SimulationSettings(d) :
        SolverSettings(d)
end

function default_set_names(folder::String)
    dir = joinpath(BattMo.parameter_file_path(), folder)
    isdir(dir) || return String[]
    return sort([splitext(f)[1] for f in readdir(dir) if endswith(f, ".json")])
end

getspec(spec, key) = (v = get(spec, key, nothing); v === nothing || v == "" ? nothing : v)

"""
Build the model and a `Simulation` from a spec Dict. Returns `(sim, solver_settings)`.
"""
function build_simulation(spec::AbstractDict)
    base_model = something(getspec(spec, "base_model"), "LithiumIonBattery")
    model_settings = load_set("model_settings", something(getspec(spec, "model_settings"), "p2d"), getspec(spec, "model_settings_overrides"))
    model = BattMo.get_model(base_model, model_settings)

    cell = load_set("cell_parameters", something(getspec(spec, "cell_parameters"), "chen_2020"), getspec(spec, "cell_parameters_overrides"))
    protocol = load_set("cycling_protocol", something(getspec(spec, "cycling_protocol"), "cc_discharge"), getspec(spec, "cycling_protocol_overrides"))

    sim_src = getspec(spec, "simulation_settings")
    sim_ovr = getspec(spec, "simulation_settings_overrides")
    sim = if isnothing(sim_src) && isnothing(sim_ovr)
        Simulation(model, cell, protocol)
    else
        settings = if isnothing(sim_src)
            s = BattMo.get_default_simulation_settings(model)
            deep_merge!(s.all, sim_ovr)
            s
        else
            load_set("simulation_settings", sim_src, sim_ovr)
        end
        Simulation(model, cell, protocol; simulation_settings = settings)
    end

    solver_src = getspec(spec, "solver_settings")
    solver_ovr = getspec(spec, "solver_settings_overrides")
    solver = if isnothing(solver_src) && isnothing(solver_ovr)
        nothing
    elseif isnothing(solver_src)
        s = BattMo.get_default_solver_settings(model)
        deep_merge!(s.all, solver_ovr)
        s
    else
        load_set("solver_settings", solver_src, solver_ovr)
    end
    return sim, solver
end

function downsample_indices(n::Int, max_points::Int)
    (max_points <= 0 || n <= max_points) && return collect(1:n)
    idx = unique(round.(Int, range(1, n; length = max_points)))
    return idx
end

function window_indices(t::AbstractVector, t_start, t_end)
    lo = isnothing(t_start) ? -Inf : Float64(t_start)
    hi = isnothing(t_end) ? Inf : Float64(t_end)
    return [i for i in eachindex(t) if lo <= t[i] <= hi]
end

function get_run(run_id::String)
    haskey(RUNS, run_id) || error("Unknown run_id '$run_id'. Known runs: $(join(sort(collect(keys(RUNS))), ", "))")
    rec = RUNS[run_id]
    isnothing(rec.output) && error("Run '$run_id' has no output (status: $(rec.status)). Message: $(rec.message)")
    return rec
end

safe_last(v) = isempty(v) ? nothing : last(v)

function summarize_time_series(ts::AbstractDict)
    out = Dict{String, Any}()
    for key in ("Time", "Voltage", "Current", "CumulativeCapacity", "NetCapacity")
        haskey(ts, key) || continue
        v = ts[key]
        isempty(v) && continue
        finite = filter(isfinite, v)
        isempty(finite) && continue
        out[key] = Dict("first" => first(v), "last" => last(v), "min" => minimum(finite), "max" => maximum(finite))
    end
    return out
end

# Flatten nested state dict into "A/B/C" => size.
function flatten_states!(acc, d::AbstractDict, prefix = "")
    for (k, v) in d
        key = isempty(prefix) ? string(k) : prefix * "/" * string(k)
        if v isa AbstractDict
            flatten_states!(acc, v, key)
        elseif v isa AbstractArray
            acc[key] = collect(size(v))
        end
    end
    return acc
end

function lookup_state(states::AbstractDict, path::String)
    node = states
    for part in split(path, "/")
        (node isa AbstractDict && haskey(node, part)) || error("State quantity '$path' not found. Use list_state_quantities to see the available paths.")
        node = node[part]
    end
    return node
end

# ---------------------------------------------------------------------------
# Public API (JSON in, JSON out)
# ---------------------------------------------------------------------------

function battmo_info()
    return tojson(Dict(
        "battmo_version" => string(pkgversion(BattMo)),
        "battmo_path" => pkgdir(BattMo),
        "julia_version" => string(VERSION),
        "threads" => Threads.nthreads(),
    ))
end

function list_default_sets()
    result = Dict{String, Any}()
    for (category, folder) in CATEGORIES
        entries = Any[]
        for name in default_set_names(folder)
            path = BattMo.parameter_file_path(folder, name)
            md = try
                get(JSON.parsefile(path; dicttype = Dict{String, Any}), "Metadata", Dict{String, Any}())
            catch
                Dict{String, Any}()
            end
            push!(entries, Dict("name" => name, "title" => get(md, "Title", nothing), "description" => get(md, "Description", nothing), "source" => get(md, "Source", nothing), "models" => get(md, "Models", nothing)))
        end
        result[category] = entries
    end
    return tojson(result)
end

function get_parameter_set(category::String, source::String)
    haskey(CATEGORIES, category) || error("Unknown category '$category'. Use one of: $(join(sort(collect(keys(CATEGORIES))), ", "))")
    d, bpx = resolve_source(category, source)
    if !isnothing(bpx)
        d = load_set(category, source, nothing).all
    end
    return tojson(d)
end

function describe(name::String, view)
    _, log, err = captured() do
        isnothing(view) ? print_info(name) : print_info(name; view = view)
    end
    return tojson(Dict("text" => log, "error" => err))
end

function validate_inputs(spec_json::String)
    spec = parsejson(spec_json)
    sim, log, err = captured() do
        build_simulation(spec)
    end
    return tojson(Dict(
        "is_valid" => isnothing(err) && sim[1].is_valid,
        "error" => err,
        "log" => tail(log, 8000),
    ))
end

function cell_kpis(source_json::String, overrides_json::String)
    source = parsejson(source_json)["source"]
    overrides = parsejson(overrides_json)
    kpis, log, err = captured() do
        cell = load_set("cell_parameters", source, overrides)
        # compute_equilibrium_energy is deliberately not included: for chen_2020 it
        # returns about -492 "Wh" for a ~5 Ah cell, so its result can't be trusted yet.
        Dict{String, Any}(get_equilibrium_kpis(cell))
    end
    return tojson(Dict(
        "kpis" => kpis,
        "units" => "Masses in kg, volume in m^3, mass loadings in kg/m^2, capacity in Ah, mass composition in % of cell mass",
        "error" => err, "log" => tail(log, 2000),
    ))
end

"""
Decide whether a run ended properly. BattMo returns normally when the nonlinear solver
gives up (timestep cuts exhausted), with only the states up to that point. A run counts
as complete if it ended at a voltage limit or reached the planned end time.
"""
function assess_termination(output)
    ts = output.time_series
    t_end = ts["Time"][end]
    v_end = ts["Voltage"][end]
    protocol = output.input["CyclingProtocol"]
    lower = get(protocol, "LowerVoltageLimit", nothing)
    upper = get(protocol, "UpperVoltageLimit", nothing)
    tol = 0.05
    at_lower = !isnothing(lower) && v_end <= lower + tol
    at_upper = !isnothing(upper) && v_end >= upper - tol

    planned = output.simulation.time_steps
    t_planned = planned isa AbstractVector && !isempty(planned) ? sum(planned) : nothing
    reached_end = !isnothing(t_planned) && t_end >= 0.98 * t_planned

    jo = output.jutul_output
    n_reports = haskey(jo, :reports) ? length(jo[:reports]) : nothing
    n_states = length(jo[:states])

    # Cycling protocols: BattMo stops once the controller's cycle count reaches TotalNumberOfCycles.
    n_cycles = get(protocol, "TotalNumberOfCycles", 0)
    final_cycle = haskey(ts, "CycleNumber") ? ts["CycleNumber"][end] : nothing
    cycles_done = n_cycles isa Real && n_cycles > 0 && !isnothing(final_cycle) && final_cycle >= n_cycles

    completed = at_lower || at_upper || reached_end || cycles_done
    reason = if cycles_done
        "Completed all $n_cycles cycles."
    elseif at_lower
        "Reached lower voltage limit ($lower V)."
    elseif at_upper
        "Reached upper voltage limit ($upper V)."
    elseif reached_end
        "Reached planned end time."
    else
        "Stopped early at t = $(round(t_end; sigdigits = 4)) s, V = $(round(v_end; digits = 3)) V, away from the voltage limits " *
            "($(lower) / $(upper) V) and before the planned end ($(isnothing(t_planned) ? "unknown" : round(t_planned; sigdigits = 4)) s). " *
            "The nonlinear solver most likely failed to converge (timestep cuts exhausted). " *
            "Typical remedies: lower DRate, or retry with finer time stepping, e.g. " *
            "simulation_settings_overrides = {\"TimeStepDuration\": 10, \"RampUpSteps\": 20} (defaults for p2d: 50 s and 5)."
    end
    return Dict{String, Any}(
        "completed" => completed,
        "reason" => reason,
        "end_time_s" => t_end,
        "final_voltage" => v_end,
        "lower_voltage_limit" => lower,
        "upper_voltage_limit" => upper,
        "planned_end_time_s" => t_planned,
        "total_number_of_cycles" => n_cycles,
        "final_cycle_number" => final_cycle,
        "n_solver_reports" => n_reports,
        "n_stored_states" => n_states,
    )
end

function run_simulation(spec_json::String, max_points::Int)
    spec = parsejson(spec_json)
    RUN_COUNTER[] += 1
    run_id = "run_$(RUN_COUNTER[])"

    t0 = time()
    output, log, err = captured() do
        sim, solver = build_simulation(spec)
        accept_invalid = get(spec, "accept_invalid", false) === true
        if !sim.is_valid && !accept_invalid
            error("Input validation failed (see log). Fix the inputs or pass accept_invalid=true.")
        end
        isnothing(solver) ? solve(sim; accept_invalid, info_level = -1) :
            solve(sim; accept_invalid, solver_settings = solver, info_level = -1)
    end
    wall = time() - t0

    rec = RunRecord(run_id, now(), spec, output, "failed", something(err, ""), wall)
    result = Dict{String, Any}("run_id" => run_id, "wall_time_s" => round(wall; digits = 2))

    if !isnothing(output)
        ts = output.time_series
        nsteps = haskey(ts, "Time") ? length(ts["Time"]) : 0
        rec.status = nsteps == 0 ? "failed" : "success"
        result["n_time_steps"] = nsteps
        result["summary"] = summarize_time_series(ts)
        result["metrics"] = output.metrics
        result["metrics_units"] = "Capacity in Ah, energy in J (divide by 3600 for Wh)"
        if nsteps > 0
            idx = downsample_indices(nsteps, max_points)
            result["time_series"] = Dict(k => ts[k][idx] for k in ("Time", "Voltage", "Current", "CumulativeCapacity") if haskey(ts, k))
            result["time_series_note"] = "Downsampled to $(length(idx)) of $nsteps points; use get_time_series for more."
        end
        if nsteps > 0
            termination = assess_termination(output)
            result["termination"] = termination
            if !termination["completed"]
                rec.status = "incomplete"
                rec.message = termination["reason"]
            end
        end
    end
    result["status"] = rec.status
    !isnothing(err) && (result["error"] = err)
    result["log"] = tail(log, rec.status == "success" ? 1500 : 6000)
    RUNS[run_id] = rec
    return tojson(result)
end

function get_time_series(run_id::String, quantities_json::String, max_points::Int, t_start, t_end)
    rec = get_run(run_id)
    ts = rec.output.time_series
    quantities = parsejson(quantities_json)
    keys_ = isempty(quantities) ? sort(collect(keys(ts))) : String.(quantities)
    missing_ = [q for q in keys_ if !haskey(ts, q)]
    isempty(missing_) || error("Unknown quantities: $(join(missing_, ", ")). Available: $(join(sort(collect(keys(ts))), ", "))")
    win = window_indices(ts["Time"], t_start, t_end)
    sel = win[downsample_indices(length(win), max_points)]
    return tojson(Dict("run_id" => run_id, "n_points" => length(sel), "n_points_in_window" => length(win), "data" => Dict(q => ts[q][sel] for q in keys_)))
end

function get_metrics(run_id::String)
    rec = get_run(run_id)
    return tojson(Dict("run_id" => run_id, "metrics" => rec.output.metrics, "units" => "Capacity in Ah, energy in J (divide by 3600 for Wh), efficiency as a fraction"))
end

function list_state_quantities(run_id::String)
    rec = get_run(run_id)
    acc = flatten_states!(Dict{String, Any}(), rec.output.states)
    return tojson(Dict("run_id" => run_id, "quantities" => acc, "note" => "Sizes are [time, space(, radius)] for time-dependent states; coordinate arrays (Position, Radius) are not time-dependent."))
end

function get_state(run_id::String, path::String, time, max_points::Int)
    rec = get_run(run_id)
    arr = lookup_state(rec.output.states, path)
    t = rec.output.time_series["Time"]
    result = Dict{String, Any}("run_id" => run_id, "quantity" => path, "full_size" => collect(size(arr)))
    if ndims(arr) >= 2 && size(arr, 1) == length(t)
        ti = isnothing(time) ? length(t) : argmin(abs.(t .- Float64(time)))
        result["time"] = t[ti]
        result["time_index"] = ti
        slice = selectdim(arr, 1, ti)
        if ndims(slice) == 1
            idx = downsample_indices(length(slice), max_points)
            result["values"] = slice[idx]
            result["space_indices"] = idx
        else
            idx = downsample_indices(size(slice, 1), max_points)
            result["values"] = collect(slice[idx, :])
            result["space_indices"] = idx
            result["note"] = "Rows are spatial cells, columns are particle radial points (last column = surface)."
        end
    else
        idx = downsample_indices(length(arr), max_points)
        result["values"] = vec(arr)[idx]
    end
    return tojson(result)
end

function list_runs()
    out = [
        Dict("run_id" => r.id, "created" => string(r.created), "status" => r.status, "wall_time_s" => round(r.wall_time; digits = 2),
            "cell_parameters" => something(getspec(r.spec, "cell_parameters"), "chen_2020") isa AbstractString ? something(getspec(r.spec, "cell_parameters"), "chen_2020") : "<inline>",
            "cycling_protocol" => something(getspec(r.spec, "cycling_protocol"), "cc_discharge") isa AbstractString ? something(getspec(r.spec, "cycling_protocol"), "cc_discharge") : "<inline>")
            for r in sort(collect(values(RUNS)); by = r -> r.created)
    ]
    return tojson(Dict("runs" => out))
end

function get_run_inputs(run_id::String)
    rec = get_run(run_id)
    return tojson(Dict("run_id" => run_id, "spec" => rec.spec, "resolved_input" => rec.output.input.all))
end

function delete_run(run_id::String)
    haskey(RUNS, run_id) || error("Unknown run_id '$run_id'")
    delete!(RUNS, run_id)
    GC.gc()
    return tojson(Dict("deleted" => run_id))
end

function export_time_series_csv(run_id::String, path::String)
    rec = get_run(run_id)
    ts = rec.output.time_series
    cols = [k for k in ("Time", "Voltage", "Current", "CumulativeCapacity", "NetCapacity", "CycleNumber") if haskey(ts, k)]
    n = length(ts["Time"])
    mkpath(dirname(abspath(path)))
    open(path, "w") do io
        println(io, join(cols, ","))
        for i in 1:n
            println(io, join((ts[c][i] for c in cols), ","))
        end
    end
    return tojson(Dict("path" => abspath(path), "rows" => n, "columns" => cols))
end

end # module

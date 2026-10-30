using BattMo
using DelimitedFiles
using SHA
using TOML
using Test

# Acceptance tests for the BPX import. Unlike test_bpx.jl, which checks the conversion
# formulas, these tests check what a simulation does with a converted BPX file: that
# every BPX parameter reaches the model, that equivalent BPX inputs give the same
# results, and that BattMo agrees with PyBaMM on the same file. The fixtures and their
# provenance are listed in test/data/bpx/datasets.toml.

const BPX_DATA_DIR = joinpath(@__DIR__, "data", "bpx")
const BPX_DATASETS = TOML.parsefile(joinpath(BPX_DATA_DIR, "datasets.toml"))
const BPX_REGIONS = ("Negative electrode", "Separator", "Positive electrode")

bpx_fixture(dataset) = joinpath(BPX_DATA_DIR, BPX_DATASETS[dataset]["file"])
bpx_fixture(dataset, distribution) = joinpath(BPX_DATA_DIR, BPX_DATASETS[dataset]["files"][distribution]["file"])

# SHA-256 of a text file with LF line endings, so that CRLF checkouts give the same sum
sha256_lf(path) = bytes2hex(sha256(replace(read(path, String), "\r\n" => "\n")))

read_bpx_json(path) = BattMo.JSON.parsefile(path; dicttype = Dict{String, Any})

function write_bpx_json(data)
    path = joinpath(mktempdir(), "input_BPX.json")
    open(io -> BattMo.JSON.print(io, data), path, "w")
    return path
end

# Run `f` without printing the conversion reports, which these tests do not check
quietly(f) = last(Test.collect_test_logs(f))

# Evaluate a BPX function string (Python syntax, variable x) of a trusted test fixture
function bpx_function(expression::AbstractString)
    f = eval(Meta.parse("x -> " * replace(expression, "**" => "^")))
    return x -> Base.invokelatest(f, x)
end

tabulate(expression, xs) = Dict{String, Any}("x" => collect(xs), "y" => bpx_function(expression).(xs))

arrhenius_factor(activation_energy, T, reference_temperature) = exp(activation_energy / 8.31446261815324 * (1 / reference_temperature - 1 / T))

# Set the initial and ambient temperature of a BPX input in either layout
function set_bpx_temperature!(data, T)
    cell = data["Parameterisation"]["Cell"]
    for key in ("Initial temperature [K]", "Ambient temperature [K]")
        haskey(cell, key) && (cell[key] = T)
    end
    if haskey(data, "State")
        get!(data["State"], "Initial conditions", Dict{String, Any}())["Initial temperature [K]"] = T
        get!(data["State"], "Thermal environment", Dict{String, Any}())["Ambient temperature [K]"] = T
    end
    return data
end

as_curve(output) = (time = output.time_series["Time"], voltage = output.time_series["Voltage"], current = output.time_series["Current"])

# BattMo applies the electrode activation energies only with the Arrhenius temperature
# dependence, and the entropic change coefficients only with the sequential thermal model
# (which also turns on the Arrhenius temperature dependence and needs a P4D model)
function bpx_model_settings(default_set = "p2d"; arrhenius = false, thermal = false)
    model_settings = load_model_settings(; from_default_set = default_set)
    arrhenius && (model_settings["TemperatureDependence"] = "Arrhenius")
    thermal && (model_settings["ThermalModel"] = "Sequential")
    return model_settings
end

# BPX does not give the BattMo heat transfer coefficient. The largest one the BattMo schema
# allows keeps the cell close to its initial temperature.
const SURFACE_HEAT_TRANSFER_COEFFICIENT = 5000.0 # W.m-2.K-1

# BPX does not describe the pouch geometry and the current collectors that a P4D pouch
# model needs. They are taken from the xu_2015 pouch cell (a single layer).
const POUCH_GEOMETRY_KEYS = ("ElectrodeWidth", "ElectrodeLength", "TabsOnSameSide", "TabLength", "TabWidth", "ElectrodeGeometricSurfaceArea", "NumberOfLayersInParallel")

function set_pouch_geometry!(cell_parameters)
    pouch = load_cell_parameters(; from_default_set = "xu_2015")
    for key in POUCH_GEOMETRY_KEYS
        cell_parameters["Cell"][key] = pouch["Cell"][key]
    end
    for electrode in ("NegativeElectrode", "PositiveElectrode")
        cell_parameters[electrode]["CurrentCollector"] = deepcopy(pouch[electrode]["CurrentCollector"])
    end
    return cell_parameters
end

# Constant current discharge of a BPX file within its voltage cut-offs, at `current` (A)
# or at `drate`
function bpx_discharge(path; current = nothing, drate = nothing, model_settings = bpx_model_settings(), simulation_settings = load_simulation_settings(; from_default_set = "p2d"))
    cell_parameters, cycling_protocol = quietly() do
        load_cell_parameters(; from_bpx_file_path = path), load_cycling_protocol(; from_bpx_file_path = path)
    end
    if model_settings["ModelFramework"] == "P4D Pouch"
        set_pouch_geometry!(cell_parameters)
    end
    if haskey(model_settings, "ThermalModel")
        cell_parameters["Cell"]["SurfaceHeatTransferCoefficient"] = SURFACE_HEAT_TRANSFER_COEFFICIENT
    end
    cycling_protocol["DRate"] = isnothing(current) ? drate : current / compute_cell_theoretical_capacity(cell_parameters)
    sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)
    return as_curve(solve(sim; info_level = -1, include_initial_state = true))
end

function bpx_full_input_discharge(path; model_settings = Dict{String, Any}())
    input = quietly(() -> load_full_simulation_input(; from_bpx_file_path = path))
    merge!(input["ModelSettings"], model_settings)
    return as_curve(run_simulation(input; info_level = -1))
end

function interpolate_linear(t, v, tq)
    k = clamp(searchsortedlast(t, tq), 1, length(t) - 1)
    return v[k] + (v[k + 1] - v[k]) * (tq - t[k]) / (t[k + 1] - t[k])
end

# Largest voltage difference of two discharges over the time span they share
function max_voltage_difference(a, b)
    t_end = min(a.time[end], b.time[end])
    return maximum(abs(interpolate_linear(b.time, b.voltage, t) - v) for (t, v) in zip(a.time, a.voltage) if t <= t_end)
end

# Root mean square voltage difference at the times of `reference`, from `t_start` on
function voltage_rmse(result, reference; t_start)
    t_end = min(result.time[end], reference.time[end])
    window = findall(t -> t_start <= t <= t_end, reference.time)
    simulated = [interpolate_linear(result.time, result.voltage, t) for t in reference.time[window]]
    return sqrt(sum((simulated .- reference.voltage[window]) .^ 2) / length(window))
end

function pybamm_curve(name)
    entry = BPX_DATASETS["schmitt_2026"]["pybamm"]["curves"][name]
    table, _ = readdlm(joinpath(BPX_DATA_DIR, entry["file"]), ',', Float64; header = true)
    return (time = table[:, 1], voltage = table[:, 2])
end

# The resolution of the PyBaMM reference runs: 20 points per electrode and particle
function pybamm_comparison_settings(duration)
    settings = load_simulation_settings(; from_default_set = "p2d")
    settings["TimeStepDuration"] = clamp(duration / 300, 1.0, 500.0)
    for key in ("NegativeElectrodeCoatingGridPoints", "PositiveElectrodeCoatingGridPoints", "NegativeElectrodeParticleGridPoints", "PositiveElectrodeParticleGridPoints")
        settings[key] = 20
    end
    settings["SeparatorGridPoints"] = 10
    return settings
end

function same_parameters(a, b; rtol = 1.0e-12)
    if a isa AbstractDict && b isa AbstractDict
        return Set(keys(a)) == Set(keys(b)) && all(same_parameters(a[k], b[k]; rtol) for k in keys(a))
    elseif a isa Real && b isa Real
        return isapprox(a, b; rtol)
    elseif a isa AbstractVector && b isa AbstractVector
        return length(a) == length(b) && all(same_parameters(x, y; rtol) for (x, y) in zip(a, b))
    else
        return a == b
    end
end

without_metadata(cell_parameters) = Dict(k => v for (k, v) in cell_parameters.all if k != "Metadata")

@testset "BPX acceptance" begin

    @testset "fixtures match the dataset manifest" begin
        for (_, dataset) in BPX_DATASETS
            entries = haskey(dataset, "file") ? Any[dataset] : collect(values(get(dataset, "files", Dict())))
            append!(entries, values(get(get(dataset, "pybamm", Dict()), "curves", Dict())))
            for entry in entries
                @test sha256_lf(joinpath(BPX_DATA_DIR, entry["file"])) == entry["sha256"]
            end
        end
    end

    @testset "function strings that are not BPX expressions do not run (strict = $strict)" for strict in (false, true)
        marker = joinpath(mktempdir(), "marker.txt")
        data = read_bpx_json(bpx_fixture("nmc_pouch"))
        ocp = data["Parameterisation"]["Positive electrode"]["OCP [V]"]
        data["Parameterisation"]["Positive electrode"]["OCP [V]"] = "(touch(raw\"$marker\"); $ocp)"
        path = write_bpx_json(data)

        cell_parameters = try
            quietly(() -> load_cell_parameters(; from_bpx_file_path = path, bpx_options = (strict = strict,)))
        catch
            nothing
        end
        # The file is rejected when it is read
        @test isnothing(cell_parameters)
        # and in no case does its function string run
        if !isnothing(cell_parameters)
            try
                cycling_protocol = quietly(() -> load_cycling_protocol(; from_bpx_file_path = path))
                solve(Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol); info_level = -1)
            catch
            end
        end
        @test !isfile(marker)
    end

    @testset "BPX 1.0 files in the layout before the State section" begin
        @testset "NMC pouch cell with a BPX 1.0 header" begin
            legacy_path = bpx_fixture("nmc_pouch")
            data = read_bpx_json(legacy_path)
            data["Header"]["BPX"] = 1.0
            reference = quietly(() -> load_cell_parameters(; from_bpx_file_path = legacy_path))
            relabelled = quietly(() -> load_cell_parameters(; from_bpx_file_path = write_bpx_json(data)))
            @test relabelled["Electrolyte"]["Concentration"] == 1000
            @test same_parameters(without_metadata(relabelled), without_metadata(reference))
        end

        @testset "Schmitt 2026: published file and its BPX 1.1 conversion" begin
            published = quietly(() -> load_cell_parameters(; from_bpx_file_path = bpx_fixture("schmitt_2026", "v0_layout")))
            converted = quietly(() -> load_cell_parameters(; from_bpx_file_path = bpx_fixture("schmitt_2026", "v1")))
            @test published["Electrolyte"]["Concentration"] == 1200
            @test same_parameters(without_metadata(published), without_metadata(converted))
        end
    end

    @testset "repeated imports do not grow the schema cache" begin
        path = bpx_fixture("nmc_pouch")
        quietly(() -> load_cell_parameters(; from_bpx_file_path = path))
        if isdefined(BattMo.BPX, :LEAF_SCHEMA_CACHE)
            n = length(BattMo.BPX.LEAF_SCHEMA_CACHE)
            quietly(() -> load_cell_parameters(; from_bpx_file_path = path))
            @test length(BattMo.BPX.LEAF_SCHEMA_CACHE) == n
        end
    end

    @testset "tabulated functions read from a file simulate like function strings" begin
        path = bpx_fixture("nmc_pouch")
        data = read_bpx_json(path)
        parameterisation = data["Parameterisation"]
        # Dense near zero, where the negative electrode OCP is steep
        stoichiometry = sort(unique(vcat(range(0, 1; length = 1001), exp10.(range(-5, log10(0.05); length = 200)))))
        concentration = range(0, 4000; length = 401)

        tabulated = deepcopy(data)
        for electrode in ("Negative electrode", "Positive electrode")
            tabulated["Parameterisation"][electrode]["OCP [V]"] = tabulate(parameterisation[electrode]["OCP [V]"], stoichiometry)
        end
        for key in ("Conductivity [S.m-1]", "Diffusivity [m2.s-1]")
            tabulated["Parameterisation"]["Electrolyte"][key] = tabulate(parameterisation["Electrolyte"][key], concentration)
        end
        tabulated_path = write_bpx_json(tabulated)

        # At the reference temperature, so that the electrolyte activation energies,
        # which tables cannot carry, do not matter
        strings = bpx_discharge(path; current = 12.5)
        tables = bpx_discharge(tabulated_path; current = 12.5)
        @test max_voltage_difference(strings, tables) < 2.0e-3
        @test tables.time[end] ≈ strings.time[end] rtol = 5.0e-3

        # The output ends one time step before the voltage cut-off, so the full simulation
        # inputs are compared with each other rather than with the cut-off
        full_input_strings = bpx_full_input_discharge(path)
        full_input_tables = bpx_full_input_discharge(tabulated_path)
        @test max_voltage_difference(full_input_strings, full_input_tables) < 2.0e-3
        @test full_input_tables.time[end] ≈ full_input_strings.time[end] rtol = 5.0e-3
    end

    @testset "the transport efficiency of every region reaches the electrolyte" begin
        path = bpx_fixture("nmc_pouch")
        base = bpx_discharge(path; current = 12.5)
        @testset "$region" for region in BPX_REGIONS
            data = read_bpx_json(path)
            data["Parameterisation"][region]["Transport efficiency"] *= 0.1
            perturbed = bpx_discharge(write_bpx_json(data); current = 12.5)
            # Ten times less effective electrolyte transport in one region changes a 1C
            # discharge by far more than 2 mV
            @test max_voltage_difference(base, perturbed) > 2.0e-3
        end
    end

    @testset "electrode activation energies apply away from the reference temperature" begin
        T = 283.15
        data = set_bpx_temperature!(read_bpx_json(bpx_fixture("nmc_pouch")), T)
        reference_temperature = data["Parameterisation"]["Cell"]["Reference temperature [K]"]
        @test T != reference_temperature

        # The same rate constants and diffusivities at T, written with half the activation energies
        halved = deepcopy(data)
        for electrode in ("Negative electrode", "Positive electrode")
            section = halved["Parameterisation"][electrode]
            for (value_key, energy_key) in (
                    ("Reaction rate constant [mol.m-2.s-1]", "Reaction rate constant activation energy [J.mol-1]"),
                    ("Diffusivity [m2.s-1]", "Diffusivity activation energy [J.mol-1]"),
                )
                energy = section[energy_key]
                section[value_key] *= arrhenius_factor(energy, T, reference_temperature) / arrhenius_factor(energy / 2, T, reference_temperature)
                section[energy_key] = energy / 2
            end
        end
        path, halved_path = write_bpx_json(data), write_bpx_json(halved)

        @testset "Simulation with the Arrhenius temperature dependence" begin
            model_settings = bpx_model_settings(; arrhenius = true)
            a = bpx_discharge(path; current = 12.5, model_settings)
            b = bpx_discharge(halved_path; current = 12.5, model_settings)
            @test max_voltage_difference(a, b) < 0.5e-3
            @test a.time[end] ≈ b.time[end] rtol = 2.0e-3
        end

        @testset "load_full_simulation_input with the Arrhenius temperature dependence" begin
            model_settings = Dict{String, Any}("TemperatureDependence" => "Arrhenius")
            a = bpx_full_input_discharge(path; model_settings)
            b = bpx_full_input_discharge(halved_path; model_settings)
            @test max_voltage_difference(a, b) < 0.5e-3
            @test a.time[end] ≈ b.time[end] rtol = 2.0e-3
        end
    end

    @testset "entropic change coefficients apply away from the reference temperature" begin
        T = 283.15
        data = set_bpx_temperature!(read_bpx_json(bpx_fixture("nmc_pouch")), T)
        parameterisation = data["Parameterisation"]
        reference_temperature = parameterisation["Cell"]["Reference temperature [K]"]
        # Ten times the published value, so that the effect (about 15 mV) is well above the tolerance
        parameterisation["Positive electrode"]["Entropic change coefficient [V.K-1]"] = -1.0e-3

        # The same OCPs at T, with the entropic term written into the OCP functions
        folded = deepcopy(data)
        # The OCPs without their temperature dependence
        plain = deepcopy(data)
        for electrode in ("Negative electrode", "Positive electrode")
            section = folded["Parameterisation"][electrode]
            section["OCP [V]"] = "($(section["OCP [V]"])) + ($(T - reference_temperature)) * ($(section["Entropic change coefficient [V.K-1]"]))"
            section["Entropic change coefficient [V.K-1]"] = 0.0
            plain["Parameterisation"][electrode]["Entropic change coefficient [V.K-1]"] = 0.0
        end

        # The OCP with the entropic term folded in stays at T, while the sequential thermal
        # model, which BattMo only supports in P4D, applies the term at the simulated
        # temperature, which stays close to T
        model_settings = bpx_model_settings("p4d_pouch"; thermal = true)
        simulation_settings = load_simulation_settings(; from_default_set = "p4d_pouch")
        discharge(data) = bpx_discharge(write_bpx_json(data); drate = 1.0, model_settings, simulation_settings)
        given = discharge(data)
        with_folded_term = discharge(folded)
        without_term = discharge(plain)
        @test max_voltage_difference(with_folded_term, without_term) > 5.0e-3
        @test max_voltage_difference(given, with_folded_term) < 0.5e-3
    end

    @testset "an isothermal parameter set without thermal parameters simulates" begin
        path = bpx_fixture("schmitt_2026", "v1")
        cell_parameters = quietly(() -> load_cell_parameters(; from_bpx_file_path = path))
        @test compute_cell_theoretical_capacity(cell_parameters) ≈ 1.0309 rtol = 1.0e-3
        result = bpx_discharge(path; current = 1.0)
        @test result.voltage[end] ≈ 3.5 atol = 0.05
    end

    @testset "Schmitt 2026: BattMo reproduces PyBaMM" begin
        path = bpx_fixture("schmitt_2026", "v1")
        uniform = read_bpx_json(path)
        for region in BPX_REGIONS
            section = uniform["Parameterisation"][region]
            section["Transport efficiency"] = section["Porosity"]^1.5
        end
        paths = Dict("original" => path, "uniform" => write_bpx_json(uniform))

        # "uniform": one Bruggeman exponent (1.5) in all regions; "original": the published
        # exponents 1.86 / 4.53 / 1.68. An earlier importer with the uniform exponent agreed
        # with PyBaMM within 1.3 mV at 0.5 A and 4.8 mV at 2 A.
        @testset "$variant, $current A" for (variant, current, curve, tolerance) in (
                ("uniform", 0.5, "uniform_0p5A", 5.0e-3),
                ("uniform", 2.0, "uniform_2A", 10.0e-3),
                ("original", 0.5, "original_0p5A", 5.0e-3),
                ("original", 2.0, "original_2A", 10.0e-3),
            )
            reference = pybamm_curve(curve)
            settings = pybamm_comparison_settings(reference.time[end])
            result = bpx_discharge(paths[variant]; current, simulation_settings = settings)
            @test result.current[end] ≈ current rtol = 1.0e-3
            @test result.time[end] ≈ reference.time[end] rtol = 0.02
            @test voltage_rmse(result, reference; t_start = settings["RampUpTime"]) < tolerance
        end
    end

end

using BattMo
using Test

# Recursive comparison of parameter dictionaries with a tolerance on numbers
function approx_equal(a, b; rtol = 1.0e-10)
    if a isa AbstractDict && b isa AbstractDict
        return keys(a) == keys(b) && all(approx_equal(a[k], b[k]; rtol) for k in keys(a))
    elseif a isa Real && b isa Real
        return isapprox(a, b; rtol)
    elseif a isa AbstractVector && b isa AbstractVector
        return length(a) == length(b) && all(approx_equal(x, y; rtol) for (x, y) in zip(a, b))
    else
        return a == b
    end
end

@testset "BPX parser" begin

    BPX = BattMo.BPX
    nmc_file_path = joinpath(@__DIR__, "data", "jsonfiles", "nmc_pouch_cell_BPX.json")
    lfp_file_path = joinpath(@__DIR__, "data", "jsonfiles", "lfp_18650_cell_BPX.json")

    # The NMC test file in the BPX 1.x layout
    nmc_v1() = BPX.migrate_legacy_bpx(BattMo.JSON.parsefile(nmc_file_path))

    @testset "conversion of the NMC pouch cell" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path)

        @test isa(cell_parameters, CellParameters)

        cell = cell_parameters["Cell"]
        @test cell["NominalCapacity"] == 12.5
        # The 34 electrode pairs are represented by a single layer of the total area
        @test cell["ElectrodeGeometricSurfaceArea"] ≈ 0.016808 * 34
        @test cell["NumberOfLayersInParallel"] == 1
        @test cell["DoubleCoatedElectrodes"] == false
        @test cell["Case"] == "Pouch"
        @test cell["ReferenceTemperature"] == 298.15

        # The cell mass computations count every BPX coating exactly once
        @test BattMo.compute_electrode_coating_mass(cell_parameters, "PositiveElectrode") ≈
            cell_parameters["PositiveElectrode"]["Coating"]["EffectiveDensity"] * 0.016808 * 34 * 5.23e-5

        ne_am = cell_parameters["NegativeElectrode"]["ActiveMaterial"]
        pe_am = cell_parameters["PositiveElectrode"]["ActiveMaterial"]

        # Stoichiometric window: the negative electrode is delithiated at SOC 0, the
        # positive electrode is lithiated
        @test ne_am["StoichiometricCoefficientAtSOC0"] == 0.005504
        @test ne_am["StoichiometricCoefficientAtSOC100"] == 0.75668
        @test pe_am["StoichiometricCoefficientAtSOC0"] == 0.9621
        @test pe_am["StoichiometricCoefficientAtSOC100"] == 0.42424

        # Reaction rate constant converted from mol.m-2.s-1 (BPX) to the Newman
        # convention used by BattMo
        @test ne_am["ReactionRateConstant"] ≈ 5.199e-6 / (29730 * sqrt(1000))

        # Bruggeman coefficients recovered from porosity and transport efficiency
        @test cell_parameters["NegativeElectrode"]["Coating"]["BruggemanCoefficient"] ≈ log(0.128) / log(0.253991)
        @test cell_parameters["Separator"]["BruggemanCoefficient"] ≈ log(0.3222) / log(0.47)

        # The coating effective density reproduces the BPX porosity
        ne = cell_parameters["NegativeElectrode"]
        @test ne["Coating"]["EffectiveDensity"] / ne_am["Density"] ≈ 1 - 0.253991

        # The active material volume fraction reproduces the BPX definition
        # surface_area * radius / 3, the rest of the solid is lumped into the binder
        @test ne_am["MassFraction"] ≈ 499522 * 4.12e-6 / 3 / (1 - 0.253991)
        @test ne["Binder"]["MassFraction"] ≈ 1 - ne_am["MassFraction"]
        @test ne["ConductiveAdditive"]["MassFraction"] == 0.0
        @test ne["Binder"]["ElectronicConductivity"] == ne_am["ElectronicConductivity"]
        vf, vfs, _ = BattMo.compute_volume_fraction(ne)
        @test vf * vfs[1] ≈ 499522 * 4.12e-6 / 3

        # Function strings are rewritten to BattMo conventions
        @test occursin("(c / cmax)", ne_am["OpenCircuitPotential"])
        @test occursin("(c / 1000)", cell_parameters["Electrolyte"]["IonicConductivity"])
        @test !occursin("**", cell_parameters["Electrolyte"]["IonicConductivity"])

        # Electrolyte activation energies are folded in as Arrhenius factors
        @test occursin("exp(17100", cell_parameters["Electrolyte"]["IonicConductivity"])

        # Scalar entropic coefficient is passed through
        @test pe_am["EntropyChange"] == -1.0e-4
    end

    @testset "tabulated data is passed through" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = lfp_file_path)

        entropy_change = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["EntropyChange"]
        @test isa(entropy_change, AbstractDict)
        @test haskey(entropy_change, "x") && haskey(entropy_change, "y")

        @test cell_parameters["Cell"]["Case"] == "Cylindrical"
    end

    @testset "conversion report" begin
        # All findings are grouped in one warning and one info message
        logs, _ = Test.collect_test_logs() do
            BPX.parse_bpx_to_cell_parameters(nmc_v1())
        end
        @test count(l -> l.level == Base.CoreLogging.Warn, logs) == 1
        @test count(l -> l.level == Base.CoreLogging.Info, logs) == 1
        warning = only(filter(l -> l.level == Base.CoreLogging.Warn, logs)).message
        info = only(filter(l -> l.level == Base.CoreLogging.Info, logs)).message

        # The thermal model difference is a warning, with the volumes involved
        @test occursin("Differences between the BPX and BattMo models", warning)
        @test occursin("lumped heat balance", warning) && occursin("57.4 % of the cell volume", warning)
        # Documented approximations and the operating conditions are information
        @test occursin("lumped cell density (1847 kg.m-3)", info)
        @test occursin("34 electrode pairs", info)
        @test occursin("Lower voltage cut-off [V] = 2.7 → CyclingProtocol[\"LowerVoltageLimit\"]", info)
        @test occursin("Initial state-of-charge = 1 → CyclingProtocol[\"InitialStateOfCharge\"]", info)
        @test occursin("Volume [m3]: volume of the BPX lumped thermal model", info)
        @test occursin("inferred from the header", info)
    end

    @testset "schema validation reports all violations" begin
        bpx = nmc_v1()
        ne = bpx["Parameterisation"]["Negative electrode"]
        # A key with a non-standard unit, a wrong type and a missing required parameter
        ne["Thickness [um]"] = ne["Thickness [m]"] * 1.0e6
        delete!(ne, "Thickness [m]")
        bpx["Parameterisation"]["Separator"]["Porosity"] = "0.47"
        delete!(bpx["Parameterisation"]["Cell"], "Nominal cell capacity [A.h]")

        issues = BPX.schema_issues(bpx)
        @test any(occursin("Negative electrode → Thickness [um]: not a parameter of the BPX standard", i) for i in issues)
        @test any(occursin("Negative electrode → Thickness [m]: missing required parameter", i) for i in issues)
        @test any(occursin("Separator → Porosity: invalid value \"0.47\"", i) for i in issues)
        @test any(occursin("Cell → Nominal cell capacity [A.h]: missing required parameter", i) for i in issues)

        # Non-standard units are not converted: the key is ignored and the parameter is
        # undetermined
        delete!(bpx["Parameterisation"]["Separator"], "Porosity")
        bpx["Parameterisation"]["Separator"]["Porosity"] = 0.47
        converted = @test_logs (:warn, r"Violations of the BPX 1\.1\.1 standard:.*Thickness \[um\]: not a parameter.*set to 0\.0.*NegativeElectrode\.Coating\.Thickness"s) match_mode = :any BPX.parse_bpx_to_cell_parameters(bpx)
        @test converted["NegativeElectrode"]["Coating"]["Thickness"] == 0.0

        # Strict mode raises an error listing all violations
        @test_throws "Thickness [um]: not a parameter" BPX.parse_bpx_to_cell_parameters(bpx; strict = true)
        @test_throws "Nominal cell capacity [A.h]: missing required parameter" BPX.parse_bpx_to_cell_parameters(bpx; strict = true)

        # Without validation, unknown keys are still reported
        @test_logs (:warn, r"Keys that are not part of the BPX standard \(ignored\):\n.*Thickness \[um\]") match_mode = :any BPX.parse_bpx_to_cell_parameters(bpx; validate = false)

        # The bundled files conform to the schema
        @test isempty(BPX.schema_issues(nmc_v1()))
        @test isempty(BPX.schema_issues(BPX.migrate_legacy_bpx(BattMo.JSON.parsefile(lfp_file_path))))
    end

    @testset "consistency checks" begin
        # The OCPs at the stoichiometry limits of the NMC example give 4.2018 V, above the
        # 4.2 V cut-off (the Python BPX package gives the same warning); in strict mode
        # this is still only a warning
        @test_logs (:warn, r"maximum voltage given by the OCPs at the stoichiometry limits \(4\.2018 V\)") match_mode = :any BPX.parse_bpx_to_cell_parameters(nmc_v1(); strict = true)

        report = BPX.ConversionReport("test")
        bpx = nmc_v1()
        bpx["Parameterisation"]["Cell"]["Upper voltage cut-off [V]"] = 4.3
        bpx["Parameterisation"]["Cell"]["Lower voltage cut-off [V]"] = 3.0
        bpx["State"]["Initial conditions"]["Initial state-of-charge"] = 1.2
        BPX.check_consistency!(report, bpx)
        consistency = BPX.entries(report, :consistency)
        @test !any(occursin("maximum voltage", c) for c in consistency)
        @test any(occursin("minimum voltage", c) && occursin("below the lower voltage cut-off (3.0 V)", c) for c in consistency)
        @test any(occursin("Initial state-of-charge: 1.2 lies outside [0, 1]", c) for c in consistency)

        # An active material volume fraction larger than the solid volume fraction
        report = BPX.ConversionReport("test")
        @test BPX.compute_active_mass_fraction(1.0e6, 3.0e-6, 0.3, report, "electrode") == 1.0
        @test any(occursin("exceeds the solid volume fraction", c) for c in BPX.entries(report, :consistency))
    end

    @testset "BPX function strings" begin
        @test BPX.evaluate_bpx_value("2 * x**2 + exp(-x) - tanh(x / 2)", 0.5) ≈ 2 * 0.25 + exp(-0.5) - tanh(0.25)
        @test BPX.evaluate_bpx_value(Dict("x" => [0.0, 1.0], "y" => [1.0, 3.0]), 0.25) ≈ 1.5
        @test BPX.evaluate_bpx_value(3.0, 0.1) == 3.0

        # Only the operations allowed by BPX; nothing else is evaluated
        _, issue = BPX.parse_bpx_expression("sin(x)")
        @test occursin("`sin`", issue)
        _, issue = BPX.parse_bpx_expression("x + y")
        @test occursin("unknown variable `y`", issue)
        @test isnothing(BPX.evaluate_bpx_value("run(`ls`)", 0.5))

        bpx = nmc_v1()
        bpx["Parameterisation"]["Positive electrode"]["OCP [V]"] = "4.2 - sin(x)"
        @test_logs (:warn, r"Positive electrode → OCP \[V\]: the function string uses `sin`") match_mode = :any BPX.parse_bpx_to_cell_parameters(bpx)
    end

    @testset "missing BPX parameters are zero-filled" begin
        bpx = BattMo.JSON.parsefile(nmc_file_path)
        cell = bpx["Parameterisation"]["Cell"]
        ne = bpx["Parameterisation"]["Negative electrode"]
        delete!(cell, "Nominal cell capacity [A.h]")
        delete!(cell, "Density [kg.m-3]")
        delete!(cell, "Specific heat capacity [J.K-1.kg-1]")
        delete!(ne, "Particle radius [m]")
        delete!(ne, "Transport efficiency")
        delete!(ne, "OCP [V]")
        delete!(ne, "Entropic change coefficient [V.K-1]")

        converted = @test_logs (:warn, r"Parameters that could not be determined and were set to 0\.0") match_mode = :any BPX.parse_bpx_to_cell_parameters(bpx)

        @test converted["Cell"]["NominalCapacity"] == 0.0

        ne_converted = converted["NegativeElectrode"]
        @test ne_converted["ActiveMaterial"]["ParticleRadius"] == 0.0
        @test ne_converted["ActiveMaterial"]["OpenCircuitPotential"] == 0.0
        @test ne_converted["ActiveMaterial"]["EntropyChange"] == 0.0
        @test ne_converted["ActiveMaterial"]["SpecificHeatCapacity"] == 0.0

        # Derived parameters with missing inputs are zero-filled as well
        @test ne_converted["Coating"]["BruggemanCoefficient"] == 0.0
        @test ne_converted["ActiveMaterial"]["ElectronicConductivity"] == 0.0
        @test ne_converted["ActiveMaterial"]["Density"] == 0.0
        @test ne_converted["Coating"]["EffectiveDensity"] == 0.0
        @test converted["Separator"]["Density"] == 0.0
        @test converted["PositiveElectrode"]["ActiveMaterial"]["Density"] == 0.0

        # Parameters that are present stay converted
        @test ne_converted["Coating"]["Thickness"] ≈ 5.62e-5
        @test converted["PositiveElectrode"]["Coating"]["BruggemanCoefficient"] ≈ log(0.1462) / log(0.277493)
        @test converted["Electrolyte"]["Concentration"] == 1000

        # A missing section zero-fills all its parameters instead of erroring
        delete!(bpx["Parameterisation"], "Separator")
        converted_no_separator = BPX.parse_bpx_to_cell_parameters(bpx)
        @test converted_no_separator["Separator"]["Thickness"] == 0.0
        @test converted_no_separator["Separator"]["Porosity"] == 0.0
        @test converted_no_separator["Separator"]["BruggemanCoefficient"] == 0.0
    end

    @testset "BPX versions" begin
        # The bundled test files use the legacy BPX 0.1 layout and are converted
        legacy = BattMo.JSON.parsefile(nmc_file_path)
        reference = @test_logs (:info, r"legacy BPX 0\.1\.0 format") match_mode = :any BPX.parse_bpx_to_cell_parameters(legacy)
        @test reference["Electrolyte"]["Concentration"] == 1000
        # The lumped thermal conductivity survives the conversion
        @test reference["Electrolyte"]["ThermalConductivity"] == 2.04

        migrated = BPX.migrate_legacy_bpx(legacy)
        @test haskey(legacy["Parameterisation"]["Electrolyte"], "Initial concentration [mol.m-3]") # input not mutated
        @test migrated["Header"]["BPX"] == string(BPX.BPX_SCHEMA_VERSION)
        @test migrated["State"]["Initial conditions"]["Initial electrolyte concentration [mol.m-3]"] == 1000
        @test migrated["State"]["Initial conditions"]["Initial temperature [K]"] == 298.15
        @test migrated["State"]["Thermal environment"]["Ambient temperature [K]"] == 298.15
        @test !haskey(migrated["Parameterisation"]["Electrolyte"], "Initial concentration [mol.m-3]")
        @test !haskey(migrated["Parameterisation"]["Cell"], "Thermal conductivity [W.m-1.K-1]")
        @test migrated["Parameterisation"]["User-defined"]["Thermal conductivity [W.m-1.K-1]"] == 2.04

        # A BPX 1.x input gives the same parameters
        @test BPX.parse_bpx_to_cell_parameters(migrated; strict = true) == reference

        # A numeric version field is accepted, as in the Python BPX package
        numeric = deepcopy(migrated)
        numeric["Header"]["BPX"] = 1.1
        @test BPX.validate_bpx(BPX.prepare_bpx_input(numeric, BPX.ConversionReport("test")); strict = true)

        # Inputs newer than the bundled schema are flagged
        newer = deepcopy(migrated)
        newer["Header"]["BPX"] = "1.2.0"
        @test_logs (:info, r"newer than the BPX 1\.1\.1 standard") match_mode = :any BPX.parse_bpx_to_cell_parameters(newer; validate = false)

        malformed = deepcopy(migrated)
        malformed["Header"]["BPX"] = "latest"
        @test_throws "version field is missing or malformed" BPX.parse_bpx_to_cell_parameters(malformed)

        # The BPX reference temperature sets the BattMo reference temperature and the
        # Arrhenius reference of the electrolyte functions
        warm = deepcopy(migrated)
        warm["Parameterisation"]["Cell"]["Reference temperature [K]"] = 308.15
        converted_warm = BPX.parse_bpx_to_cell_parameters(warm; strict = true)
        @test converted_warm["Cell"]["ReferenceTemperature"] == 308.15
        @test occursin("1.0 / 308.15", converted_warm["Electrolyte"]["IonicConductivity"])
    end

    @testset "unsupported BPX features" begin
        # Blended electrodes cannot be represented
        blended = nmc_v1()
        pe = blended["Parameterisation"]["Positive electrode"]
        particle_keys = ["Minimum stoichiometry", "Maximum stoichiometry", "Maximum concentration [mol.m-3]", "Particle radius [m]", "Surface area per unit volume [m-1]", "Diffusivity [m2.s-1]", "OCP [V]", "Reaction rate constant [mol.m-2.s-1]"]
        pe["Particle"] = Dict("Large" => Dict(k => pe[k] for k in particle_keys), "Small" => Dict(k => pe[k] for k in particle_keys))
        foreach(k -> delete!(pe, k), particle_keys)
        @test_throws "blended electrode" BPX.parse_bpx_to_cell_parameters(blended)

        # OCP hysteresis: the equilibrium OCP is used
        hysteresis = nmc_v1()
        hysteresis["Parameterisation"]["Negative electrode"]["OCP (lithiation) [V]"] = 0.1
        hysteresis["Parameterisation"]["Negative electrode"]["OCP (delithiation) [V]"] = 0.12
        hysteresis["Parameterisation"]["Negative electrode"]["OCP hysteresis decay constant"] = 10.0
        converted = @test_logs (:warn, r"BattMo has no OCP hysteresis model") match_mode = :any BPX.parse_bpx_to_cell_parameters(hysteresis; strict = true)
        @test occursin("(c / cmax)", converted["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"])

        # Degradation state
        degraded = nmc_v1()
        degraded["State"]["Degradation"] = Dict{String, Any}("LAM: Negative electrode" => 0.0, "LAM: Positive electrode" => 0.05, "LLI" => 0.0)
        @test_logs (:warn, r"State → Degradation: the degradation state .* is not supported") match_mode = :any BPX.parse_bpx_to_cell_parameters(degraded; strict = true)

        # Reduced models
        spme = nmc_v1()
        spme["Header"]["Model"] = "SPMe"
        @test_logs (:warn, r"parameterised for the SPMe model. BattMo simulates the full P2D") match_mode = :any BPX.parse_bpx_to_cell_parameters(spme; strict = true)

        # Activation energy with tabulated electrolyte data
        tabulated = nmc_v1()
        tabulated["Parameterisation"]["Electrolyte"]["Diffusivity [m2.s-1]"] = Dict("x" => [0.0, 2000.0], "y" => [4.0e-10, 2.0e-10])
        @test_logs (:warn, r"activation energy \(17100 J.mol-1\) cannot be combined with tabulated data") match_mode = :any BPX.parse_bpx_to_cell_parameters(tabulated)
    end

    @testset "cell case and options of load_cell_parameters" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path, bpx_options = (cell_case = "Cylindrical", strict = true))
        @test cell_parameters["Cell"]["Case"] == "Cylindrical"

        no_case = nmc_v1()
        no_case["Header"]["Title"] = "Example cell"
        no_case["Header"]["Description"] = "Example cell"
        converted = @test_logs (:info, r"could not be inferred from the header") match_mode = :any BPX.parse_bpx_to_cell_parameters(no_case)
        @test !haskey(converted["Cell"], "Case")
    end

    @testset "export to BPX" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path)
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        cycling_protocol["LowerVoltageLimit"] = 2.7
        cycling_protocol["UpperVoltageLimit"] = 4.2

        bpx = BPX.convert_to_bpx(cell_parameters; cycling_protocol, strict = true)
        @test isempty(BPX.schema_issues(bpx))

        parameterisation = bpx["Parameterisation"]
        ne = parameterisation["Negative electrode"]
        @test ne["Reaction rate constant [mol.m-2.s-1]"] ≈ 5.199e-6
        @test ne["Conductivity [S.m-1]"] ≈ 0.222
        @test ne["Transport efficiency"] ≈ 0.128
        @test ne["Porosity"] ≈ 0.253991
        @test ne["Minimum stoichiometry"] == 0.005504
        @test parameterisation["Positive electrode"]["Maximum stoichiometry"] == 0.9621
        @test parameterisation["Electrolyte"]["Conductivity activation energy [J.mol-1]"] == 17100
        @test !occursin("exp(17100", parameterisation["Electrolyte"]["Conductivity [S.m-1]"])
        @test occursin("**", parameterisation["Electrolyte"]["Conductivity [S.m-1]"])
        @test occursin(r"\bx\b", ne["OCP [V]"]) && !occursin("cmax", ne["OCP [V]"])
        @test parameterisation["Cell"]["Electrode area [m2]"] ≈ 0.016808 * 34
        @test parameterisation["Cell"]["Number of electrode pairs connected in parallel to make a cell"] == 1
        @test parameterisation["Cell"]["Density [kg.m-3]"] ≈ 1847
        @test parameterisation["Cell"]["Upper voltage cut-off [V]"] == 4.2
        @test bpx["State"]["Initial conditions"]["Initial electrolyte concentration [mol.m-3]"] == 1000

        # Importing the exported parameter set gives the original BattMo parameters
        @test approx_equal(BPX.parse_bpx_to_cell_parameters(bpx; strict = true), cell_parameters.all)

        # Without a cycling protocol the required voltage cut-offs are missing
        @test_throws "Lower voltage cut-off [V]: missing required parameter" BPX.convert_to_bpx(cell_parameters; strict = true)

        # write_bpx writes a JSON file that can be loaded again
        # (the temporary directory is removed at exit; the parsed file can stay
        # memory-mapped on Windows, so it is not deleted here)
        path = joinpath(mktempdir(), "exported_BPX.json")
        write_bpx(path, cell_parameters; cycling_protocol)
        reloaded = load_cell_parameters(; from_bpx_file_path = path, bpx_options = (strict = true,))
        @test approx_equal(reloaded.all, cell_parameters.all)

        # Parameter sets that are not from BPX: BattMo features without a BPX counterpart
        # are reported
        chen = load_cell_parameters(; from_default_set = "chen_2020")
        logs, chen_bpx = Test.collect_test_logs() do
            BPX.convert_to_bpx(chen; cycling_protocol)
        end
        messages = join((l.message for l in logs), "\n")
        @test occursin(r"\bx\b", chen_bpx["Parameterisation"]["Negative electrode"]["OCP [V]"])
        @test occursin("NegativeElectrode.CurrentCollector.Thickness: not exported", messages)
        @test occursin("differs from the one BPX derives from surface area × radius / 3", messages)
    end

    @testset "simulation reproduces the BPX validation data" begin
        bpx = BattMo.JSON.parsefile(nmc_file_path)
        validation = bpx["Validation"]["1C discharge"]
        t_ref = Float64.(validation["Time [s]"])
        v_ref = Float64.(validation["Voltage [V]"])
        current = -validation["Current [A]"][end]

        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path)
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        cycling_protocol["LowerVoltageLimit"] = 2.7
        cycling_protocol["UpperVoltageLimit"] = 4.2
        cycling_protocol["InitialStateOfCharge"] = 1.0

        # The DRate is relative to the theoretical cell capacity, which must equal the
        # capacity implied by the BPX parameters
        sim = Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol)
        capacity = BattMo.computeCellCapacity(sim.model.multimodel) / 3600
        @test capacity ≈ 13.19 atol = 0.01
        cycling_protocol["DRate"] = current / capacity

        output = solve(Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol); info_level = -1)
        t = output.time_series["Time"]
        v = output.time_series["Voltage"]

        # Discharge time to the lower cut-off
        @test t[end] ≈ t_ref[end] rtol = 0.02

        function interpolate(tt)
            k = clamp(searchsortedlast(t, tt), 1, length(t) - 1)
            return v[k] + (v[k + 1] - v[k]) * (tt - t[k]) / (t[k + 1] - t[k])
        end
        mask = t_ref .<= t[end]
        error = interpolate.(t_ref[mask]) .- v_ref[mask]
        @test sqrt(sum(error .^ 2) / length(error)) < 0.025
    end

    @testset "converted parameters validate and simulate" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path)

        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        cycling_protocol["LowerVoltageLimit"] = 2.7
        cycling_protocol["UpperVoltageLimit"] = 4.2

        # Keep the solve short.
        time_steps = [1.0]

        sim = Simulation(LithiumIonBattery(), cell_parameters, cycling_protocol; time_steps)
        @test sim.is_valid === true

        output = solve(sim; info_level = -1)
        @test haskey(output.time_series, "Voltage")
    end

end

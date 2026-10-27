using BattMo
using Test

@testset "BPX parser" begin

    nmc_file_path = joinpath(@__DIR__, "data", "jsonfiles", "nmc_pouch_cell_BPX.json")
    lfp_file_path = joinpath(@__DIR__, "data", "jsonfiles", "lfp_18650_cell_BPX.json")

    @testset "conversion of the NMC pouch cell" begin
        cell_parameters = load_cell_parameters(; from_bpx_file_path = nmc_file_path)

        @test isa(cell_parameters, CellParameters)

        cell = cell_parameters["Cell"]
        @test cell["NominalCapacity"] == 12.5
        @test cell["ElectrodeGeometricSurfaceArea"] ≈ 0.016808 * 34
        @test cell["NumberOfLayersInParallel"] == 34
        @test cell["Case"] == "Pouch"

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

    @testset "non-standard units are not converted" begin
        # BPX fixes the unit of every parameter; a key with another unit is not BPX
        # compliant, so it is flagged by the schema validation and ignored
        bpx = BattMo.JSON.parsefile(nmc_file_path)
        ne = bpx["Parameterisation"]["Negative electrode"]
        ne["Thickness [um]"] = ne["Thickness [m]"] * 1.0e6
        delete!(ne, "Thickness [m]")

        converted = @test_logs (:warn, r"does not conform to the BPX") (:warn, r"Negative electrode.*were ignored: Thickness \[um\]") (:warn, r"set to 0\.0:.*NegativeElectrode\.Coating\.Thickness") match_mode = :any BattMo.BPX.parse_bpx_to_cell_parameters(bpx)
        @test converted["NegativeElectrode"]["Coating"]["Thickness"] == 0.0
        @test_throws "does not conform to the BPX" BattMo.BPX.parse_bpx_to_cell_parameters(bpx; strict = true)
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

        converted = @test_logs (:warn, r"could not be determined from the BPX input and were set to 0\.0") match_mode = :any BattMo.BPX.parse_bpx_to_cell_parameters(bpx)

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
        converted_no_separator = BattMo.BPX.parse_bpx_to_cell_parameters(bpx)
        @test converted_no_separator["Separator"]["Thickness"] == 0.0
        @test converted_no_separator["Separator"]["Porosity"] == 0.0
        @test converted_no_separator["Separator"]["BruggemanCoefficient"] == 0.0
    end

    @testset "BPX versions and schema validation" begin
        BPX = BattMo.BPX

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

        # The converted files conform to the BPX schema
        @test BPX.validate_bpx(migrated; strict = true)
        @test BPX.validate_bpx(BPX.migrate_legacy_bpx(BattMo.JSON.parsefile(lfp_file_path)); strict = true)

        # A BPX 1.x input gives the same parameters, and its State entries are reported
        converted = @test_logs (:info, r"Initial state-of-charge, Initial temperature") match_mode = :any BPX.parse_bpx_to_cell_parameters(migrated; strict = true)
        @test converted == reference

        # A non-zero degradation state is reported as unsupported
        degraded = deepcopy(migrated)
        degraded["State"]["Degradation"] = Dict{String, Any}("LAM: Negative electrode" => 0.0, "LAM: Positive electrode" => 0.05, "LLI" => 0.0)
        @test_logs (:warn, r"non-zero degradation state") match_mode = :any BPX.parse_bpx_to_cell_parameters(degraded; strict = true)

        # Schema violations warn, or throw in strict mode
        invalid = deepcopy(migrated)
        invalid["Parameterisation"]["Negative electrode"]["Particle diameter [m]"] = 1.0e-5
        @test_logs (:warn, r"does not conform to the BPX") match_mode = :any BPX.parse_bpx_to_cell_parameters(invalid)
        @test_throws "does not conform to the BPX" BPX.parse_bpx_to_cell_parameters(invalid; strict = true)
        @test BPX.parse_bpx_to_cell_parameters(invalid; validate = false) isa Dict

        # Inputs newer than the bundled schema are flagged
        newer = deepcopy(migrated)
        newer["Header"]["BPX"] = "1.2.0"
        @test_logs (:warn, r"newer than the BPX 1\.1\.1 schema") match_mode = :any BPX.parse_bpx_to_cell_parameters(newer; validate = false)

        malformed = deepcopy(migrated)
        malformed["Header"]["BPX"] = "latest"
        @test_throws "version field is missing or malformed" BPX.parse_bpx_to_cell_parameters(malformed)
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

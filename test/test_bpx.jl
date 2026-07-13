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

    @testset "unit conversion" begin
        BPX = BattMo.BPX

        # Equivalent unit spellings normalize identically
        @test BPX.normalize_unit("J.kg-1.K-1") == BPX.normalize_unit("J.K-1.kg-1")
        @test BPX.normalize_unit("W/(m.K)") == BPX.normalize_unit("W.m-1.K-1")
        @test BPX.normalize_unit("mol/L") == BPX.normalize_unit("mol.L-1")
        @test BPX.normalize_unit("µm") == BPX.normalize_unit("um")

        reference = BattMo.BPX.load_from_bpx_file(nmc_file_path)

        # Rewrite some keys of the BPX file in non-SI units; parsing must give the
        # same converted values as the original file
        bpx = BattMo.JSON.parsefile(nmc_file_path)
        cell = bpx["Parameterisation"]["Cell"]
        ne = bpx["Parameterisation"]["Negative electrode"]
        elyte = bpx["Parameterisation"]["Electrolyte"]

        rename!(section, old, new, factor) = begin
            section[new] = section[old] * factor
            delete!(section, old)
        end

        rename!(cell, "Nominal cell capacity [A.h]", "Nominal cell capacity [mA.h]", 1.0e3)
        rename!(cell, "Density [kg.m-3]", "Density [g.cm-3]", 1.0e-3)
        rename!(ne, "Thickness [m]", "Thickness [um]", 1.0e6)
        rename!(ne, "Particle radius [m]", "Particle radius [nm]", 1.0e9)
        rename!(ne, "Maximum concentration [mol.m-3]", "Maximum concentration [mol.L-1]", 1.0e-3)
        rename!(ne, "Conductivity [S.m-1]", "Conductivity [mS.cm-1]", 1.0e1)
        rename!(ne, "Diffusivity activation energy [J.mol-1]", "Diffusivity activation energy [kJ.mol-1]", 1.0e-3)
        # Offset conversion for scalar temperatures
        cell["Reference temperature [degC]"] = cell["Reference temperature [K]"] - 273.15
        delete!(cell, "Reference temperature [K]")

        converted = BattMo.BPX.parse_bpx_to_cell_parameters(bpx)

        @test converted["Cell"]["NominalCapacity"] ≈ reference["Cell"]["NominalCapacity"]
        @test converted["NegativeElectrode"]["Coating"]["Thickness"] ≈ reference["NegativeElectrode"]["Coating"]["Thickness"]
        ne_am = converted["NegativeElectrode"]["ActiveMaterial"]
        ne_am_ref = reference["NegativeElectrode"]["ActiveMaterial"]
        @test ne_am["ParticleRadius"] ≈ ne_am_ref["ParticleRadius"]
        @test ne_am["MaximumConcentration"] ≈ ne_am_ref["MaximumConcentration"]
        @test ne_am["ElectronicConductivity"] ≈ ne_am_ref["ElectronicConductivity"]
        @test ne_am["ActivationEnergyOfDiffusion"] ≈ ne_am_ref["ActivationEnergyOfDiffusion"]
        # The reaction rate constant conversion uses the converted cmax
        @test ne_am["ReactionRateConstant"] ≈ ne_am_ref["ReactionRateConstant"]
        # The Arrhenius reference temperature converted from degC appears in the string
        @test occursin("1.0 / 298.15", converted["Electrolyte"]["IonicConductivity"])

        # Function strings in non-SI units are rescaled on output
        bpx_mv = BattMo.JSON.parsefile(nmc_file_path)
        ne_mv = bpx_mv["Parameterisation"]["Negative electrode"]
        ne_mv["Entropic change coefficient [mV.K-1]"] = ne_mv["Entropic change coefficient [V.K-1]"]
        delete!(ne_mv, "Entropic change coefficient [V.K-1]")
        converted_mv = BattMo.BPX.parse_bpx_to_cell_parameters(bpx_mv)
        @test occursin("* 0.001", converted_mv["NegativeElectrode"]["ActiveMaterial"]["EntropyChange"])

        # Tabulated data in non-SI units has its output values rescaled
        bpx_tab = BattMo.JSON.parsefile(lfp_file_path)
        pe_tab = bpx_tab["Parameterisation"]["Positive electrode"]
        table = pe_tab["Entropic change coefficient [V.K-1]"]
        pe_tab["Entropic change coefficient [mV.K-1]"] = Dict("x" => table["x"], "y" => table["y"] .* 1.0e3)
        delete!(pe_tab, "Entropic change coefficient [V.K-1]")
        converted_tab = BattMo.BPX.parse_bpx_to_cell_parameters(bpx_tab)
        @test converted_tab["PositiveElectrode"]["ActiveMaterial"]["EntropyChange"]["y"] ≈ Float64.(table["y"])

        # Unrecognized or non-convertible units raise errors
        bpx_bad = BattMo.JSON.parsefile(nmc_file_path)
        ne_bad = bpx_bad["Parameterisation"]["Negative electrode"]
        ne_bad["Particle radius [ft]"] = ne_bad["Particle radius [m]"]
        delete!(ne_bad, "Particle radius [m]")
        @test_throws "is not recognized" BattMo.BPX.parse_bpx_to_cell_parameters(bpx_bad)

        bpx_wrong = BattMo.JSON.parsefile(nmc_file_path)
        ne_wrong = bpx_wrong["Parameterisation"]["Negative electrode"]
        ne_wrong["Particle radius [mol.L-1]"] = ne_wrong["Particle radius [m]"]
        delete!(ne_wrong, "Particle radius [m]")
        @test_throws "Cannot convert" BattMo.BPX.parse_bpx_to_cell_parameters(bpx_wrong)

        # Duplicate entries for the same parameter are rejected
        bpx_dup = BattMo.JSON.parsefile(nmc_file_path)
        ne_dup = bpx_dup["Parameterisation"]["Negative electrode"]
        ne_dup["Particle radius [um]"] = 4.12
        @test_throws "multiple entries" BattMo.BPX.parse_bpx_to_cell_parameters(bpx_dup)
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

using BattMo
using Test

@testset "compute_equilibrium_energy" begin

    @testset "linear OCPs match the closed-form result" begin
        # With OCPs linear in the stoichiometry, the cell OCV is linear in SOC, so the
        # trapezoidal rule is exact: E = C * (V(SOC=0) + V(SOC=1)) / 2.
        # The OCPs depend on c/cmax, so passing cmax in the wrong argument slot breaks this.
        cell = load_cell_parameters(; from_default_set = "chen_2020")
        pe = cell["PositiveElectrode"]["ActiveMaterial"]
        ne = cell["NegativeElectrode"]["ActiveMaterial"]
        pe["OpenCircuitPotential"] = "4.2 - 0.8 * (c/cmax)"
        ne["OpenCircuitPotential"] = "0.6 - 0.5 * (c/cmax)"

        Up(θ) = 4.2 - 0.8 * θ
        Un(θ) = 0.6 - 0.5 * θ
        V(θp, θn) = Up(θp) - Un(θn)
        V0 = V(pe["StoichiometricCoefficientAtSOC0"], ne["StoichiometricCoefficientAtSOC0"])
        V1 = V(pe["StoichiometricCoefficientAtSOC100"], ne["StoichiometricCoefficientAtSOC100"])
        expected = compute_cell_theoretical_capacity(cell) * (V0 + V1) / 2

        @test compute_equilibrium_energy(cell) ≈ expected rtol = 1.0e-10

        # The same OCPs as tabulated data (x = stoichiometry): exact for linear data too.
        pe["OpenCircuitPotential"] = Dict{String, Any}("x" => [0.0, 1.0], "y" => [Up(0.0), Up(1.0)])
        ne["OpenCircuitPotential"] = Dict{String, Any}("x" => [0.0, 1.0], "y" => [Un(0.0), Un(1.0)])
        @test compute_equilibrium_energy(cell) ≈ expected rtol = 1.0e-10
    end

    @testset "OCPs given by function name" begin
        # Independent trapezoidal integration that calls the named OCP functions directly.
        function reference_energy(cell, Up, Un; Npts = 1000)
            pe = cell["PositiveElectrode"]["ActiveMaterial"]
            ne = cell["NegativeElectrode"]["ActiveMaterial"]
            T = 298.15
            soc = range(0.0, 1.0; length = Npts)
            θ(am, s) = am["StoichiometricCoefficientAtSOC0"] + (am["StoichiometricCoefficientAtSOC100"] - am["StoichiometricCoefficientAtSOC0"]) * s
            ocp(f, am, s) = f(θ(am, s) * am["MaximumConcentration"], T, T, am["MaximumConcentration"])
            V = [ocp(Up, pe, s) - ocp(Un, ne, s) for s in soc]
            mean_ocv = sum((V[i] + V[i + 1]) / 2 * (soc[i + 1] - soc[i]) for i in 1:(Npts - 1))
            return compute_cell_theoretical_capacity(cell) * mean_ocv
        end

        cases = [
            ("xu_2015", BattMo.open_circuit_potential_lfp_Xu_2015, BattMo.open_circuit_potential_graphite_Xu_2015),
            ("chayambuka_2022", BattMo.calc_pe_ocp, BattMo.calc_ne_ocp),
        ]
        for (name, Up, Un) in cases
            @testset "$name" begin
                cell = load_cell_parameters(; from_default_set = name)
                @test cell["PositiveElectrode"]["ActiveMaterial"]["OpenCircuitPotential"] isa AbstractDict
                energy = compute_equilibrium_energy(cell)
                mean_ocv = energy / compute_cell_theoretical_capacity(cell)
                @test energy ≈ reference_energy(cell, Up, Un) rtol = 1.0e-10
                @test 2.0 < mean_ocv < 4.5
            end
        end
    end

    @testset "chen_2020 regression" begin
        # LG M50 (21700): theoretical capacity ≈ 5.09 Ah, mean OCV ≈ 3.69 V.
        # The reference value was computed independently from the OCP expressions.
        cell = load_cell_parameters(; from_default_set = "chen_2020")
        energy = compute_equilibrium_energy(cell)
        mean_ocv = energy / compute_cell_theoretical_capacity(cell)

        @test energy ≈ 18.79 rtol = 1.0e-3
        @test 3.0 < mean_ocv < 4.2
    end
end

using BattMo
using Random
using Test

@testset "Sobol estimators (Ishigami)" begin
    # Ishigami function on [-π, π]^3 with analytic Sobol indices.
    a, b = 7.0, 0.1
    ishigami(x) = sin(x[1]) + a * sin(x[2])^2 + b * x[3]^4 * sin(x[1])
    V1 = 0.5 * (1 + b * π^4 / 5)^2
    V2 = a^2 / 8
    V13 = b^2 * π^8 * (1 / 18 - 1 / 50)
    V = V1 + V2 + V13
    S1_exact = [V1 / V, V2 / V, 0.0]
    ST_exact = [(V1 + V13) / V, V2 / V, V13 / V]

    rng = Random.Xoshiro(1234)
    N, d = 20_000, 3
    points = BattMo.saltelli_points(rand(rng, N, d), rand(rng, N, d))
    @test size(points) == (N * (d + 2), d)
    Y = reshape([ishigami(-π .+ 2π .* points[j, :]) for j in axes(points, 1)], :, 1)
    estimates = BattMo.estimate_sobol_indices(Y, N, d; bootstrap = 50, rng)

    @test isapprox(estimates.first_order[:, 1], S1_exact; atol = 0.04)
    @test isapprox(estimates.total_order[:, 1], ST_exact; atol = 0.04)
    @test estimates.n_valid == [N]
    lower, upper = estimates.total_order_ci
    @test all(lower[:, 1] .<= estimates.total_order[:, 1] .<= upper[:, 1])

    # The indices do not depend on a constant offset of the quantity.
    shifted = BattMo.estimate_sobol_indices(Y .+ 1000.0, N, d)
    @test shifted.first_order ≈ estimates.first_order
    @test shifted.total_order ≈ estimates.total_order

    # A failed evaluation drops its base sample.
    Y[2N + 5, 1] = NaN
    @test BattMo.estimate_sobol_indices(Y, N, d).n_valid == [N - 1]
end

@testset "Sobol sensitivity parameters and indices" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
    model = LithiumIonBattery()
    sim = Simulation(model, cell_parameters, cycling_protocol)

    output = solve(sim; info_level = -1)
    heat = compute_heat_generation(output)
    heat_sources = compute_heat_generation(output; method = :source_terms)
    @test heat.total > 0
    @test 0 < heat_sources.total < heat.total
    @test length(heat.rate) == length(output.jutul_output.states)

    sa = SobolSensitivity(sim)
    @test sa.sim !== sim
    @test sort!(collect(keys(sa.quantities))) == ["Energy", "Heat", "Power"]

    ne_D = ["NegativeElectrode", "ActiveMaterial", "DiffusionCoefficient"]
    pe_D = ["PositiveElectrode", "ActiveMaterial", "DiffusionCoefficient"]
    sep_L = ["Separator", "Thickness"]
    @test_throws ArgumentError free_sensitivity_parameter!(sa, ne_D)
    @test_throws ArgumentError free_sensitivity_parameter!(sa, ne_D; lower_bound = 1.0e-13, upper_bound = 1.0e-14)
    @test_throws ArgumentError free_sensitivity_parameter!(sa, sep_L; lower_bound = 0.0, upper_bound = 1.0, scaling = :log)
    @test_throws ArgumentError free_sensitivity_parameter!(sa, sep_L; lower_bound = 1.0, upper_bound = 2.0)
    @test_throws ArgumentError free_sensitivity_parameter!(sa, sep_L; lower_bound = 0.0, upper_bound = 1.0, scaling = :sqrt)

    free_sensitivity_parameter!(sa, sep_L; lower_bound = 1.0e-5, upper_bound = 2.0e-5)
    free_sensitivity_parameter!(sa, ne_D; lower_bound = 1.0e-14, upper_bound = 1.0e-13, scaling = :log)
    free_sensitivity_parameter!(sa, pe_D; lower_bound = 1.0e-15, upper_bound = 1.0e-14, scaling = :log)
    @test sa.parameter_targets[ne_D].scaling == :log
    targets = [sa.parameter_targets[ne_D], sa.parameter_targets[sep_L]]
    @test BattMo.unit_to_physical(targets, [0.5, 0.5]) ≈ [sqrt(1.0e-14 * 1.0e-13), 1.5e-5]
    freeze_sensitivity_parameter!(sa, sep_L)
    @test !haskey(sa.parameter_targets, sep_L)

    result = solve(sa; N = 8, bootstrap = 20, info_level = -1, rng = Random.Xoshiro(1))
    @test sa.result === result
    @test result.parameter_names == [join(ne_D, "."), join(pe_D, ".")]
    @test result.quantity_names == ["Energy", "Heat", "Power"]
    @test size(result.samples) == (8 * 4, 2)
    @test all(isfinite, result.values)
    @test all(result.values[:, 1] .> 0) && all(result.values[:, 2] .> 0)
    @test all(isfinite, result.total_order)
    @test result.n_valid == [8, 8, 8]
    io = IOBuffer()
    print_sobol_indices(io, result)
    @test occursin("Sobol indices of Heat", String(take!(io)))
    print_sensitivity_overview(sa)

    # The original simulation is unchanged.
    @test sim.cell_parameters["Separator"]["Thickness"] == cell_parameters["Separator"]["Thickness"]
end
